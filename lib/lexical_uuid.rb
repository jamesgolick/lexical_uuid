require "rubygems"
require "socket"
require "fnv"
require File.join(File.dirname(__FILE__), "time_ext")
require File.join(File.dirname(__FILE__), "increasing_microsecond_clock")

class LexicalUUID
  class << self
    def worker_id
      @worker_id ||= create_worker_id
    end

    private
      def create_worker_id
        fqdn = Socket.gethostbyname(Socket.gethostname).first
        pid  = Process.pid
        FNV.new.fnv1a_64("#{fqdn}-#{pid}")
      end
  end

  attr_reader :worker_id, :timestamp

  def initialize(timestamp = nil, worker_id = nil, timestamp_factory = IncreasingMicrosecondClock)
    case timestamp
    when Fixnum, Bignum
      @timestamp = timestamp
      @worker_id = worker_id || self.class.worker_id
    when String
      case timestamp.size
      when 16
        from_bytes(timestamp)
      when 36
        elements = timestamp.split("-")
        from_bytes(Array(elements.join).pack('H32'))
      else
        raise ArgumentError, 
          "#{timestamp} was incorrectly sized. Must be 16 timestamp."
      end
    when Time
      @timestamp = timestamp.stamp
      @worker_id = self.class.worker_id
    when nil
      @worker_id = self.class.worker_id
      @timestamp = timestamp_factory.call
    end
  end

  def to_bytes
    [timestamp >> 32,
      timestamp & 0xffffffff,
      worker_id >> 32,
      worker_id & 0xffffffff].pack("NNNN")
  end

  # Also borrowed from simple_uuid
  def to_guid
    elements     = to_bytes.unpack("NnnCCa6")
    node         = elements[-1].unpack('C*')
    elements[-1] = '%02x%02x%02x%02x%02x%02x' % node
    "%08x-%04x-%04x-%02x%02x-%s" % elements
  end

  def <=>(other)
    timestamp == other.timestamp ? 
      worker_id <=> other.worker_id : timestamp <=> other.timestamp
  end

  def ==(other)
    other.is_a?(LexicalUUID) &&
      timestamp == other.timestamp &&
        worker_id == other.worker_id
  end

  def eql?(other)
    self == other
  end

  def hash
    to_bytes.hash
  end

  private
    def from_bytes(bytes)
      time_high, time_low, worker_high, worker_low = bytes.unpack("NNNN")
      @timestamp = (time_high << 32) | time_low
      @worker_id = (worker_high << 32) | worker_low
    end
end
