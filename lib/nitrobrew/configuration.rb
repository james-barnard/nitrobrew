require 'debugger'
require 'yaml'
require 'set'


class Configuration 
	attr_reader :valves

	def initialize
		begin 
			data = YAML.load(File.open("config.yml"))
		rescue ArgumentError => e
			puts "Could not parse YAML: #{e.message}"
		end
		@valves = data['valves'] || raise("Config file doesn't have valves")
    validate_valves
  end

  private
  def validate_valves
    ids = Set.new []
    names = Set.new []
    pin_set = Set.new []

    @valves.each do | valve |
      raise("Duplicate valve id") unless ids.add?(valve["id"])
      raise("Duplicate valve name") unless names.add?(valve["name"])
      Valve::VALID_PINS[valve["type"]].each do | pin |
        if valve[pin]
          raise("Duplicate pin") unless pin_set.add?(valve[pin])
        end
      end
    end
  end
end