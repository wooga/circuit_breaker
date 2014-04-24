# encoding: UTF-8
require 'test_helper'

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
    circuit_breaker = CircuitBreaker::Basic.new(failure_threshold: 1, invocation_timeout: invocation_timeout)

    circuit_breaker.execute do
      sleep invocation_timeout + 0.1
    end

    assert_raises CircuitBreaker::CircuitBrokenException do
      circuit_breaker.execute do
        assert false, "The call should not be executed in open state"
      end
    end
  end
end
