require "circuit_breaker/version"
require "circuit_breaker/circuit_broken_error"
require "timeout"


module CircuitBreaker
  class Basic

    DEFAULTS = {
      failure_threshold:    5,
      invocation_timeout:   2,
      reset_timeouts:      10
    }

    attr_reader :failure_count, :last_failure_time, :failure_threshold

    def initialize(options = {})
      options             = DEFAULTS.merge(options)
      @failure_threshold  = options[:failure_threshold]
      @invocation_timeout = options[:invocation_timeout]
      @reset_timeouts     = Array(options[:reset_timeouts])
      @last_failure_time  = nil
      @failure_count      = 0
    end

    def closed?
      state == :closed
    end

    def open?
      state == :open
    end

    def half_open?
      state == :half_open
    end

    def trip!
      @failure_count = @failure_threshold
      @last_failure_time = Time.now
    end

    def reset!
      @failure_count     = 0
      @last_failure_time = nil
    end

    def retry_counter
      @failure_count - @failure_threshold
    end

    def reset_timeout
      min = [@reset_timeouts.size - 1, retry_counter].min
      index = min > 0 ? rand(min) + 1 : 0
      @reset_timeouts[index]
    end


    def state
      case
        when (@failure_count >= @failure_threshold) &&
          (Time.now - @last_failure_time) > reset_timeout
          :half_open
        when @failure_count >= @failure_threshold
          :open
        else
          :closed
      end
    end

    def execute &block
      if closed? || half_open?
        begin
          Timeout::timeout(@invocation_timeout) do
            block.call if block_given?
          end
          reset!
        rescue Timeout::Error
          record_failure
          raise
        end
      else
        raise CircuitBrokenError.new("Circuit is broken")
      end
    end

    def record_failure
      @failure_count += 1
      @last_failure_time = Time.now
    end
  end

end

