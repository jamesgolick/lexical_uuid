require "rubygems"
require "socket"
require "inline"

class String
  inline :C do |builder|
    builder.c <<-__END__
      static long fnv1a() {
        int hash = 2166136261;
        int i    = 0;
      
        for(i = 0; i < RSTRING_LEN(self); i++) {
          hash ^= RSTRING_PTR(self)[i];
          hash *= 16777619;
        }

        return hash;
      }
    __END__
  end
end

# Borrowed from the SimpleUUID gem
class Time
  def self.stamp
    Time.now.stamp
  end
  
  def stamp
    to_i * 1_000_000 + usec
  end
end

class LexicalUUID
  class << self
    def worker_id
      @worker_id ||= create_worker_id
    end

    private
      def create_worker_id
        fqdn = Socket.gethostbyname(Socket.gethostname).first
        pid  = Process.pid
        "#{fqdn}-#{pid}".fnv1a
      end
  end

  attr_reader :worker_id, :jitter, :timestamp

  def initialize(timestamp = nil, jitter = nil, worker_id = nil)
    case timestamp
    when Fixnum, Bignum
      @timestamp = timestamp
      @jitter    = jitter || create_jitter
      @worker_id = worker_id || self.class.worker_id
    when String
      case timestamp.size
      when 16
        from_bytes(timestamp)
      when 36
        elements = timestamp.split("-")
        from_bytes([elements.join].pack('H32'))
      else
        raise ArgumentError, 
          "#{timestamp} was incorrectly sized. Must be 16 timestamp."
      end
    when Time
      @timestamp = timestamp.stamp
      @jitter    = create_jitter
      @worker_id = self.class.worker_id
    when nil
      @worker_id = self.class.worker_id
      @jitter    = create_jitter
      @timestamp = Time.stamp
    end
  end

  def to_bytes
    [timestamp >> 32,
     timestamp & 0xffffffff,
     jitter,
     worker_id].pack("iIii")
  end

  # Also borrowed from simple_uuid
  def to_guid
    elements     = to_bytes.unpack("NnnCCa6")
    node         = elements[-1].unpack('C*')
    elements[-1] = '%02x%02x%02x%02x%02x%02x' % node
    "%08x-%04x-%04x-%02x%02x-%s" % elements
  end

  def <=>(other)
    if timestamp == other.timestamp && jitter == other.jitter
      worker_id <=> other.worker_id
    elsif timestamp == other.timestamp
      jitter <=> other.jitter
    else
      timestamp <=> other.timestamp
    end
  end

  def ==(other)
    other.is_a?(LexicalUUID) &&
      timestamp == other.timestamp &&
        jitter == other.jitter &&
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
      time_high, time_low, @jitter, @worker_id = bytes.unpack("iIii")
      @timestamp = (time_high << 32) | time_low
    end

    def create_jitter
      rand(2**32)
    end
end
