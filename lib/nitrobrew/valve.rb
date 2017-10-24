require 'beaglebone'
include Beaglebone

class Valve
	attr_accessor :id, :name, :action, :open, :close, :sense_open, :sense_closed

	VALID_TYPES 		= ["NC", "powered"]
	VALID_PINS  		= { "NC" 		 => ["open"],
								 		 "powered" => ["open", "close", "sense_open", "sense_closed"] }
	REQUIRED_PARAMS = ["name", "id"]

	def initialize(params)
		validate!(params)
		activate_pins(params)
		#@id = id
		#@name = name
		#@action = action
		#@open = open
		#@close = close
		#@sense_open = sense_open
		#@sense_closed = sense_closed
	end

	def validate!(params)
		raise("Invalid type") unless VALID_TYPES.include?(params["type"])

		(VALID_PINS[params["type"]] + REQUIRED_PARAMS).each do | param | 
			raise("Invalid #{param}") if params[param].nil?
		end
		
		return true
	end

	def activate_pins(params)
		VALID_PINS[params["type"]].each do | key |
			mode = pin_mode(key)
			pins[key] = GPIOPin.new(params[key].to_sym, mode, pullmode(mode))
		end
	end

	private
	def pins
		@pins ||= {}
	end

	def pin_mode(pin)
		case pin
		when "open", "close"
			:OUT
		when "sense_open", "sense_closed"
			:IN
		end
	end

	def pullmode(mode)
		mode == :IN ? :PULLDOWN : nil
	end
end