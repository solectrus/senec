require 'senec/version'
require 'senec/connection'
require 'senec/state'
require 'senec/request'

module Senec
  class Error < StandardError; end
  class DecodingError < StandardError; end
end
