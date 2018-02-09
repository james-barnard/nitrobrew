describe Machine do
  GPIOPin = Beaglebone::GPIOPin
  I2CDevice = Beaglebone::I2CDevice

  let(:machine) { Machine.new }
  let(:run_switch) { machine2.send(:switches)[:run] }
  let(:valve_2) { machine.send(:valves)[2] }
  let(:fake_stepper) { double("fs1") }
  let(:fake_stepper2) { double("fs2", :step => "2:done") }
  let(:light_manager) do
    double("light_manager",
      :on_program_change => nil,
      :ready_mode => nil,
      :run_mode => nil,
      :blink => nil,
      :all_on => nil,
      :all_off => nil)
  end
  let(:validator) { Validator.new(:brew, "machine.db", valves) }
  let(:valves) do
    [{"id"=>1, "name"=>"Filter H2O", "type"=>"NC", "open"=>"P8_39", "trigger"=>"high"},
     {"id"=>2, "name"=>"Filter Backflush", "type"=>"NC", "open"=>"P8_40", "trigger"=>"high"}]
  end

  context "with activations" do
    let(:machine2) { Machine.new }
    let(:run_switch) { machine2.send(:switches)[:run] }
    before(:each) do
      allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
      allow(I2CDevice).to receive(:new).and_return(double("fake_i2cdevice", write: nil, read: 1))
    end

    it "configures itself" do
      expect(machine.config).to be_a_kind_of(Configuration)
    end

    it "knows its ID" do
      expect(machine.id).to_not be_nil
    end

    it "creates a hash of valve objects" do
      key = machine.send(:valves).keys.first
      expect(machine.send(:valves)[key]).to be_a_kind_of(Valve)
    end

    it "creates a hash of switches" do
      expect(machine.send(:switches)[:run]).to be_a_kind_of(Hash)
    end

    it "creates a hash for each switch" do
      expect(run_switch.keys.sort).to eq( [:duplicate, :id, :name, :pin, :pin_id, :pull_down] )
    end

    it "has a hash of i2c devices" do
      expect(machine.send(:i2cs)["A"]).to be_a_kind_of(I2CDriver)
    end

    it "writes to the log if the time elapsed has been too long" do
      allow(valve_2).to receive(:in_position?).and_return(false)
      allow(machine).to receive(:log)

      machine.check_component_state(2)
      
      expect(machine).to have_received(:log).with("machine:check_component_state", "component_id: 2", "has timed out while closed").once
    end

    describe "#set_component_state" do
      it "calls open on the valve" do
        allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
        allow(valve_2).to receive(:open)
        machine.set_component_state(2, "open")

        expect(valve_2).to have_received(:open)
      end
    end
  end

  context "without activations" do
    before(:each) do
      Machine.any_instance.stub(:activate_valves)
      Machine.any_instance.stub(:activate_control_pins)
      allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
    end

    describe "#debounce" do
      it "doesn't call the block the first time" do
        @count = 0
        machine.debounce(:key, "value") { @count += 1 }
        expect(@count).to eq(0)
      end

      it "calls the block the second time" do
        @count = 0
        machine.debounce(:key, "value") { @count += 1 }
        machine.debounce(:key, "value") { @count += 1 }
        expect(@count).to eq(1)
      end

      it "doesn't call the block the third time" do
        @count = 0
        machine.debounce(:key, "value") { @count += 1 }
        machine.debounce(:key, "value") { @count += 1 }
        machine.debounce(:key, "value") { @count += 1 }
        expect(@count).to eq(1)
      end
    end

    describe "#activate_pins"

    describe "#on_change" do
      it "logs the step status when it changes" do
        allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
        allow(machine).to receive(:log)
        allow(machine).to receive(:done)
        allow(machine).to receive(:stepper).and_return(fake_stepper)
        allow(fake_stepper).to receive(:step).and_return("2:soaking", "2:soaking", "2:done")

        machine.run

        expect(machine).to have_received(:log).with("machine:run", "program starting", nil).once
        expect(machine).to have_received(:log).with("machine:run", "status", "2:soaking").once
        expect(machine).to have_received(:log).with("machine:run", "status", "2:done").once
      end
    end

    describe "#check_action" do
      it "recognizes a button push" do
        allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
        allow(machine).to receive(:check_button).with(:halt).and_return(:halt)
        machine.send(:check_action, :halt)
        expect(machine.send(:check_action, :halt)).to be_truthy
      end

      it "ignores the first button press" do
        allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
        allow(machine).to receive(:check_button).with(:run).and_return(:run)
        expect(machine.send(:check_action, :run)).to be_falsey
      end
    end

    describe "#check_set_program" do
      before(:each) do
        allow(Validator).to receive(:new).and_return(validator)
        allow(validator).to receive(:validate).and_return(true)
        allow(I2CDevice).to receive(:new).and_return(double("fake_i2cdevice", write: nil, read: 1))
      end

      it "recognizes a program selection" do
        allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
        allow(machine).to receive(:run)
        allow(machine).to receive(:program_selector).and_return(:clean)
        allow(machine).to receive(:check_action).and_return(false, true)
        expect { machine.ready }.to change { machine.program }
      end

      it "recognizes a clean program selection" do
        allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
        allow(machine).to receive(:check_button).with(:clean).and_return(:clean)
        allow(machine).to receive(:check_button).with(:brew).and_return(false)
        machine.program = nil

        machine.check_set_program
        expect(machine.program).to eq(nil)
        machine.check_set_program
        expect(machine.program).to eq(:clean)
      end

      it "recognizes a brew program selection" do
        allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
        allow(machine).to receive(:check_button).with(:clean).and_return(false)
        allow(machine).to receive(:check_button).with(:brew).and_return(:brew)
        machine.program = nil

        machine.check_set_program
        expect(machine.program).to eq(nil)
        machine.check_set_program
        expect(machine.program).to eq(:brew)
      end

      it "recognizes a load program selection" do
        allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
        allow(machine).to receive(:check_button).with(:clean).and_return(false)
        allow(machine).to receive(:check_button).with(:brew).and_return(false)
        machine.program = nil

        machine.check_set_program
        expect(machine.program).to eq(nil)
        machine.check_set_program
        expect(machine.program).to eq(:load)
      end
    end

    describe "#change_program" do
      before(:each) do
        allow(Validator).to receive(:new).and_return(validator)
        allow(I2CDevice).to receive(:new).and_return(double("fake_i2cdevice", write: nil, read: 1))
      end

      it "validates the program" do
        allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
        allow(validator).to receive(:validate)
        machine.change_program(:brew)
        expect(validator).to have_received(:validate)
      end

      it "lights up the program light when a valid program is selected" do
        allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
        allow(machine).to receive(:light_manager).and_return(light_manager)
        allow(validator).to receive(:validate).and_return(true)

        machine.change_program(:load)

        expect(light_manager).to have_received(:on_program_change).with(:load)
      end

      it "blinks the program light when the program is invalid" do
        allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
        allow(machine).to receive(:light_manager).and_return(light_manager)
        allow(validator).to receive(:validate).and_return(false)
        allow(light_manager).to receive(:add_blink)

        machine.change_program(:brew)

        expect(light_manager).to have_received(:add_blink).with(:brew)
      end

      it "writes to the log when the program is invalid" do
        allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
        allow(machine).to receive(:log)
        allow(Validator).to receive(:new).and_return(validator)
        allow(validator).to receive(:program_id).and_return(1)
        allow(validator).to receive(:component_ids).and_return([1, 2])
        allow(validator).to receive(:valve_ids).and_return([1])

        machine.change_program(:brew)

        expect(machine).to have_received(:log).with("machine:change_program", "program invalid", :brew)
      end
    end

    describe "#ready" do
      before(:each) do
        allow(Validator).to receive(:new).and_return(validator)
        allow(validator).to receive(:validate).and_return(true)
        allow(I2CDevice).to receive(:new).and_return(double("fake_i2cdevice", write: nil, read: 1))
      end

      it "loops until it gets a run command" do
        allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
        allow(machine).to receive(:run)
        allow(machine).to receive(:check_action).with(:run).and_return(nil, true)
        #allow(machine).to receive(:check_action).with(:reset).and_return(false)

        machine.change_program(:brew)
        machine.ready
        expect(machine).to have_received(:run)
      end

      it "tells the light manager we are in ready mode" do
        allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
        allow(machine).to receive(:run)
        allow(machine).to receive(:light_manager).and_return(light_manager)
        allow(machine).to receive(:check_action).with(:run).and_return(nil, true)
        machine.ready

        expect(light_manager).to have_received(:ready_mode)
      end

      it "tells the light manager we are paused" do
        allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
        allow(machine).to receive(:run)
        allow(machine).to receive(:light_manager).and_return(light_manager)
        allow(machine).to receive(:check_action).with(:run).and_return(true)
        machine.halt
        expect(light_manager).to have_received(:ready_mode).with(:paused)
      end

      it "deletes the stepper when a new program is selected" do
        allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
        allow(Stepper).to receive(:new).and_return(fake_stepper, fake_stepper2)
        allow(machine).to receive(:ready)
        allow(machine).to receive(:program_selector).and_return(:brew)
        stepper = machine.stepper
        machine.halt
        machine.check_set_program
        machine.check_set_program
        expect(machine.stepper).to_not eq(stepper)
      end

      it "can only exit the ready loop if the program has been validated" do
        allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
        allow(machine).to receive(:run)
        allow(machine).to receive(:check_action).with(:run).and_return(nil, true)
        allow(machine).to receive(:check_action).with(:reset).and_return(false)
        allow(validator).to receive(:validate).and_return(false, true)
        allow(machine).to receive(:program_selector).and_return(:load, :load, :brew)

        machine.ready

        expect(machine).to have_received(:run).once
      end
    end

    describe "#run" do
      before :each do
        allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
      end

      it "loops until it gets a halt command" do
        allow(machine).to receive(:halt)
        allow(machine).to receive(:stepper).and_return(fake_stepper)
        allow(fake_stepper).to receive(:step).and_return(:started)
        allow(machine).to receive(:check_action).with(:halt).and_return(nil, true)

        machine.run
        expect(machine).to have_received(:halt)
      end

      it "loops until it finishes its program" do
        allow(machine).to receive(:done)
        allow(machine).to receive(:stepper).and_return(fake_stepper)
        allow(fake_stepper).to receive(:step).and_return(:soaking, :done)

        machine.run
        expect(machine).to have_received(:done)
      end

      it "lights up the run light when it is running" do
        allow(machine).to receive(:ready)
        allow(machine).to receive(:light_manager).and_return(light_manager)
        allow(machine).to receive(:stepper).and_return(fake_stepper2)
        allow(machine).to receive(:check_action).with(:halt).and_return(nil, true)
        machine.run

        expect(light_manager).to have_received(:run_mode)
      end
    end

    describe "#done" do
      it "deletes the stepper when it finishes the program" do
        allow(GPIOPin).to receive(:new).and_return(double("fake_gpio_pin", digital_write: nil, digital_read: 1))
        allow(Stepper).to receive(:new).and_return(fake_stepper, fake_stepper2)
        allow(machine).to receive(:ready)
        stepper = machine.stepper
        machine.done
        expect(machine.stepper).to_not eq(stepper)
      end
    end
  end
end
