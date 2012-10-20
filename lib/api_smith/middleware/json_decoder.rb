require 'multi_json'

module APISmith
  module Middleware
    class JSONDecoder < Faraday::Response::Middleware

      def parse(body)
        MultiJson.decode body
      end

    end

    # Now, register it with faraday.
    require 'faraday'
    Faraday.register_middleware :response, api_smith_json: JSONDecoder

  end
end