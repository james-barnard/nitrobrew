require "sqlite3"

# Open a database
db = SQLite3::Database.new "test.db"

# Create a table
db.execute <<-SQL
  create table test_cells (
    id int,
    name varchar(30)
  );
SQL

db.execute <<-SQL
  create table components (
    id int,
    test_cell_id int,
    name varchar(30)
  );
SQL

db.execute <<-SQL
  create table component_states (
    id int,
    component_id int,
    step_id int,
    state varchar(10),
    sequence_number int
  );
SQL

db.execute <<-SQL
  create table test_runs (
    id int,
    test_cell_id int,
    program_id int,
    name varchar(30),
    started_at int,
    completed_at int,
    status_final varchar(15)
  );
SQL

db.execute <<-SQL
  create table programs (
    id int,
    purpose varchar(30)
  );
SQL

db.execute <<-SQL
  create table steps (
    id int,
    program_id int,
    description varchar(30),
    duration int,
    sequence_number int
  );
SQL

db.execute <<-SQL
  create table step_statuses (
    id int,
    sequence_number int,
    test_run_id int,
    status varchar(10),
    started_at int,
    soaking_at int,
    completed_at int
  );
SQL