# Copyright 2018 Lars Eric Scheidler
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
      initialize_data
      send_data
    end

    def set_defaults
      @required_arguments = []
      @config = OverlayConfig::Config.new config_scope: 'aws_sns_notification', defaults: {
        region:   'eu-central-1',
        template_directories: [File.realpath(File.dirname(__FILE__)+'/..')+ '/templates']
      }
    end

    def parse_arguments
      @options = OptionParser.new do |opt|
        opt.on('-h', '--help', 'show this help') do
          puts opt
          exit 0
        end

        opt.on('--region STRING', 'set sns topic region', 'default: ' + @config.region) do |region|
          @config.region = region
        end

        opt.on('--host', 'host notification') do
          @type = :host
        end

        opt.on('--service', 'service notification') do
          @type = :service
        end

        opt.on('--template STRING', 'use specified template for notification') do |template|
          @config.template = template
        end

        opt.on('--template-directory STRING', 'add specified template directory to search path', 'default: ' + @config.template_directories.inspect) do |template_directory|
          @config.template_directories.unshift File.realpath(template_directory)
        end
      end

      add_argument :date_time,            'set date time'
      add_argument :host_address,         'set host address'
      add_argument :host_alias,           'set host alias'
      add_argument :host_display_name,    'set host display name'
      add_argument :notification_author,  'set notification author'
      add_argument :notification_comment, 'set notification comment'
      add_argument :notification_type,    'set notification type'
      add_argument :output,               'set output'

      add_argument :service_description,  'set service description' do
        ( @type == :service ) ? true : false
      end

      add_argument :service_display_name,  'set service display name' do
        ( @type == :service ) ? true : false
      end

      add_argument :state,                'set state'
      add_argument :sns_topic,            'set sns topic'

      @options.parse!

      @required_arguments.delete_if do |name, block|
        if block.yield and not instance_variable_get("@#{name}").nil? #and not instance_variable_get("@#{name}").empty?
          true
        else
          not block.yield
        end
      end
      raise ArgumentError.new 'missing arguments: ' + @required_arguments.map{|name,p| '--' + name.to_s.gsub('_', '-')}.join(', ') unless @required_arguments.empty?
    end

    def add_argument name, description, &block
      @options.on('--' + name.to_s.gsub('_', '-') + ' STRING', description) do |value|
        instance_variable_set "@#{name}", value
      end

      if block.nil?
        @required_arguments << [name, Proc.new {true}]
      else
        @required_arguments << [name, block]
      end
    end

    def load_template
      # set default values
      data = YAML::load_file(@config.template_directories.last + '/default.yml')
      data.each do |key, value|
        instance_variable_set '@'+key, value
      end

      # find template
      if @config.template
        template_file = @config.template_directories.map do |dir|
          [dir + '/' + @config.template + '.yml', dir + '/' + @config.template + '.yaml'].find{|x| File.exist? x}
        end.find{|x| not x.nil?}

        data = YAML::load_file(template_file)
        data.each do |key, value|
          instance_variable_set '@'+key, value
        end
      end
    end

    def initialize_data
      parse_output if @parse_output
      @subject = if @type == :host
                   ERB.new(@host_subject).result(binding)
                 else
                   ERB.new(@service_subject).result(binding)
                 end
      @message = ERB.new(@template).result(binding)
      puts @message
      exit
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

    def send_data
      if @config.aws_access_key_id and @config.aws_secret_key
        Aws.config.update(
          credentials: Aws::Credentials.new(@config.aws_access_key_id, @config.aws_secret_key)
        )
      end

      sns = Aws::SNS::Resource.new(
        region: @config.region
      )
      topic = sns.topic(@sns_topic)
      topic.publish(message: @message, subject: @subject)
    end
  end
end
