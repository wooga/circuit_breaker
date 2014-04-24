# CircuitBreaker

Implementation of the circuit breaker pattern to protect against high latencies or outages of services.
See Martin Fowlers [writeup](http://martinfowler.com/bliki/CircuitBreaker.html) for more information.

This is a very basic implementation. There is another implementation with a nice DSL by [wsargent.](https://github.com/wsargent/circuit_breaker)


## Installation

Add this line to your application's Gemfile:

    gem 'circuit_breaker'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install circuit_breaker

## Usage

````
require 'circuit_breaker'

options = {
  # number of failures before the circuit breaker trips
  failure_threshold: 5,
  # invocation timeout in seconds
  invocation_timeout: 0.5,
  # a list of timeouts for consecutive failures in seconds. can be used for exponential backoff
  reset_timeouts: [2, 4, 8, 16, 32, 64, 128]
}

circuit_breaker = CircuitBreaker::Basic.new(options)

begin
  circuit_breaker.execute do
    http_api_call()
  end
rescue CircuitBreaker::CircuitBrokenError
  $stderr.puts "Circuit tripped"
rescue Timeout::Error
  $stderr.puts "Call took too long"
rescue Error
  $stderr.puts "Error thrown by 'http_api_call'"
end
````
## Contributing

1. Fork it ( https://github.com/wooga/circuit_breaker/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
