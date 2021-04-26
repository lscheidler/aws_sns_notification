# Copyright 2020 Lars Eric Scheidler
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

require "aws_sns_notification"
require "aws_sns_notification/version"

require 'bundler/setup'

module AwsSnsNotification
  class CLI
    def initialize
      @client = Client.new
      parse_arguments

      @client.load_template
      help if @show_help

      check_arguments

      @client.initialize_data
      @client.send_data
    end

    def parse_arguments
      @options = OptionParser.new do |opts|
        opts.on('-h', '--help', 'show this help') do
          @show_help = true
        end

        opts.on('--hashicorp-vault-address URL', 'set hashicorp vault address') do |address|
          @client.config.hashicorp_vault_address = address
        end

        opts.on('-n', '--dryrun') do
          @client.config.dryrun = true
        end

        opts.on('--region STRING', 'set sns topic region', 'default: ' + @client.config.region) do |region|
          @client.config.region = region
        end

        opts.on('--shorten VARNAME', 'shorten varname in subject, if subject is to long', 'example: --shorten host_display_name') do |varname|
          @client.config.shorten = varname
        end

        opts.on('--template STRING', 'use specified template for notification') do |template|
          @client.config.template = template
        end

        opts.on('--template-directory STRING', 'add specified template directory to search path', 'default: ' + @client.config.template_directories.inspect) do |template_directory|
          @client.config.template_directories.unshift File.realpath(template_directory)
        end

        opts.on('--sns-topic TOPIC', 'set sns topic') do |topic|
          @client.config.sns_topic = topic
        end

        opts.on('-v', '--variable KEY=VALUE', 'set variable KEY to VALUE') do |keyval|
          key, value = keyval.split("=", 2)
          #@client.config[key] = value
          #instance_variable_set "@#{key}", value
          @client.set_variable key, value
        end

        opts.on('--variant NAME', 'use template variant NAME') do |variant|
          @client.config.template_variant = variant
        end
      end

      @options.parse!
    end

    def help
      puts @options

      if not @client.required_variables.empty?
        puts "\nRequired Variables:"
        @client.required_variables.each do |rarg|
          printf "    -v %-29s %s\n", "#{rarg['name'].to_s}=<VALUE>", rarg['description']
        end
      end

      if not @client.optional_variables.empty?
        puts "\nOptional Variables:"
        @client.optional_variables.each do |oarg|
          printf "    -v %-29s %s\n", "#{oarg['name'].to_s}=<VALUE>", oarg['description']
        end
      end
      exit 0
    end

    def check_arguments
      raise ArgumentError.new 'missing argument: --sns-topic' unless @client.config.sns_topic

      @client.check_variables
    end
  end
end
