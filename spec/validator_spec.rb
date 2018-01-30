RSpec.describe Validator do
  let(:validator) { Validator.new(:clean, "validator.db", valves) }
  let(:valves) do
    [{"id"=>1, "name"=>"Filter H2O", "type"=>"NC", "open"=>"P8_39", "trigger"=>"high"},
     {"id"=>2, "name"=>"Filter Backflush", "type"=>"NC", "open"=>"P8_40", "trigger"=>"high"}]
  end

  before(:all) do
    @db = SQLite3::Database.new("validator.db")
    schema = File.open("schema.sql").read
    schema.split(/\;\n/).each { |stmt|
      if stmt =~ /CREATE/
        @db.execute("#{stmt};")
      end
    }
  end

  before(:each) do
    clean_database
  end

  it "makes a list of component ids referenced in the component states table" do
    expect(validator.component_ids).to eq([1, 2])
  end

  it "makes a list of component ids referenced by config#valves" do
    expect(validator.valve_ids).to eq([1, 2])
  end

  context "the program is valid" do
    it "returns true" do
      allow(validator).to receive(:component_ids).and_return([1, 2])
      allow(validator).to receive(:valve_ids).and_return([1, 2])
      
      expect(validator.validate!).to be(true)
    end
  end

  context "the program is not valid" do
    it "prints a warning if any components have states but are not configured" do
      allow(validator).to receive(:component_ids).and_return([1, 2])
      allow(validator).to receive(:valve_ids).and_return([1])
      expect{validator.validate!}.to output(/Validator: ERROR: Component 2 is not included in config file/).to_stdout
    end

    it "prints a warning if a component is configured but not referenced in the component states table" do
      allow(validator).to receive(:component_ids).and_return([1])
      allow(validator).to receive(:valve_ids).and_return([1, 2])
      expect {validator.validate!}.to output(/Validator: WARNING: Component 2 is not used in the clean program/).to_stdout
    end

    it "returns false if any components have states but are not configured" do
      allow(validator).to receive(:component_ids).and_return([1, 2])
      allow(validator).to receive(:valve_ids).and_return([1])

      expect(validator.validate!).to be(false)
    end

    it "returns true if a component is configured but not referenced in the component states table" do
      allow(validator).to receive(:component_ids).and_return([1])
      allow(validator).to receive(:valve_ids).and_return([1, 2])

      expect(validator.validate!).to be(true)
    end
  end

  def clean_database
    @db.execute("delete from programs")
    @db.execute("delete from step_statuses")
    @db.execute("delete from steps")
    @db.execute("delete from test_runs")
    @db.execute("delete from components")
    @db.execute("delete from component_states")
    @db.execute("insert into programs values(1, 'clean')")
    @db.execute("insert into steps values(1, 1, 'first step', 0, 10)")
    @db.execute("insert into steps values(2, 1, 'second step', 0, 20)")
    @db.execute("insert into components values(1, 1, 'component1')")
    @db.execute("insert into components values(2, 1, 'component2')")
    @db.execute("insert into component_states values(1, 1, 1, 'open', 1)")
    @db.execute("insert into component_states values(2, 2, 1, 'closed', 1)")
    @db.execute("insert into component_states values(3, 1, 2, 'closed', 1)")
    @db.execute("insert into component_states values(4, 2, 2, 'open', 1)")
  end
end