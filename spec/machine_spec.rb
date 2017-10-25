describe Machine do 

  let(:machine) {Machine.new}

  it "configures itself" do
    expect(machine.config).to be_a_kind_of(Configuration)
  end

  it "knows its ID" do
    expect(machine.id).to_not be_nil
  end

  it "defaults to offline status" do
    expect(machine.status).to eq("offline")
  end
  
  it "can change its status to busy" do
    machine.set_busy
    expect(machine.status).to eq("busy")
  end

  it "can change its status to ready" do
    machine.set_ready
    expect(machine.status).to eq("ready")
  end

  it "creates a hash of valve objects" do
    key = machine.send(:valves).keys.first
    expect(machine.send(:valves)[key]).to be_a_kind_of(Valve)
  end

  it "validates its config"

end