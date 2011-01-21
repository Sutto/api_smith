require 'httparty'

module APISmith
  # A base class for building api clients (with a specified endpoint and general
  # shared options) on top of HTTParty, including response unpacking and
  # transformation.
  #
  # @author Darcy Laycock
  # @author Steve Webb
  class Base
    include HTTParty
    
    def initialize(*)
    end

    def self.endpoint(value = nil)
      define_method(:endpoint) { value }
    end
    
    def get(path, options = {})
      request! :get, path, options, :query
    end
    
    def post(path, options = {})
      request! :post, path, options, :query, :body
    end
    
    def put(path, options = {})
      request! :put, path, options, :query, :body
    end
    
    def delete(path, options = {})
      request! :delete, path, options, :query
    end
    
  protected

    def request!(method, path, options, *param_types)
      full_path = path_for(path)
      request_options = merged_options_for(:request, options)
      param_types.each do |type|
        request_options[type] = merged_options_for(type, options)
      end
      response = self.class.send method, full_path, request_options
      parsed_response = response.parsed_response
      check_response_errors parsed_response
      inner_response = extract_response path, parsed_response, options
      transform_response inner_response, options
    end
    
    def check_response_errors(response)
      # Do nothing in this version of the api
    end

    def merged_options_for(type, options)
      base = send :"base_#{type}_options"
      base.merge!(send(:"#{type}_options") || {})
      base.merge! options.fetch(:"extra_#{type}", {})
      base
    end
    
    def base_body_options
      {}
    end
    
    def base_query_options
      {}
    end
    
    def base_request_options
      {}
    end
    
    def query_options
      @query_options ||= {}
    end
    
    def body_options
      @body_options ||= {}
    end
    
    def request_options
      @request_options ||= {}
    end
    
    def add_query_options!(value)
      query_options.merge! value
    end
    
    def add_body_options!(value)
      body_options.merge! value
    end
    
    def add_request_options!(value)
      request_options.merge! value
    end
    
    def path_for(path)
      File.join(*['', endpoint, path].compact)
    end
    
    def extract_response(path, response, options)
      response_container = options[:response_container] || default_response_container(path, options)
      if response_container
        response_keys = Array(options[:response_container]).map(&:to_s)
        response = response_keys.inject(response) do |r, key|
          r.respond_to?(:[]) ? r[key] : r
        end
      end
      response
    end
    
    def transform_response(response, options)
      if (transformer = options[:transform])
        transformer.call response
      else
        response
      end
    end
    
    def endpoint
      nil
    end
    
    def default_response_container(path, options)
      nil
    end
    
  end
end
