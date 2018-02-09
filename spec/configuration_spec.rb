  RSpec.describe Configuration do

    let(:config) {Configuration.new("config.yml.test")}
    let(:valid_control) do
      "control:
      -  id: 1
         name: p8_enable
         pin_id: P9_42
         trigger: low\n"
    end
    let(:valid_i2cs) do
      "i2cs:
      -  id: A
         bus: I2C2
         addr: 0x20
         gpio_default: 0xff\n"
    end
    let(:valid_valve_setup) do
      "valves:
      -  "
    end
    let(:valid_valve) do
        "id: 2
         name: Brew In
         type: powered
         open: P8_3
         activate: P8_4
         sense_open: P8_5
         sense_closed: P8_6\n"
    end
    let(:valid_switch) do
      "switches:
      -  id: 1
         name: clean
         pin: P9_29
         pull_down: yes\n"
    end
    let(:valid_lights) do
      "lights:
   -  name: done
      pin_id: P8_19
   -  name: brew
      pin_id: P8_26\n"
    end
    let(:valid_config) { valid_control + valid_i2cs + valid_switch + valid_lights + valid_valve_setup + valid_valve }
    let(:duplicate_id) do
      valid_config + "\n      -  id: 2"
    end
    let(:duplicate_pins) do
      valid_config + "\n      -  type: NC\n         open: P8_3"
    end
    let(:duplicate_i2c_pins) do
      valid_config +
      "      -  id: 3
         name: Name1
         type: NC
         open: I.B.7
      -  id: 4
         name: Name2
         type: NC
         open: I.B.7"
    end
    let(:duplicate_name) do
      valid_config + "\n      -  name: Brew In"
    end
    let(:duplicate_true) do
      valid_config +
      "      -  id: 3
         name: Name1
         type: NC
         open: I.B.7
         duplicate: true +
      -  id: 4
         name: Name2
         type: NC
         open: I.B.7
         duplicate: true"
    end
    let(:duplicate_pins_across_components) do
      valid_config + "\n      -  type: NC\n         open: P9_42"
    end
    let(:invalid_valve_config) do
      valid_control + valid_switch +
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

    it "loads light definitions into an array" do
      expect(config.lights).to be_a_kind_of(Array)
      expect(config.lights.first).to be_a_kind_of(Hash)
    end

    context "i2cs" do
      it "loads i2c definitions into an array" do
        expect(config.i2cs).to be_a_kind_of(Array)
      end

      it "verifies the keys of an i2c configuration" do
        config.i2cs.each do |i2c|
          expect(i2c.keys.sort).to eq(["addr", "bus", "gpio_default", "id"])
        end
      end
    end

    it "raises an exception if there are no valves" do
      allow(File).to receive(:open).and_return(invalid_valve_config)
      expect{Configuration.new("config.yml.test")}.to raise_error("Config file doesn't have valves")
    end

    it "validates valve parameters" do
      expect {Configuration.new("config.yml.test")}.to_not raise_error
    end

    it "raises an exception if any valve pins are repeated" do
      allow(File).to receive(:open).and_return(duplicate_pins)
      expect {Configuration.new("config.yml.test")}.to raise_error("Duplicate pin: P8_3")
    end

    it "raises an exception if any ids are repeated" do
      allow(File).to receive(:open).and_return(duplicate_id)
      expect{Configuration.new("config.yml.test")}.to raise_error("Duplicate valve id: 2")
    end

    it "raises an exception if any names are repeated" do
      allow(File).to receive(:open).and_return(duplicate_name)
      expect{Configuration.new("config.yml.test")}.to raise_error("Duplicate valve name: Brew In")
    end

    it "raises an exception if any I2C pins are in conflict" do
      allow(File).to receive(:open).and_return(duplicate_i2c_pins)
      expect {Configuration.new("config.yml.test")}.to raise_error("Duplicate pin: I.B.7")
    end

    it "raises an exception if more than 1 component uses the same pins" do
      allow(File).to receive(:open).and_return(duplicate_pins_across_components)
      expect {Configuration.new("config.yml.test")}.to raise_error("Duplicate pin: P9_42")
    end

    it "doesn't raise an exception if the component is specified as having a duplicate pin" do
      allow(File).to receive(:open).and_return(duplicate_true)
      expect {Configuration.new("config.yml.test")}.to_not raise_error
    end
  end
