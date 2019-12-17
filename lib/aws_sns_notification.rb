# Copyright 2019 Lars Eric Scheidler
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "aws_sns_notification/version"

require 'bundler/setup'

require 'aws-sdk-sns'
require 'erb'
require 'optparse'
require 'yaml'

require 'overlay_config'

module AwsSnsNotification
  class CLI
    def initialize
      set_defaults
      parse_arguments

      load_template
      check_arguments

      help if @show_help

      initialize_data
      send_data
    end

    def set_defaults
      @config = OverlayConfig::Config.new config_scope: 'aws_sns_notification', defaults: {
        aws_notification_role: 'notification',
        hashicorp_secret_engine_path: 'aws',
        aws_sts_ttl: '60m',
        region:   'eu-central-1',
        template_directories: [File.realpath(File.dirname(__FILE__)+'/..')+ '/templates'],
        template: 'default',
      }
    end

    def parse_arguments
      @options = OptionParser.new do |opts|
        opts.on('-h', '--help', 'show this help') do
          @show_help = true
        end

        opts.on('--hashicorp-vault-address URL', 'set hashicorp vault address') do |address|
          @config.hashicorp_vault_address = address
        end

        opts.on('-n', '--dryrun') do
          @config.dryrun = true
        end

        opts.on('--region STRING', 'set sns topic region', 'default: ' + @config.region) do |region|
          @config.region = region
        end

        opts.on('--template STRING', 'use specified template for notification') do |template|
          @config.template = template
        end

        opts.on('--template-directory STRING', 'add specified template directory to search path', 'default: ' + @config.template_directories.inspect) do |template_directory|
          @config.template_directories.unshift File.realpath(template_directory)
        end

        opts.on('--sns-topic TOPIC', 'set sns topic') do |topic|
          @config.sns_topic = topic
        end

        opts.on('-v', '--variable KEY=VALUE', 'set variable KEY to VALUE') do |keyval|
          key, value = keyval.split("=")
          #@config[key] = value
          instance_variable_set "@#{key}", value
        end

        opts.on('--variant NAME', 'use template variant NAME') do |variant|
          @config.template_variant = variant
        end
      end

      @options.parse!
    end

    def help
      puts @options

      if not @required_variables.empty?
        puts "\nRequired Variables:"
        @required_variables.each do |rarg|
          printf "    -v %-29s %s\n", "#{rarg['name'].to_s}=<VALUE>", rarg['description']
        end
      end

      if not @optional_variables.empty?
        puts "\nOptional Variables:"
        @optional_variables.each do |oarg|
          printf "    -v %-29s %s\n", "#{oarg['name'].to_s}=<VALUE>", oarg['description']
        end
      end
      exit 0
    end

    def load_template
      ## find template
      template_file = @config.template_directories.map do |dir|
        [dir + '/' + @config.template + '.yml', dir + '/' + @config.template + '.yaml'].find{|x| File.exist? x}
      end.find{|x| not x.nil?}

      @template = YAML::load_file(template_file)

      if @template['variants'] and @template['variants'][@config.template_variant]
        @template['variants'][@config.template_variant].each do |key, value|
          if @template[key] and ['required_variables', 'optional_variables'].include? key
            @template[key] += value
          else
            @template[key] = value
          end
        end
      end

      @required_variables = []
      if @template['required_variables'] and not @template['required_variables'].empty?
        @required_variables += @template['required_variables']
      end

      @optional_variables = []
      if @template['optional_variables'] and not @template['optional_variables'].empty?
        @optional_variables += @template['optional_variables']
      end
    end

    def check_arguments
      raise ArgumentError.new 'missing argument: --sns-topic' unless @config.sns_topic

      missing_arguments = []
      @required_variables.each do |rarg|
        if not instance_variable_defined? "@#{rarg['name']}"
          #missing_arguments << '-v ' + rarg['name'].to_s + '=<VALUE>'
          missing_arguments << rarg['name'].to_s
        end
      end
      raise ArgumentError.new 'missing variables: ' + missing_arguments.join(', ') unless missing_arguments.empty?
    end

    def initialize_data
      parse_output if @parse_output
      @subject = ERB.new(@template['subject']).result(binding)
      @message = ERB.new(@template['template']).result(binding)
    end

    def parse_output
      case @parse_output
      when :json
        begin
          @output = JSON::parse(@output)
        rescue JSON::ParserError
          @json_parse_error = true
        end
      end
    end

    def hashicorp_vault_authenticate
      require 'vault'
      require 'aws_imds'

      Vault.address = @config.hashicorp_vault_address
      iam_instance_role = File.basename(AwsImds.meta_data.iam.info["InstanceProfileArn"])
      Vault.auth.aws_iam(iam_instance_role, Aws::InstanceProfileCredentials.new, @config.hashicorp_vault_id_header)

      session = Vault.logical.write("#{@config.hashicorp_secret_engine_path}/sts/#{@config.aws_notification_role}", {ttl: @config.aws_sts_ttl})

      Aws.config.update(
         credentials: Aws::Credentials.new(
           session.data[:access_key],
           session.data[:secret_key],
           session.data[:security_token]
         )
      )
    end

    def send_data
      if @config.hashicorp_vault_address and @config.aws_notification_role
        hashicorp_vault_authenticate
      elsif @config.aws_access_key_id and @config.aws_secret_key
        Aws.config.update(
          credentials: Aws::Credentials.new(@config.aws_access_key_id, @config.aws_secret_key)
        )
      end

      sns = Aws::SNS::Resource.new(
        region: @config.region
      )
      if not @config.dryrun
        topic = sns.topic(@config.sns_topic)
        topic.publish(message: @message, subject: @subject)
      else
        puts @subject
        puts @message
      end
    end
  end
end
