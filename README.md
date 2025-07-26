[![Continuous integration](https://github.com/solectrus/senec/actions/workflows/push.yml/badge.svg)](https://github.com/solectrus/senec/actions/workflows/push.yml)
[![wakatime](https://wakatime.com/badge/user/697af4f5-617a-446d-ba58-407e7f3e0243/project/84ac7dc2-9288-497c-bb20-9c6123d3de66.svg)](https://wakatime.com/badge/user/697af4f5-617a-446d-ba58-407e7f3e0243/project/84ac7dc2-9288-497c-bb20-9c6123d3de66)
[![Maintainability](https://qlty.sh/gh/solectrus/projects/senec/maintainability.svg)](https://qlty.sh/gh/solectrus/projects/senec)
[![Code Coverage](https://qlty.sh/gh/solectrus/projects/senec/coverage.svg)](https://qlty.sh/gh/solectrus/projects/senec)

# Unofficial Ruby Client for SENEC Home

Access your local SENEC Solar Battery Storage System or the SENEC Cloud (App API) from Ruby.

**WARNING:** I'm not affiliated in any way with the SENEC company.

Inspired by:

- https://github.com/mchwalisz/pysenec
- https://gist.github.com/smashnet/82ad0b9d7f0ba2e5098e6649ba08f88a
- https://github.com/marq24/ha-senec-v3

## Installation

```bash
$ gem install senec
```

## Usage

### Cloud access (V2.1, V3 and Home.4)

````ruby
require 'senec'

# Build connection with your credentials
connection = Senec::Cloud::Connection.new(username: 'me@example.com', password: 'my-secret-senec-password')

# List available systems (with their IDs)
puts connection.systems
# => {"id" => 999999, "controlUnitNumber" => "1234567890", ...

# Get the current dashboard data for a specific system
puts connection.dashboard(999999)
# => {"currently" => {"powerGenerationInW" => 8539.603515625, "powerConsumptionInW" => 765.77, "gridFeedInInW" => 6451.11376953125, "gridDrawInW" => 0.0, "batteryChargeInW" => 1316.9090576171875, "batteryDischargeInW" => 0.0, "batteryLevelInPercent" => 88.88888549804688, "selfSufficiencyInPercent" => 100.0, "wallboxInW" => 0.0}, "today" => {"powerGenerationInWh" => 19687.5, "powerConsumptionInWh" => 4960.93, "gridFeedInInWh" => 15310.546875, "gridDrawInWh" => 28.3203125, "batteryChargeInWh" => 1175.78125, "batteryDischargeInWh" => 1732.421875, "batteryLevelInPercent" => 88.88888549804688, "selfSufficiencyInPercent" => 99.43, "wallboxInWh" => 0.0}, "timestamp" => "2025-07-26T10:55:07Z", "electricVehicleConnected" => false, "numberOfWallboxes" => 0, "systemId" => 999999, "systemType" => "V123", "storageDeviceState" => "CHARGING"}

### Local access (V2.1 and V3 only)

```ruby
require 'senec'

connection = Senec::Local::Connection.new(host: '192.168.178.123', schema: 'https')
request = Senec::Local::Request.new(connection:)

puts "PV production: #{request.inverter_power} W"
puts "House power consumption: #{request.house_power} W"
puts "\n"
puts "Battery charge power: #{request.bat_power} W"
puts "Battery fuel charge: #{request.bat_fuel_charge} %"
puts "Battery charge current: #{request.bat_charge_current} A"
puts "Battery voltage: #{request.bat_voltage} V"
puts "\n"
puts "Case temperature: #{request.case_temp} °C"
puts "\n"
puts "Wallbox charge power: [ #{request.wallbox_charge_power.join(',')} ] W"
puts "\n"
puts "Grid power: #{request.grid_power} W"
puts "Current state of the system: #{request.current_state_code}"
puts "Measure time: #{Time.at request.measure_time}"

# Example result:
#
# PV production: 1530 W
# House power consumption: 870 W
#
# Battery charge power: 974 W
# Battery fuel charge: 11.3 %
# Battery charge current: 19.8 A
# Battery voltage: 49.2 V
#
# Case temperature: 31.3 °C
#
# Wallbox charge power: [ 8680, 0, 0, 0 ] W
#
# Grid power: 315 W
# Current state of the system: 14
# Measure time: 2021-10-06 17:50:22 +0200
````

To get the state name (in English, German or Italian) instead of just the number:

```ruby
# Get a Hash with all available state names:
state_names = Senec::State.new(connection:).names(language: :de) # or :en or :it
# Use this hash for the number => string mapping:
request = Senec::Request.new(connection:, state_names:)

puts request.current_state_name
# => "LADEN"
```

The state names are extracted from the JavaScript source code returned by the SENEC web interface.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/solectrus/senec. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/solectrus/senec/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

Copyright (c) 2020-2025 Georg Ledermann

## Code of Conduct

Everyone interacting in this project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/solectrus/senec/blob/master/CODE_OF_CONDUCT.md).
