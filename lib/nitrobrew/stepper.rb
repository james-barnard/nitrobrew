require "sqlite3"

class Stepper
  attr_accessor :machine
  COMPONENT_STATES_SQL = <<-SQL
    select *
    from component_states
    where step_id = ?
    order by sequence_number
  SQL
  FINAL_STEP_SQL = <<-SQL
    select sequence_number
    from steps
    where program_id = ?
    order by sequence_number desc
    limit 1
  SQL
  COMPLETED_STEP_SQL = <<-SQL
    select sequence_number
    from step_statuses ss, steps s
    where s.id = ss.step_id
    and status = 'completed'
    and test_run_id = ?
    order by ss.id desc
    limit 1
  SQL
  NEXT_STEP_SQL = <<-SQL
    select sequence_number
    from steps
    where program_id = ?
    and sequence_number > ?
    order by sequence_number
    limit 1
  SQL
  CURRENT_STATUS_SQL = <<-SQL
    select status
    from step_statuses
    where step_id = ?
    and test_run_id = ?
    order by id desc
    limit 1
  SQL
  STEP_SQL = <<-SQL
    select id
    from steps
    where sequence_number = ?
    and program_id = ?
  SQL
  DURATION_SQL = <<-SQL
    select duration
    from steps
    where id = ?
  SQL
  STARTED_AT_SQL = <<-SQL
    select started_at
    from step_statuses
    where status = 'soaking'
    and step_id = ?
    and test_run_id = ?
  SQL
  TEST_RUN_SQL = <<-SQL
    insert into test_runs
    (id, test_cell_id, program_id, name, started_at)
    values (?, ?, ?, ?, ?)
  SQL


  def initialize(database, program, machine)
    @machine = machine
    validate_database_file!(database)
    @database = database
    @program = program
    validate_program!(program)
    create_test_run
  end

  def step
    @current_step = nil
    last_reported_status = current_status
    case last_reported_status
    when nil
      set_component_states
      status = check_component_states
    when :pending
      status = check_component_states
    when :soaking
      status = check_soak_time
    when :completed
      status = :done
    else
      raise("Unknown current status in step: #{last_reported_status}")
    end
    set_current_status(status) if last_reported_status != status
    "#{current_step}:#{status}"
  end

  def check_soak_time
    started_at = single_value { db.execute STARTED_AT_SQL, step_id(current_step), test_run_id }
    soak_duration = single_value { db.execute DURATION_SQL, step_id(current_step) }
    puts "stepper:check_soak_time:elapsed: #{Time.now.to_i - started_at}:target: #{soak_duration}"
    if Time.now.to_i - started_at < soak_duration
      :soaking
    else
      :completed
    end
  end

  def set_current_status(status)
    save_step_status(current_step, test_run_id, status)
  end

  def component_states
    db.execute COMPONENT_STATES_SQL, step_id(current_step)
  end

  def set_component_states
    component_states.each do |state|
      set_state(*state)
    end
  end

  def check_component_states
    component_states.each do |state|
      return :pending unless check_state(*state)
    end
    :soaking
  end

  def check_state(id, component_id, step_id, state, sequence_number)
    machine.check_component_state(component_id)
  end

  def set_state(id, component_id, step_id, state, sequence_number)
    machine.set_component_state(component_id, state.to_sym)
  end

  def current_step
    @current_step ||= if last_completed_step < final_step
      next_step(last_completed_step)
    else
      final_step
    end
  end

  def next_step(last_step)
    single_value { db.execute NEXT_STEP_SQL, program_id, last_step }
  end

  def current_status
    status = single_value { db.execute CURRENT_STATUS_SQL, step_id(current_step), test_run_id }
    status.nil? ? nil : status.to_sym
  end

  def last_completed_step
    single_value { db.execute COMPLETED_STEP_SQL, test_run_id } || 0
  end

  def final_step
    @final_step ||= single_value { db.execute FINAL_STEP_SQL, program_id }
  end

  def save_step_status(sequence_number, test_run_id, status, started_at = Time.now.to_i)
    prev_id = single_value { db.execute("select id from step_statuses order by id desc limit 1") }
    sql = <<-SQL
      insert into step_statuses
        (id, step_id, test_run_id, status, started_at)
      values (#{(prev_id || 0) + 1 }, #{step_id(sequence_number)}, #{test_run_id}, '#{status.to_s}', #{started_at})
    SQL
    db.execute sql
  end

  def step_id(sequence_number)
    single_value { db.execute STEP_SQL, sequence_number, program_id }
  end

  private
  def validate_database_file!(database)
    raise("Invalid database file") unless File.exist?(database)
  end

  def validate_program!(program)
	  puts "validate_program: #{program}: #{@program}"
    raise("Invalid program") unless program_id
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

  def last_test_run
    single_value { db.execute("select id from test_runs order by id desc limit 1") }
  end

  def create_test_run
    db.execute TEST_RUN_SQL, test_run_id, @machine.id, program_id, 'test run name', Time.now.to_i
  end

  def test_run_id
    @test_run_id ||= (last_test_run || 0) + 1
  end
end
