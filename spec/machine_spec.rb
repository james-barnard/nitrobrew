describe Machine do

  let(:machine) { Machine.new }
  let(:run_switch) { machine.send(:switches)[:run] }
  let(:valve_2) { machine.send(:valves)[2] }
  let(:fake_stepper) { double("fs1") }
  let(:fake_stepper2) { double("fs2") }

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
    expect(run_switch.keys.sort).to eq( [:id, :name, :pin, :pin_id, :pull_down] )
  end

  it "has a pin object that is a GPIOPin" do
    expect(run_switch[:pin]).to be_a_kind_of(GPIOPin)
  end

  describe "#on_change" do
    it "logs the step status when it changes" do
      allow(machine).to receive(:log)
      allow(machine).to receive(:done)
      allow(machine).to receive(:stepper).and_return(fake_stepper)
      allow(fake_stepper).to receive(:step).and_return("2:soaking", "2:soaking", "2:done")

      machine.run

      expect(machine).to have_received(:log).with("machine:run", "program starting", nil).once
      expect(machine).to have_received(:log).with("machine:run", "status", "2:soaking").once
      expect(machine).to have_received(:log).with("machine:run", "status", "2:done").once
    end


    it "logs the program when a new program is selected"
    it "calls the light manager when a program is selected"
    it "calls the light manager when the mode changes"

  end

  describe "#check_action" do
    it "recognizes a button push" do
      allow(machine).to receive(:check_button).with(:halt).and_return(:halt)
      machine.send(:check_action, :halt)
      expect(machine.send(:check_action, :halt)).to be_truthy
    end
  end

  describe "#check_set_program" do
    it "recognizes a program selection" do
      allow(machine).to receive(:check_set_program).and_return(:clean)
      allow(machine).to receive(:run)
      allow(machine).to receive(:check_action).and_return(:run)
      expect { machine.ready }.to change { machine.program }
    end

    it "recognizes a clean program selection" do
      allow(machine).to receive(:check_button).with(:clean).and_return(:clean)
      allow(machine).to receive(:check_button).with(:brew).and_return(false)
      expect(machine.check_set_program).to eq(nil)
      expect(machine.check_set_program).to eq(:clean)
    end

    it "recognizes a brew program selection" do
      allow(machine).to receive(:check_button).with(:clean).and_return(false)
      allow(machine).to receive(:check_button).with(:brew).and_return(:brew)
      expect(machine.check_set_program).to eq(nil)
      expect(machine.check_set_program).to eq(:brew)
    end

    it "recognizes a load program selection" do
      allow(machine).to receive(:check_button).with(:clean).and_return(false)
      allow(machine).to receive(:check_button).with(:brew).and_return(false)
      expect(machine.check_set_program).to eq(nil)
      expect(machine.check_set_program).to eq(:load)
    end

    it "lights up the brew light when brew is selected"
    it "lights up the clean light when clean is selected"
    it "lights up the load light when load is selected"
  end

  describe "#ready" do
    it "loops until it gets a run command" do
      allow(machine).to receive(:run)
      allow(machine).to receive(:check_action).with(:run).and_return(nil, true)
      allow(machine).to receive(:check_action).with(:reset).and_return(false)

      machine.ready
      expect(machine).to have_received(:run)
    end

    it "lights up the ready light when in ready mode"

    it "lights up both mode lights when it receives a halt"

    it "deletes the stepper when a new program is selected" do
      allow(Stepper).to receive(:new).and_return(fake_stepper, fake_stepper2)
      allow(machine).to receive(:ready)
      allow(machine).to receive(:program_selector).and_return(:brew)
      stepper = machine.stepper
      machine.halt
      machine.check_set_program
      machine.check_set_program
      expect(machine.stepper).to_not eq(stepper)
    end

    it "turns off the run light when a new program is selected"

  end

  describe "#run" do
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

    it "lights up the run light when it is running"
  end

  describe "#done" do
    it "deletes the stepper when it finishes the program" do
      allow(Stepper).to receive(:new).and_return(fake_stepper, fake_stepper2)
      allow(machine).to receive(:ready)
      stepper = machine.stepper
      machine.done
      expect(machine.stepper).to_not eq(stepper)
    end
  end

  describe "#set_component_state" do
    it "calls open on the valve" do
      allow(valve_2).to receive(:open)
      machine.set_component_state(2, "open")

      expect(valve_2).to have_received(:open)
    end
  end
  
  let(:timed_out_error) { "Valve Valve 2 has timed out: 3.00033 seconds" }
  it "raises an error if the time elapsed has been too long" do
    allow(valve_2).to receive(:in_position?).and_raise(timed_out_error)
    allow(machine).to receive(:log)
    expect { machine.check_component_state(2) }.to raise_error(timed_out_error)
    expect(machine).to have_received(:log).once
  end
end
