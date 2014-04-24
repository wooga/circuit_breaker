require "circuit_breaker/version"
require "circuit_breaker/circuit_broken_exception"
require "timeout"


module CircuitBreaker
  class Basic

    DEFAULTS = {
      failure_threshold:    5,
      invocation_timeout:   2,
      reset_timeouts:      10
    }

    def initialize(options = {})
      options             = DEFAULTS.merge(options)
      @failure_threshold  = options[:failure_threshold]
      @invocation_timeout = options[:invocation_timeout]
      @reset_timeouts     = Array(options[:reset_timeouts])
      @last_failure_time  = nil
      @failure_count      = 0
      @retry_counter      = 0
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
      @retry_counter     = 0
    end


    def state
      case
        when (@failure_count >= @failure_threshold) &&
          (Time.now - @last_failure_time) > @reset_timeouts[[@reset_timeouts.size - 1, @retry_counter].min]
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
          @retry_counter += 1 if half_open?
          record_failure
          raise
        end
      else
        raise CircuitBrokenException.new("Circuit is broken")
      end
    end

    def record_failure
      @failure_count += 1
      @last_failure_time = Time.now
    end
  end
end
