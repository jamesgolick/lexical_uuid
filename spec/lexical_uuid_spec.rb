require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "LexicalUUID" do
  describe "creating a UUID with no parameters" do
    before do
      @uuid = LexicalUUID.new
    end

    it "has a worker id" do
      @uuid.worker_id.should_not be_nil
    end

    it "has a timestamp in usecs" do
      @uuid.timestamp.should < Time.stamp
    end

    it "serializes to bytes" do
      expected_bytes = [@uuid.timestamp >> 32,
                        @uuid.timestamp & 0xffffffff,
                        @uuid.worker_id >> 32,
                        @uuid.worker_id & 0xffffffff].pack("iiii")
      @uuid.to_bytes.should == expected_bytes
    end
  end

  describe "reinitializing the uuid from bytes" do
    describe "with a correctly sized byte array" do
      before do
        @bytes = [1234567890 >> 32,
                  1234567890 & 0xffffffff,
                  9876543210 >> 32,
                  9876543210 & 0xffffffff].pack("iiii")
        @uuid  = LexicalUUID.new(@bytes)
      end

      it "correctly extracts the timestamp" do
        @uuid.timestamp.should == 1234567890
      end

      it "correctly extracts the worker id" do
        @uuid.worker_id.should == 9876543210
      end
    end
    
    describe "with a mis-sized byte array" do
      it "raises ArgumentError" do
        lambda {
          LexicalUUID.new("asdf")
        }.should raise_error(ArgumentError)
      end
    end
  end

  describe "initializing a uuid from a timestamp and worker_id" do
    before do
      @timestamp = 15463021018891620831
      @worker_id = 9964740229835689317
      @uuid      = LexicalUUID.new(@timestamp, @worker_id)
    end

    it "sets the timestamp" do
      @uuid.timestamp.should == @timestamp
    end

    it "sets the worker_id" do
      @uuid.worker_id.should == @worker_id
    end
  end

  describe "converting a uuid in to a guid" do
    before do
      @uuid = LexicalUUID.new(1286235492870036, -8436540173626891075)
    end
    
    it "matches other uuid->guid implementations" do
      @uuid.to_guid.should == "d3910400-9467-a609-6963-eb8abd24a829"
    end
  end

  describe "initializing from a guid" do
    before do
      @uuid = LexicalUUID.new("d3910400-a04d-1c02-69bd-2d82f733af24")
    end
    
    it "correctly initializes the timestamp" do
      @uuid.timestamp.should == 1286235366378912
    end

    it "correctly initializes the worker_id" do
      @uuid.worker_id.should == -9066382215542262793
    end
  end

  describe "initializing with a timestamp with no worker_id" do
    before do
      @uuid = LexicalUUID.new(12345)
    end

    it "sets the timestamp" do
      @uuid.timestamp.should == 12345
    end

    it "uses the default worker_id" do
      @uuid.worker_id.should == LexicalUUID.worker_id
    end
  end

  describe "comparing uuids" do
    it "compares first by timestamp" do
      (LexicalUUID.new(123) <=> LexicalUUID.new(234)).should == -1
      (LexicalUUID.new(223) <=> LexicalUUID.new(134)).should == 1
    end

    it "compares by worker_id if the timestamps are equal" do
      (LexicalUUID.new(123, 1) <=> LexicalUUID.new(123, 2)).should == -1
      (LexicalUUID.new(123, 2) <=> LexicalUUID.new(123, 1)).should == 1
      (LexicalUUID.new(123, 1) <=> LexicalUUID.new(123, 1)).should == 0
    end
  end

  describe "==" do
    it "is equal when the timestamps and worker ids are equal" do
      LexicalUUID.new(123, 123).should == LexicalUUID.new(123, 123)
    end

    it "is not equal when the timestamps are not equal" do
      LexicalUUID.new(223, 123).should_not == LexicalUUID.new(123, 123)
    end

    it "is not equal when the worker_ids are not equal" do
      LexicalUUID.new(123, 223).should_not == LexicalUUID.new(123, 123)
    end
  end

  describe "eql?" do
    it "is equal when the timestamps and worker ids are equal" do
      LexicalUUID.new(123, 123).should eql(LexicalUUID.new(123, 123))
    end

    it "is not equal when the timestamps are not equal" do
      LexicalUUID.new(223, 123).should_not eql(LexicalUUID.new(123, 123))
    end

    it "is not equal when the worker_ids are not equal" do
      LexicalUUID.new(123, 223).should_not eql(LexicalUUID.new(123, 123))
    end
  end

  describe "hash" do
    it "has the same hash if the timestamp/worker_id are the same" do
      LexicalUUID.new(123, 123).hash.should == LexicalUUID.new(123, 123).hash
    end

    it "has a different hash when the timestamps are different" do
      LexicalUUID.new(223, 123).hash.should_not == LexicalUUID.new(123, 123).hash
    end

    it "has a different hash when the worker_ids are not equalc" do
      LexicalUUID.new(123, 223).hash.should_not == LexicalUUID.new(123, 123).hash
    end
  end

  describe "initializing with a time object" do
    before do
      @time = Time.now
      @uuid = LexicalUUID.new(@time)
    end

    it "uses the time's stamp object" do
      @uuid.timestamp.should == @time.stamp
    end
  end
end
