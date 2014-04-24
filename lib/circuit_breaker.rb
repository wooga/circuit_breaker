require "circuit_breaker/version"
require "circuit_breaker/circuit_broken_exception"
require "timeout"


module CircuitBreaker
  class Basic

    DEFAULTS = {
      failure_threshold:  5,
      invocation_timeout: 2,
      reset_timeout:      10
    }

    def initialize(options = {})
      options             = DEFAULTS.merge(options)
      @failure_threshold  = options[:failure_threshold]
      @invocation_timeout = options[:invocation_timeout]
      @reset_timeout      = options[:reset_timeout]
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
      @failure_count = 0
      @last_failure_time = nil
    end


    def state
      case
        when (@failure_count >= @failure_threshold) &&
          (Time.now - @last_failure_time) > @reset_timeout
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
