require "sqlite3"

class Stepper

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

  private
  def validate_database_file!(database)
    raise("Invalid database file") unless File.exist?(database) 
  end

  def validate_program!(program)
    raise("Invalid program") unless program_id
  end

  def program_id
    db.execute("select id from programs where purpose = ?", @program.to_s).first.first
  end

  def db
    @db ||= SQLite3::Database.new @database
  end

  def create_test_run
    prev_id = db.execute("select id from test_runs order by id desc limit 1").first
    debugger
    db.execute("insert into test_runs values (#{prev_id || 0} + 1, #{@machine.id}, #{program_id}, 'test run name', #{Time.now.to_i}, null, null)")
  end
end