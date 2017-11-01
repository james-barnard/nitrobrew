require "sqlite3"

class Stepper
    FINAL_STEP_SQL = <<-SQL
      select sequence_number
      from steps
      where program_id = ?
      order by sequence_number desc
      limit 1
    SQL
    COMPLETED_STEP_SQL = <<-SQL
      select sequence_number
      from step_statuses
      where status = 'completed'
      and test_run_id = ?
      order by id desc
      limit 1
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
  end

  def get_component_states
  end

  def current_step
    last_step = last_completed_step || 0
    if last_step < final_step
      last_step + 1
    else
      nil
    end
  end

  def last_completed_step
    single_value { db.execute COMPLETED_STEP_SQL, test_run_id }
  end

  def final_step
    @final_step ||= single_value { db.execute FINAL_STEP_SQL, program_id }
  end

  def save_step_status(sequence_number, test_run_id, status, started_at = Time.now.to_i)
    prev_id = single_value { db.execute("select id from step_statuses order by id desc limit 1") }
    sql = <<-SQL
      insert into step_statuses
        (id, sequence_number, test_run_id, status, started_at)
      values (#{(prev_id || 0) + 1 }, #{sequence_number}, #{test_run_id}, '#{status.to_s}', #{started_at})
    SQL
    db.execute sql
  end

  private
  def validate_database_file!(database)
    raise("Invalid database file") unless File.exist?(database)
  end

  def validate_program!(program)
    raise("Invalid program") unless program_id
  end

  def program_id
    single_value { db.execute("select id from programs where purpose = ?", @program.to_s) }
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
    db.execute("insert into test_runs (id, test_cell_id, program_id, name, started_at) values (#{test_run_id}, #{@machine.id}, #{program_id}, 'test run name', #{Time.now.to_i})")
  end

  def test_run_id
    @test_run_id ||= (last_test_run || 0) + 1
  end

end
