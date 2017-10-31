describe Stepper do


  before(:all) do
    @db = SQLite3::Database.new("stepper_test.db")
    #@db.execute(File.open("schema.db").read)
    @db.execute("insert into programs values(1, 'clean')")
  end
  let (:machine) { Machine.new }
  
  describe "#initialize" do
    it "validates its database parameter" do
      expect {Stepper.new("not a database", :clean, machine)}.to raise_error("Invalid database file")
    end

    it "validates its program parameter" do
      expect {Stepper.new("test.db", :not_a_program, machine)}.to raise_error("Invalid program")
    end

    it "creates the test_run in the database" do
      expect {Stepper.new("stepper_test.db", :clean, machine)}.to change {@db.execute("select count(*) from test_runs")}.by(1)
    end
  end

  describe "#step" do
    it "gets the current step number from the database"

    it "sets the component states"

    it "checks the component states"

    it "moves to the next step when the duration has ended"

    it "reports the step status"
  end

  
end