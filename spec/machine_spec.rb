describe Machine do

  let(:machine) { Machine.new }
  let(:first_switch) { machine.send(:switches)[1] }
  let(:valve_v2) { machine.send(:valves)["v2"] }

  it "configures itself" do
    expect(machine.config).to be_a_kind_of(Configuration)
  end

  it "knows its ID" do
    expect(machine.id).to_not be_nil
  end

  xit "creates a hash of valve objects" do
    key = machine.send(:valves).keys.first
    expect(machine.send(:valves)[key]).to be_a_kind_of(Valve)
  end

  it "creates a hash of switches" do
    expect(machine.send(:switches)[1]).to be_a_kind_of(Hash)
  end

  it "creates a hash for each switch" do
    expect(first_switch.keys.sort).to eq( [:id, :name, :pin, :pull_down] )
  end

  describe "#check_button" do
    it "recognizes a button push" do
      allow(machine).to receive(:check_button).with(:halt).and_return(:halt)
      machine.send(:check_action, :halt)
      expect(machine.send(:check_action, :halt)).to be_truthy
    end
  end

  describe "#check_set_program" do
    it "recognizes a program selection" do
      allow(machine).to receive(:check_set_program).and_return(:clean)
      allow(machine).to receive(:ready)
      expect { machine.start }.to change { machine.program }
    end
  end

  describe "#log" do
    let(:stdout_logger) { log = Logger.new(STDOUT) }

    it "logs select program" do
      allow(machine).to receive(:check_set_program).and_return(:clean)
      allow(machine).to receive(:ready)
      allow(machine).to receive(:logger).and_return(stdout_logger)

      expect { machine.start }.to output.to_stdout_from_any_process
    end
  end

  describe "#start" do
    it "loops until it gets a program" do
      allow(machine).to receive(:ready)
      allow(machine).to receive(:check_set_program).and_return(nil, "a program")

      machine.start
      expect(machine).to have_received(:ready)
    end
  end

  describe "#ready" do
    it "loops until it gets a run command" do
      allow(machine).to receive(:run)
      allow(machine).to receive(:check_action).with(:run).and_return(nil, true)
      allow(machine).to receive(:check_action).with(:reset).and_return(false)

      machine.ready
      expect(machine).to have_received(:run)
    end

    it "loops until it gets a reset command" do
      allow(machine).to receive(:start)
      allow(machine).to receive(:check_action).with(:run).and_return(false)
      allow(machine).to receive(:check_action).with(:reset).and_return(nil, true)

      machine.ready
      expect(machine).to have_received(:start)
    end
  end

  describe "#run" do
    let(:fake_stepper) { double() }
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
  end

  describe "#set_component_state" do
    xit "calls open on the valve" do
      allow(valve_v2).to receive(:open)
      machine.set_component_state("v2", "open")

      expect(valve_v2).to have_received(:open)
    end
  end
end
