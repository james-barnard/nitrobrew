  RSpec.describe Configuration do
    
    let(:config) {Configuration.new}
    let(:valid_setup) do
      "valves:
      -  "
    end
    let(:valid_valve) do
        "id: v2
         name: Brew In
         type: powered
         open: P8_3
         close: P8_4
         sense_open: P8_5
         sense_closed: P8_6"
    end
    let(:valid_config) { valid_setup + valid_valve }
    let(:duplicate_id) do
      valid_config + "\n      -  id: v2"
    end
    let(:duplicate_pins) do
      valid_config + "\n      -  type: NC\n         open: P8_3"
    end
    let(:duplicate_name) do
      valid_config + "\n      -  name: Brew In"
    end
    let(:invalid_config) do
      "notvalves:
         -  id: v1
            name: Brew Vacuum
            action: powered
            open: P8_3
            close: P8_4
            sense_open: P8_5
            sense_closed: P8_6"
    end

    it "#new loads valve definitions into an array" do
      expect(config.valves).to be_a_kind_of(Array)
    end
  
    it "raises an exception if there are no valves" do
      allow(File).to receive(:open).and_return(invalid_config)
      expect{Configuration.new}.to raise_error("Config file doesn't have valves")
    end

    it "validates valve parameters" do
      expect {Configuration.new}.to_not raise_error
    end

    it "raises an exception if any valve pins are repeated" do
      allow(File).to receive(:open).and_return(duplicate_pins)
      expect {Configuration.new}.to raise_error("Duplicate pin")
    end

    it "raises an exception if any ids are repeated" do
      allow(File).to receive(:open).and_return(duplicate_id)
      expect{Configuration.new}.to raise_error("Duplicate valve id")
    end

    it "raises an exception if any names are repeated" do
      allow(File).to receive(:open).and_return(duplicate_name)
      expect{Configuration.new}.to raise_error("Duplicate valve name")
    end
  end
