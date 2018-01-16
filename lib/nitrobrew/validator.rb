class Validator
  attr_reader :program, :database, :valves


  def initialize(program, database, valves)
    @program = program
    @database = database
    @valves = valves
  end

  def validate!
    raise "ERROR: Component has states but is not configured" unless ids_match?(component_ids, valve_ids)
    puts "WARNING: Component is configured but not used" unless ids_match?(valve_ids, component_ids)
  end

  def component_ids
    db.execute("select distinct component_id from component_states join steps on steps.id = component_states.step_id where program_id = ?", program_id).flatten
  end

  def program_id
    @program_id ||= single_value { db.execute("select id from programs where purpose = ?", @program.to_s) }
  end

  def db
    @db ||= SQLite3::Database.new @database
  end

  def single_value
    result_set = yield
    return nil if result_set.empty?
    row = result_set.flatten.first
  end

  def valve_ids
    @valves.map { |v| v["id"] }
  end

  def ids_match?(a, b)
    a.all? { |id| b.include?(id) }
  end
end