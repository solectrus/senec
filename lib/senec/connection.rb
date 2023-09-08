require 'faraday'
require 'faraday/net_http_persistent'
require 'forwardable'

module Senec
  class Connection
    def initialize(host:, schema: 'http')
      @url = "#{schema}://#{host}"
    end

    extend Forwardable
    def_delegators :faraday, :get, :post

    private

    def faraday
      @faraday ||= Faraday.new @url,
                               ssl: { verify: false },
                               headers: {
                                 'Connection' => 'keep-alive'
                               } do |f|
        f.adapter :net_http_persistent, pool_size: 5 do |http|
          http.idle_timeout = 30
        end
      end
    end
  end
end
