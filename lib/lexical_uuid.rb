require "rubygems"
require "socket"
require "inline"

class String
  inline :C do |builder|
    builder.c <<-__END__
      static long fnv1a() {
        long hash = 0xcbf29ce484222325;
        long i = 0;
      
        for(i = 0; i < RSTRING(self)->len; i++) {
          hash ^= RSTRING(self)->ptr[i];
          hash *= 0x100000001b3;
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
        Socket.gethostbyname(Socket.gethostname).first.fnv1a
      end
  end

  attr_reader :worker_id, :timestamp

  def initialize(timestamp = nil, worker_id = nil)
    case timestamp
    when Fixnum, Bignum
      @timestamp = timestamp
      @worker_id = worker_id
    when String
      case timestamp.size
      when 16
        from_bytes(timestamp)
      when 36
        elements = timestamp.split("-")
        from_bytes(elements.join.to_a.pack('H32'))
      else
        raise ArgumentError, 
          "#{timestamp} was incorrectly sized. Must be 16 timestamp."
      end
    when nil
      @worker_id = self.class.worker_id
      @timestamp = Time.stamp
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

  private
    def from_bytes(bytes)
      time_high, time_low, worker_high, worker_low = bytes.unpack("NNNN")
      @timestamp = (time_high << 32) | time_low
      @worker_id = (worker_high << 32) | worker_low
    end
end
