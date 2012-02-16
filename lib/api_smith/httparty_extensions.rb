# Monkey patches HTTParty to accept persistent connections.
module HTTParty
  class Request

    alias _original_http http
    def http
      options[:persistent] || _original_http
    end

    def perform
      validate
      setup_raw_request
      self.last_response = perform_inner_request
      handle_deflation
      handle_response
    end

    def perform_inner_request
      options[:persistent] ? http.request(uri, @raw_request) : http.request(@raw_request)
    end

  end
end