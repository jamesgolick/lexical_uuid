require 'thread'

class IncreasingMicrosecondClock
  def initialize(timestamp_factory = lambda { Time.stamp },
                 mutex             = Mutex.new)
    @timestamp_factory = timestamp_factory
    @mutex             = mutex
    @time              = @timestamp_factory.call
  end

  def call
    @mutex.synchronize {
      new_time = @timestamp_factory.call

      @time =
        if new_time > @time
          new_time
        else
          @time + 1
        end
    }
  end

  @instance = new

  class << self
    attr_accessor :instance

    def call
      instance.call
    end
  end
end
