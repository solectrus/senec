[![Continuous integration](https://github.com/solectrus/senec/actions/workflows/push.yml/badge.svg)](https://github.com/solectrus/senec/actions/workflows/push.yml)
[![wakatime](https://wakatime.com/badge/user/697af4f5-617a-446d-ba58-407e7f3e0243/project/84ac7dc2-9288-497c-bb20-9c6123d3de66.svg)](https://wakatime.com/badge/user/697af4f5-617a-446d-ba58-407e7f3e0243/project/84ac7dc2-9288-497c-bb20-9c6123d3de66)
[![Maintainability](https://qlty.sh/gh/solectrus/projects/senec/maintainability.svg)](https://qlty.sh/gh/solectrus/projects/senec)
[![Code Coverage](https://qlty.sh/gh/solectrus/projects/senec/coverage.svg)](https://qlty.sh/gh/solectrus/projects/senec)

# Unofficial Ruby Client for SENEC Home

Access your local SENEC Solar Battery Storage System or the SENEC Cloud from Ruby.

**WARNING:** I'm not affiliated in any way with the SENEC company.

Inspired by:

- https://github.com/mchwalisz/pysenec
- https://gist.github.com/smashnet/82ad0b9d7f0ba2e5098e6649ba08f88a
- https://documenter.getpostman.com/view/932140/2s9YXib2td

## Installation

```bash
$ gem install senec
```

## Usage

### Cloud access (V2.1, V3 and V4)

```ruby
require 'senec'

# Login to the SENEC cloud
connection = Senec::Cloud::Connection.new(username: 'me@example.com', password: 'my-secret-senec-password')

# List all available systems
puts connection.systems

# => [{"id"=>"123456", "steuereinheitnummer"=>"S123XXX", "gehaeusenummer"=>"DE-V3-XXXX", "strasse"=>"Musterstraße", "hausnummer"=>"27a", "postleitzahl"=>"99999", "ort"=>"Musterort", "laendercode"=>"DE", "zeitzone"=>"Europe/Berlin", "wallboxIds"=>["1"], "systemType"=>"V3"}]

# Get the Dashboard data of first systems (without knowing the ID):
puts Senec::Cloud::Dashboard[connection].first.data

# => {"aktuell"=>
#   {"stromerzeugung"=>{"wert"=>0.01, "einheit"=>"W"},
#    "stromverbrauch"=>{"wert"=>860.0, "einheit"=>"W"},
#    "netzeinspeisung"=>{"wert"=>0.01, "einheit"=>"W"},
#    "netzbezug"=>{"wert"=>852.6270000000001, "einheit"=>"W"},
#    "speicherbeladung"=>{"wert"=>0.01, "einheit"=>"W"},
#    "speicherentnahme"=>{"wert"=>11.68, "einheit"=>"W"},
#    "speicherfuellstand"=>{"wert"=>1.0e-05, "einheit"=>"%"},
#    "autarkie"=>{"wert"=>1.35, "einheit"=>"%"},
#    "wallbox"=>{"wert"=>0.01, "einheit"=>"W"}},
#  "heute"=>
#   {"stromerzeugung"=>{"wert"=>3339.84375, "einheit"=>"Wh"},
#    "stromverbrauch"=>{"wert"=>21000.0, "einheit"=>"Wh"},
#    "netzeinspeisung"=>{"wert"=>13.671875, "einheit"=>"Wh"},
#    "netzbezug"=>{"wert"=>17546.38671875, "einheit"=>"Wh"},
#    "speicherbeladung"=>{"wert"=>119.140625, "einheit"=>"Wh"},
#    "speicherentnahme"=>{"wert"=>254.39453125, "einheit"=>"Wh"},
#    "speicherfuellstand"=>{"wert"=>0.0, "einheit"=>"%"},
#    "autarkie"=>{"wert"=>16.47, "einheit"=>"%"},
#    "wallbox"=>{"wert"=>0.0, "einheit"=>"Wh"}},
#  "zeitstempel"=>"2023-11-26T18:45:23Z",
#  "electricVehicleConnected"=>false}

# Get the Dashboard data of a specific system (by ID):
puts Senec::Cloud::Dashboard[connection].find("123456").data

# => {"aktuell"=>
#   {"stromerzeugung"=>{"wert"=>0.01, "einheit"=>"W"},
# ....

# Dashboard data can be requested in different versions, v1 and v2 are available, v1 is the default.
# To request the data in version 2, pass the version parameter to the `data` method:
puts Senec::Cloud::Dashboard[connection].first.data(version: 'v2')

# => {
#   'currently' => {
#     'powerGenerationInW' => 1.0e-05,
#     'powerConsumptionInW' => 1350.37,
#     'gridFeedInInW' => 1.0e-05,
#     'gridDrawInW' => 1321.26966059603,
#     'batteryChargeInW' => 1.0e-05,
#     'batteryDischargeInW' => 11.6411423841,
#     'batteryLevelInPercent' => 1.0e-05,
#     'selfSufficiencyInPercent' => 2.16,
#     'wallboxInW' => 1.0e-05
#   },
#   'today' => {
#     'powerGenerationInWh' => 3.90625,
#     'powerConsumptionInWh' => 9119.14,
#     'gridFeedInInWh' => 0.0,
#     'gridDrawInWh' => 9011.71875,
#     'batteryChargeInWh' => 0.0,
#     'batteryDischargeInWh' => 107.421875,
#     'batteryLevelInPercent' => 1.0e-05,
#     'selfSufficiencyInPercent' => 1.18,
#     'wallboxInWh' => 0.0
#   },
#   'timestamp' => '2025-01-11T06:45:09Z',
#   'electricVehicleConnected' => false
# }

# Get the Technical Data of a specific system (by ID):
puts Senec::Cloud::TechnicalData[connection].find("123456").data

# => {"systemOverview"=>{"systemId"=>123456, "productName"=>"SENEC.Home V3 hybrid duo", ...

# Get the Technical Data of first systems (without knowing the ID):
puts Senec::Cloud::TechnicalData[connection].first.data

# => {"systemOverview"=>{"systemId"=>123456, "productName"=>"SENEC.Home V3 hybrid duo", ...
```

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
```

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
