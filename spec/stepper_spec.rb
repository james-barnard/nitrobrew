describe Stepper do
  let (:machine) { double("fake machine", id: 1, set_component_state: nil) }

  before(:all) do
    @db = SQLite3::Database.new("stepper.db")
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
  describe "stepper" do
    before(:each) { allow(stepper).to receive(:test_run_id).and_return(1) }
    it "starts at the beginning of the program when there are no step statuses" do
      expect(stepper.current_step).to eq(10)
    end

    it "gets the current step number" do
      stepper.save_step_status(10, 1, :soaking)
      expect(stepper.current_step).to eq(10)
    end

    it "returns the first step not completed" do
      stepper.save_step_status(10, 1, :completed)
      expect(stepper.current_step).to eq(20)
    end

    it "returns the final step when the last step is completed" do
      stepper.save_step_status(10, 1, :completed)
      stepper.save_step_status(20, 1, :completed)
      expect(stepper.current_step).to eq(20)
    end

    it "gets the component states for a step" do
      allow(stepper).to receive(:current_step).and_return(10)
      expect(stepper.component_states.length).to eq(2)
    end

    it "sets the component states" do
      allow(stepper).to receive(:current_step).and_return(10)
      stepper.set_component_states
      expect(machine).to have_received(:set_component_state).with(1, :open).once
      expect(machine).to have_received(:set_component_state).with(2, :closed).once
    end
  end

  describe "#current_status" do
    it "returns nil when not started" do
      expect(stepper.current_status).to eq(nil)
    end
  end

  describe "#step" do
    before(:each) { allow(stepper).to receive(:test_run_id).and_return(1) }
    it "sets the step status in the database when the state changes" do
      allow(stepper).to receive(:current_step).and_return(10)
      allow(machine).to receive(:check_component_state).and_return(false)

      stepper.step
      expect(stepper.send(:single_value) { @db.execute("select status from step_statuses") }
      ).to eq("pending")
    end

    it "moves to the next step" do
      stepper.save_step_status(10, 1, :completed)
      allow(machine).to receive(:check_component_state).and_return(false)

      expect(stepper.step).to eq("20:pending")
    end

    it "moves to the next step" do
      stepper.save_step_status(10, 1, :completed)
      allow(machine).to receive(:check_component_state).and_return(false)

      stepper.step
      expect(machine).to have_received(:set_component_state).with(1, :closed).once
      expect(machine).to have_received(:set_component_state).with(2, :open).once
    end

    context "reports the step status" do
      before(:each) { allow(stepper).to receive(:test_run_id).and_return(1) }
      it "one component is not in position" do
        allow(machine).to receive(:check_component_state).and_return(false)

        expect(stepper.step).to eq("10:pending")
        expect(machine).to have_received(:check_component_state).with(1).once
        expect(machine).not_to have_received(:check_component_state).with(2)
      end

      it "all components are in position" do
        stepper.save_step_status(10, 1, :pending)
        allow(machine).to receive(:check_component_state).and_return(true)

        expect(stepper.step).to eq("10:soaking")
        expect(machine).to have_received(:check_component_state).with(1).once
        expect(machine).to have_received(:check_component_state).with(2).once
      end

      it "has not finished soaking" do
        stepper.save_step_status(10, 1, :soaking)
        allow(stepper).to receive(:check_soak_time).and_return(:soaking)

        expect(stepper.step).to eq("10:soaking")
      end

      context "has finished soaking" do
        it "returns completed" do
          stepper.save_step_status(10, 1, :soaking)
          allow(stepper).to receive(:check_soak_time).and_return(:completed)

          expect(stepper.step).to eq("10:completed")
        end

        it "moves to the next step when the duration has ended" do
          stepper.save_step_status(10, 1, :soaking)
          allow(stepper).to receive(:check_soak_time).and_return(:completed)

          expect(stepper.step).to eq("10:completed")
        end

        it "returns done when it finishes the last step" do
          stepper.save_step_status(20, 1, :completed)

          expect(stepper.step).to eq("20:done")
        end
      end
    end
  end

  describe "#save_step_status" do
    it "creates a step status record" do
      expect { stepper.save_step_status(10, 1, :soaking) }.to change {
        stepper.send(:single_value) { @db.execute("select count(*) from step_statuses") }
      }.by(1)
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
