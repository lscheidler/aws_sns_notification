# AwsSnsNotification


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'aws_sns_notification', '~> 0.1.0', git: 'https://github.com/lscheidler/aws_sns_notification'
```

And then execute:

    $ bundle install --binstubs=bin

## Usage

```
bin/aws_sns_notification -h
```

### icinga2 configuration

```
template NotificationCommand "sns-notification-command" {
  vars.sns_topic = "arn:aws:sns:<region>:<account>:<topic>"
}

object NotificationCommand "sns-host-notification" {
  import "plugin-notification-command"
  import "sns-notification-command"

  command = [ CustomPluginDir + "/aws-sns-notification" ]

  arguments = {
    "--template"              = "icinga"
    "--variant"               = "host"
    "--sns-topic"             = "$sns_topic$"

    "-v"                      = "notification_type=$notification.type$"
    "-v"                      = "host_alias=$host.display_name$"
    "-v"                      = "host_address=$address$"
    "-v"                      = "state=$host.state$"
    "-v"                      = "date_time=$icinga.long_date_time$"
    "-v"                      = "output=$host.output$"
    "-v"                      = "notification_author=$notification.author$"
    "-v"                      = "notification_comment=$notification.comment$"
    "-v"                      = "host_display_name=$host.display_name$"
  }

  env = {
    "BUNDLE_GEMFILE" = CustomPluginDir + "/../Gemfile"
  }
}
```

```
object NotificationCommand "sns-service-notification" {
  import "plugin-notification-command"
  import "sns-notification-command"

  command = [ CustomPluginDir + "/aws-sns-notification" ]

  arguments = {
    "--template"              = "icinga"
    "--variant"               = "service"
    "--sns-topic"             = "$sns_topic$"

    "-v"                      = "notification_type=$notification.type$"
    "-v"                      = "service_description=$service.name$"
    "-v"                      = "host_alias=$host.display_name$"
    "-v"                      = "host_address=$address$"
    "-v"                      = "state=$service.state$"
    "-v"                      = "date_time=$icinga.long_date_time$"
    "-v"                      = "output=$service.output$"
    "-v"                      = "notification_author=$notification.author$"
    "-v"                      = "notification_comment=$notification.comment$"
    "-v"                      = "host_display_name=$host.display_name$"
    "-v"                      = "service_display_name=$service.display_name$"
    "-v"                      = {
      set_if = Icingaweb2Url.len()
      value = 'icingaweb2=' + Icingaweb2Url
    }
    "-v"                      = {
      set_if = "$service.action_url$".len()
      value = "graph=$service.action_url$"
    }
  }

  env = {
    "BUNDLE_GEMFILE" = CustomPluginDir + "/../Gemfile"
  }
}
```

```
object NotificationCommand "sns-service-template-notification" {
  import "plugin-notification-command"
  import "sns-notification-command"

  command = [ CustomPluginDir + "/aws-sns-notification" ]

  arguments = {
    "--sns-topic"             = "$sns_topic$"
    "--template"              = "$template"
    "--template-directory"    = "$template_directory"
    "--variant"               = "service"

    "-v"                      = "notification_type=$notification.type$"
    "-v"                      = "service_description=$service.name$"
    "-v"                      = "host_alias=$host.display_name$"
    "-v"                      = "host_address=$address$"
    "-v"                      = "state=$service.state$"
    "-v"                      = "date_time=$icinga.long_date_time$"
    "-v"                      = "output=$service.output$"
    "-v"                      = "notification_author=$notification.author$"
    "-v"                      = "notification_comment=$notification.comment$"
    "-v"                      = "host_display_name=$host.display_name$"
    "-v"                      = "service_display_name=$service.display_name$"
    "-v"                      = {
      set_if = Icingaweb2Url.len()
      value = 'icingaweb2=' + Icingaweb2Url
    }
    "-v"                      = {
      set_if = "$service.action_url$".len()
      value = "graph=$service.action_url$"
    }
  }

  env = {
    "BUNDLE_GEMFILE" = CustomPluginDir + "/../Gemfile"
  }
}
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/lscheidler/aws_sns_notification.


## License

The gem is available as open source under the terms of the [Apache 2.0 License](http://opensource.org/licenses/Apache-2.0).

