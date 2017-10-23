class Valve
	attr_accessor :id, :name, :action, :open, :close, :sense_open, :sense_closed

	VALID_TYPES 		= ["NC", "powered"]
	VALID_PINS  		= { "NC" 		 => ["open"],
								 		 "powered" => ["open", "closed", "sense_open", "sense_closed"] }
	REQUIRED_PARAMS = ["name", "id"]

	def initialize(params)
		validate!(params)

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
end