PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS test_cells (
    id int,
    name varchar(30)
  );
CREATE TABLE IF NOT EXISTS components (
    id int,
    test_cell_id int,
    name varchar(30)
  );
CREATE TABLE IF NOT EXISTS component_states (
    id int,
    component_id int,
    step_id int,
    state varchar(10),
    sequence_number int
  );
CREATE TABLE IF NOT EXISTS test_runs (
    id int,
    test_cell_id int,
    program_id int,
    name varchar(30),
    started_at int,
    completed_at int,
    status_final varchar(15)
  );
CREATE TABLE IF NOT EXISTS programs (
    id int,
    purpose varchar(30)
  );
CREATE TABLE IF NOT EXISTS steps (
    id int,
    program_id int,
    description varchar(30),
    duration int,
    sequence_number int
  );
CREATE TABLE IF NOT EXISTS step_status (
    id int,
    step_id int,
    test_run_id int,
    status varchar(10),
    started_at int,
    soaking_at int,
    completed_at int
  );
COMMIT;
