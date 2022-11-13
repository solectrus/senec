# Unofficial Ruby Client for SENEC Home

Access your local SENEC Solar Battery Storage System

**WARNING:** I'm not affiliated in any way with the SENEC company.

Inspired by:

- https://github.com/mchwalisz/pysenec
- https://gist.github.com/smashnet/82ad0b9d7f0ba2e5098e6649ba08f88a

## Installation

```bash
$ gem install senec
```

## Usage

```ruby
require 'senec'

request = Senec::Request.new host: '10.0.1.99'

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
puts "Current state of the system: #{request.current_state}"
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
# Current state of the system: CHARGE
# Measure time: 2021-10-06 17:50:22 +0200
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/solectrus/senec. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/solectrus/senec/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in this project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/solectrus/senec/blob/master/CODE_OF_CONDUCT.md).
