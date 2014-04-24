# encoding: UTF-8
require 'test_helper'

def successful_method
  nil
end

def slow_method(sleep_time)
  sleep(sleep_time)
end

describe CircuitBreaker::Basic do

  it "should initialize in a closed state" do
    assert CircuitBreaker::Basic.new.closed?
  end

  it "should trip the circuit breaker" do
    circuit_breaker = CircuitBreaker::Basic.new
    circuit_breaker.trip!

    assert circuit_breaker.open?
  end

  it "should reset the circuit breaker" do
    circuit_breaker = CircuitBreaker::Basic.new
    circuit_breaker.trip!
    assert circuit_breaker.open?

    circuit_breaker.reset!

    assert circuit_breaker.closed?
  end

  it "should execute the call in an closed state" do
    circuit_breaker = CircuitBreaker::Basic.new
    assert CircuitBreaker::Basic.new.closed?

    @mock = MiniTest::Mock.new
    @mock.expect(:do_something, nil)

    circuit_breaker.execute do
      @mock.do_something
    end

    @mock.verify
  end

  it "should trip after the failure threshold has been exceeded" do
    invocation_timeout = 0.1
    circuit_breaker    = CircuitBreaker::Basic.new(failure_threshold: 1, invocation_timeout: invocation_timeout)

    assert_raises Timeout::Error do
      circuit_breaker.execute do
        slow_method(invocation_timeout + 0.1)
      end
    end

    assert_raises CircuitBreaker::CircuitBrokenException do
      circuit_breaker.execute do
        assert false, "The call should not be executed in open state"
      end
    end
  end

  it "should reset after reset timeout" do
    reset_timeouts  = 0.1
    circuit_breaker = CircuitBreaker::Basic.new(reset_timeouts: reset_timeouts)

    # switch into an open state
    circuit_breaker.trip!

    assert circuit_breaker.open?

    sleep(reset_timeouts)

    assert circuit_breaker.half_open?
  end

  it "should change from half open to closed on success" do
    reset_timeouts  = 0.1
    circuit_breaker = CircuitBreaker::Basic.new(reset_timeouts: reset_timeouts)

    # switch into an open state
    circuit_breaker.trip!

    sleep(reset_timeouts)

    assert circuit_breaker.half_open?

    circuit_breaker.execute do
      successful_method
    end

    assert circuit_breaker.closed?
  end

  it "should change from hald open to closed on failure" do
    invocation_timeout = 0.1
    reset_timeouts     = 0.1
    circuit_breaker    = CircuitBreaker::Basic.new(invocation_timeout: invocation_timeout, reset_timeouts: reset_timeouts)
    circuit_breaker.trip!

    sleep(reset_timeouts)

    assert circuit_breaker.half_open?

    assert_raises Timeout::Error do
      circuit_breaker.execute do
        slow_method(invocation_timeout + 0.1)
      end
    end

    assert circuit_breaker.open?
  end

  it "should back off exponentially" do
    invocation_timeout = 0.1
    reset_timeout      = 0.1
    reset_timeouts     = [reset_timeout, 2 * reset_timeout, 3 * reset_timeout]
    circuit_breaker    = CircuitBreaker::Basic.new(failure_threshold: 1, invocation_timeout: invocation_timeout, reset_timeouts: reset_timeouts)

    reset_timeouts.each do |timeout|
      assert_raises Timeout::Error do
        circuit_breaker.execute do
          slow_method(invocation_timeout + 0.1)
        end
      end
      assert circuit_breaker.open?
      sleep(timeout)
    end
  end


end
