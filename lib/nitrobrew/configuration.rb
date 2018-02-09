#require 'debugger'
require 'yaml'
require 'set'


class Configuration
	attr_reader :valves, :switches, :lights, :control, :i2cs

	def initialize(config_file)
		begin
			data = YAML.load(File.open(config_file))
		rescue ArgumentError => e
			puts "Could not parse YAML: #{e.message}"
		end
		@control  = data['control'] || raise("Config file doesn't have control features")
		@valves   = data['valves'] || raise("Config file doesn't have valves")
		@switches = data['switches'] || raise("Config file doesn't have switches")
    @lights   = data['lights']
    @i2cs     = data['i2cs'] || raise("Config file doesn't have i2cs")
    validate_components
  end

  private
  def validate_components
    ids     = Set.new []
    names   = Set.new []
    pin_set = Set.new []
    @valves.each do | valve |
      raise("Duplicate valve id: #{valve['id']}") unless ids.add?(valve["id"])
      raise("Duplicate valve name: #{valve['name']}") unless names.add?(valve["name"])
      Valve::VALID_PINS[valve["type"]].each do | pin |
        if valve[pin]
          raise("Duplicate pin: #{valve[pin]}") unless pin_set.add?(valve[pin]) || valve['duplicate'] == true
        end
      end
    end
    check_pins(pin_set, @control)
    check_pins(pin_set, @switches)
    check_pins(pin_set, @lights)
  end

  def check_pins(pin_set, components)
    components.each do | component |
      raise("Duplicate pin: #{component['pin_id']}") unless pin_set.add?(component["pin_id"]) || component['duplicate'] == true
    end
  end
end
