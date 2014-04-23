$LOAD_PATH.unshift( File.join( File.dirname(__FILE__), "..", "lib") )

require "rubygems"
require 'minitest/spec'
require 'minitest/autorun'
require 'circuit_breaker'
