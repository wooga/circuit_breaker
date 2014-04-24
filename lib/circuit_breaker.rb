require "circuit_breaker/version"
require "circuit_breaker/circuit_broken_exception"
require "timeout"


module CircuitBreaker
  class Basic

    DEFAULTS = {
      failure_threshold:  5,
      invocation_timeout: 2
    }

    def initialize(options = {})
      options = DEFAULTS.merge(options)
      @failure_count = 0
      @failure_threshold = options[:failure_threshold]
      @invocation_timeout = options[:invocation_timeout]
    end

    def closed?
      state == :closed
    end

    def open?
      state == :open
    end

    def trip!
      @failure_count = @failure_threshold
    end

    def reset!
      @failure_count = 0
    end

    def state
     @failure_count >= @failure_threshold ? :open : :closed
    end

    def execute &block
      if closed?
        begin
          Timeout::timeout(@invocation_timeout) do
            block.call if block_given?
          end
        rescue Timeout::Error
          @failure_count += 1
        end
      else
        raise CircuitBrokenException.new("Circuit is broken")
      end
    end
    #def initialize
      #@invocation_timeout = 0.01
      #@failure_threshold = 5
      #@reset_timeout = 0.1
      #reset
    #end


    #def call args
      #case state
      #when :closed, :half_open
        #begin
          #do_call args
        #rescue Timeout::Error
          #record_failure
          #raise $!
        #end
      #when :open then raise CircuitBreaker::Open
      #else raise "Unreachable Code"
      #end
    #end

    #def do_call args
      #result = Timeout::timeout(@invocation_timeout) do
        #@circuit.call args
      #end
      #reset
      #return result
    #end

    #def reset
      #@failure_count = 0
      #@last_failure_time = nil
    #end

    #

    #def record_failure
      #@failure_count += 1
      #@last_failure_time = Time.now
    #end
  end
end
