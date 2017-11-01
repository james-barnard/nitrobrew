describe Stepper do
  before(:all) do
    @db = SQLite3::Database.new("stepper.db")
    schema = File.open("schema.sql").read
    schema.split(/\;\n/).each { |stmt|
      if stmt =~ /CREATE/
        @db.execute("#{stmt};")
      end
    }
    @db.execute("delete from programs")
    @db.execute("delete from step_statuses")
    @db.execute("delete from steps")
    @db.execute("delete from test_runs")
    @db.execute("insert into programs values(1, 'clean')")
    @db.execute("insert into steps values(1, 1, 'first step', 0, 1)")
    @db.execute("insert into steps values(2, 1, 'second step', 0, 2)")
  end
  let (:machine) { Machine.new }

  describe "#initialize" do
    it "validates its database parameter" do
      expect {Stepper.new("not a database", :clean, machine)}.to raise_error("Invalid database file")
    end

    it "validates its program parameter" do
      expect {Stepper.new("stepper.db", :not_a_program, machine)}.to raise_error("Invalid program")
    end

    it "creates the test_run in the database" do
      expect { Stepper.new("stepper.db", :clean, machine) }.to change {
        stepper.send(:single_value) { @db.execute("select count(*) from test_runs") }
      }.by(1)
    end
  end

  let (:stepper) { Stepper.new("stepper.db", :clean, machine) }
  describe "#step" do
    before(:each) { allow(stepper).to receive(:test_run_id).and_return(1) }
    it "returns 1 if the step hasn't started" do
      expect(stepper.current_step).to eq(1)
    end
    
    it "gets the current step number from the database" do
      stepper.save_step_status(1, 1, :started)
      expect(stepper.current_step).to eq(1)
    end

    it "returns the first step not completed" do
      stepper.save_step_status(1, 1, :completed)
      expect(stepper.current_step).to eq(2)
    end

    it "returns nil when the last step is completed" do
      stepper.save_step_status(1, 1, :completed)
      stepper.save_step_status(2, 1, :completed)
      expect(stepper.current_step).to eq(nil)
    end

    it "sets the component states"

    it "checks the component states"

    it "moves to the next step when the duration has ended"

    it "reports the step status"
  end

  describe "#save_step_status" do
    it "creates a step status record" do
      expect { stepper.save_step_status(1, 1, :started) }.to change {
        stepper.send(:single_value) { @db.execute("select count(*) from step_statuses") }
      }.by(1)
    end
  end
end
