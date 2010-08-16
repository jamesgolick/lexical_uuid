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
                        @uuid.worker_id & 0xffffffff].pack("NNNN")
      @uuid.to_bytes.should == expected_bytes
    end
  end

  describe "reinitializing the uuid from bytes" do
    before do
      @bytes = [1234567890 >> 32,
                1234567890 & 0xffffffff,
                9876543210 >> 32,
                9876543210 & 0xffffffff].pack("NNNN")
      @uuid  = LexicalUUID.new(@bytes)
    end

    it "correctly extracts the timestamp" do
      @uuid.timestamp.should == 1234567890
    end

    it "correctly extracts the worker id" do
      @uuid.worker_id.should == 9876543210
    end
  end
end
