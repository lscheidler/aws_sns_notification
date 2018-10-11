# AwsSnsNotification


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'overlay_config', '~> 0.1.2', git: 'https://github.com/lscheidler/ruby-overlay_config', branch: 'master'
gem 'aws_sns_notification', '~> 0.1.0', git: 'https://github.com/lscheidler/aws_sns_notification', branch: 'master'
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
    "--host"                  = ""
    "--notification-type"     = "$notification.type$"
    "--host-alias"            = "$host.display_name$"
    "--host-address"          = "$address$"
    "--state"                 = "$host.state$"
    "--date-time"             = "$icinga.long_date_time$"
    "--output"                = "$host.output$"
    "--notification-author"   = "$notification.author$"
    "--notification-comment"  = "$notification.comment$"
    "--host-display-name"     = "$host.display_name$"
    "--sns-topic"             = "$sns_topic$"
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
    "--service"               = ""
    "--notification-type"     = "$notification.type$"
    "--service-description"   = "$service.name$"
    "--host-alias"            = "$host.display_name$"
    "--host-address"          = "$address$"
    "--state"                 = "$service.state$"
    "--date-time"             = "$icinga.long_date_time$"
    "--output"                = "$service.output$"
    "--notification-author"   = "$notification.author$"
    "--notification-comment"  = "$notification.comment$"
    "--host-display-name"     = "$host.display_name$"
    "--service-display-name"  = "$service.display_name$"
    "--sns-topic"             = "$sns_topic$"
    "--icingaweb2"            = {
      set_if = Icingaweb2Url.len()
      value = Icingaweb2Url
    }
    "--graph"                 = {
      set_if = "$service.action_url$".len()
      value = "$service.action_url$"
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
    "--service"               = ""
    "--notification-type"     = "$notification.type$"
    "--service-description"   = "$service.name$"
    "--host-alias"            = "$host.display_name$"
    "--host-address"          = "$address$"
    "--state"                 = "$service.state$"
    "--date-time"             = "$icinga.long_date_time$"
    "--output"                = "$service.output$"
    "--notification-author"   = "$notification.author$"
    "--notification-comment"  = "$notification.comment$"
    "--host-display-name"     = "$host.display_name$"
    "--service-display-name"  = "$service.display_name$"
    "--sns-topic"             = "$sns_topic$"
    "--template"              = "$template"
    "--template-directory"    = "$template_directory"
    "--icingaweb2"            = {
      set_if = Icingaweb2Url.len()
      value = Icingaweb2Url
    }
    "--graph"                 = {
      set_if = "$service.action_url$".len()
      value = "$service.action_url$"
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

