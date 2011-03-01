require 'httparty'

module APISmith
  # A mixin providing the base set of functionality for building API clients.
  #
  # @see InstanceMethods
  # @see ClassMethods
  # @see HTTParty
  #
  # @author Darcy Laycock
  # @author Steve Webb
  module Client

    # Hooks into the mixin process to add HTTParty and the two APISmith::Client
    # components to the given parent automatically.
    # @param [Class] parent the object this is being mixed into
    def self.included(parent)
      parent.class_eval do
        include HTTParty
        include InstanceMethods
        extend  ClassMethods
      end
    end

    # The most important part of the client functionality - namely, provides a set of tools
    # and methods that make it possible to build API clients. This is where the bulk of the
    # client work takes place.
    module InstanceMethods

      # Given a path relative to the endpoint (or `/`), will perform a GET request.
      #
      # If provided, will use a `:transformer` to convert the resultant data into
      # a useable object. Also, in the case an object is nested, allows you to
      # traverse an object.
      #
      # @param [String] path the relative path to the object, pre-normalisation
      # @param [Hash] options the raw options to be passed to ``#request!``
      # @see #request!
      def get(path, options = {})
        request! :get, path, options, :query
      end

      # Given a path relative to the endpoint (or `/`), will perform a POST request.
      #
      # If provided, will use a `:transformer` to convert the resultant data into
      # a useable object. Also, in the case an object is nested, allows you to
      # traverse an object.
      #
      # @param [String] path the relative path to the object, pre-normalisation
      # @param [Hash] options the raw options to be passed to ``#request!``
      # @see #request!
      def post(path, options = {})
        request! :post, path, options, :query, :body
      end

      # Given a path relative to the endpoint (or `/`), will perform a PUT request.
      #
      # If provided, will use a `:transformer` to convert the resultant data into
      # a useable object. Also, in the case an object is nested, allows you to
      # traverse an object.
      #
      # @param [String] path the relative path to the object, pre-normalisation
      # @param [Hash] options the raw options to be passed to ``#request!``
      # @see #request!
      def put(path, options = {})
        request! :put, path, options, :query, :body
      end

      # Given a path relative to the endpoint (or `/`), will perform a DELETE request.
      #
      # If provided, will use a `:transformer` to convert the resultant data into
      # a useable object. Also, in the case an object is nested, allows you to
      # traverse an object.
      #
      # @param [String] path the relative path to the object, pre-normalisation
      # @param [Hash] options the raw options to be passed to ``#request!``
      # @see #request!
      def delete(path, options = {})
        request! :delete, path, options, :query
      end

      # Performs a HTTP request using HTTParty, using a set of expanded options built up by the current client.
      #
      # @param [:get, :post, :put, :delete] method the http request method to use
      # @param [String] path the request path, relative to either the endpoint or /.
      # @param [Hash{Symbol => Object}] options the options for the given request.
      # @param [Array<Symbol>] param_types the given parameter types (e.g. :body, :query) to add to the request
      #
      # @option options [true,false] :skip_endpoint If true, don't expand the given path before processing.
      # @option options [Array] :response_container If present, it will traverse an array of objects to unpack
      # @option options [Hash] :extra_request Extra raw, request options to pass in to the request
      # @option options [Hash] :extra_body Any parameters to add to the request body
      # @option options [Hash] :extra_query Any parameters to add to the request query string
      # @option options [#call] :transform An object, invoked via #call, that takes the response and
      #   transformers it into a useable form.
      #
      # @see #path_for
      # @see #extract_response
      # @see #transform_response
      def request!(method, path, options, *param_types)
        # Merge in the default request options, e.g. those to be passed to HTTParty raw
        request_options = merged_options_for(:request, options)
        # Exapdn the path out into a full version when the endpoint is present.
        full_path = request_options[:skip_endpoint] ? path : path_for(path)
        # For each of the given param_types (e.g. :query, :body) will automatically
        # merge in the options for the current request.
        param_types.each do |type|
          request_options[type] = merged_options_for(type, options)
        end
        # Finally, use HTTParty to get the response
        response = self.class.send method, full_path, request_options
        parsed_response = response.parsed_response
        # Pre-process the response to check for errors.
        check_response_errors parsed_response
        # Unpack the response using the :response_container option
        inner_response = extract_response path, parsed_response, options
        # Finally, apply any transformations
        transform_response inner_response, options
      end

      private

      # Provides a hook to handle checking errors on API responses. This is called
      # post-fetch and pre-unpacking / transformation. It is passed the apis response
      # post-decoding (meaning JSON etc have been parsed into normal ruby objects).
      # @param [Object] response the raw decoded api response
      def check_response_errors(response)
      end

      # Merges in options of a given type into the base options, taking into account
      #
      # * Shared options (e.g. #base_query_options)
      # * Instance-level options (e.g. #query_options)
      # * Call-level options (e.g. the :extra_query option)
      #
      # @param [Symbol] type the type of options, one of :body, :query or :request
      # @param [Hash] options the hash to check for the `:extra_{type}` option.
      # @return [Hash] a hash of the merged options.
      def merged_options_for(type, options)
        base = send :"base_#{type}_options"
        base.merge!(send(:"#{type}_options") || {})
        base.merge! options.fetch(:"extra_#{type}", {})
        base
      end

      # The base set of body parameters, common to all instances of the client.
      # Ideally, in your client you'd override this to return other required
      # parameters that are the same across all client subclasses e.g. the format.
      #
      # These will automatically be included in POST and PUT requests but not
      # GET or DELETE requests.
      #
      # @example
      #   def base_body_options
      #     {:format => 'json'}
      #   end
      #
      def base_body_options
        {}
      end

      # The base set of query parameters, common to all instances of the client.
      # Ideally, in your client you'd override this to return other required
      # parameters that are the same across all client subclasses e.g. the format.
      #
      # These will automatically be included in all requests as part of the query
      # string.
      #
      # @example
      #   def base_query_options
      #     {:format => 'json'}
      #   end
      #
      def base_query_options
        {}
      end

      # The base set of request options as accepted by HTTParty. These can be used to
      # setup things like the normaliser HTTParty will use for parameters.
      def base_request_options
        {}
      end

      # Per-instance configurable query parameters.
      # @return [Hash] the instance-specific query parameters.
      # @see #add_query_options!
      def query_options
        @query_options ||= {}
      end

      # Per-instance configurable body parameters.
      # @return [Hash] the instance-specific body parameters.
      # @see #add_body_options!
      def body_options
        @body_options ||= {}
      end

      # Per-instance configurable request options.
      # @return [Hash] the instance-specific request options.
      # @see #add_request_options!
      def request_options
        @request_options ||= {}
      end

      # Merges in a hash of extra query parameters to the given request, applying
      # them for every request that has query string parameters. Typically
      # called from inside #initialize.
      # @param [Hash{Symbol => Object}] value a hash of options to add recently
      def add_query_options!(value)
        query_options.merge! value
      end

      # Merges in a hash of extra body parameters to the given request, applying
      # them for every request that has body parameters. Typically called from
      # inside #initialize.
      # @param [Hash{Symbol => Object}] value a hash of options to add recently
      def add_body_options!(value)
        body_options.merge! value
      end

      # Merges in a hash of request options to the given request, applying
      # them for every request that has query string parameters. Typically called
      # from inside #initialize.
      # @param [Hash{Symbol => Object}] value a hash of options to add recently
      def add_request_options!(value)
        request_options.merge! value
      end

      # Given a path, expands it relative to the / and the defined endpoint
      # for this class.
      # @param [String] path the current, unexpanded path for the api call.
      # @example With an endpoint of v1
      #   path_for('test') # => "/v1/test"
      def path_for(path)
        File.join(*['', endpoint, path].compact)
      end

      # Given a path, response and options, will walk the response object
      # (typically hashes and arrays) to unpack / extract the users response.
      #
      # Note that the response container will be found either via a :response_container
      # option or, if not specified at all, the result of #default_response_container to
      # 'get' the part of the response that the user cares about.
      #
      # @param [String] path the path used for the request#
      # @param [Hash, Array] response the object returned from the api call
      # @param [Hash] options the options passed to the api call
      # @option options [Array<Symbol, String, Integer>] :response_container the container to unpack
      #   from, e.g. ["a", 1, "b"], %w(a 2 3) or something else.
      def extract_response(path, response, options)
        # First, get the response container options
        response_container = options.fetch(:response_container, default_response_container(path, options))
        # And then unpack then
        if response_container
          response_keys = Array(options[:response_container])
          response = response_keys.inject(response) do |r, key|
            r.respond_to?(:[]) ? r[key] : r
          end
        end
        response
      end

      # Takes a response and, if present, uses the :transform option to convert
      # it into a useable object.
      # @param [Hash, Array] response the object returned from the api call
      # @param [Hash] options the options passed to the api call
      # @option options [#call] :transform If present, passed the unpack response.
      # @return [Object] the transformed response, or the response itself if no :transform
      #   option is passed.
      def transform_response(response, options)
        if (transformer = options[:transform])
          transformer.call response
        else
          response
        end
      end

      # Returns the current api endpoint, if present.
      # @return [nil, String] the current endpoint
      def endpoint
        nil
      end

      # A hook method to define the default response container for a given
      # path and set of options to an API call. Intended to be used inside
      # subclasses to make it possible to define a standardised way to unpack
      # responses without having to pass a `:response_container` option.
      # @param [String] path the current path to the request
      # @param [Hash] options the set of options passed to #request!
      # @return [nil, Array] the array of indices (either hash / array indices)
      #   to unpack the response via.
      def default_response_container(path, options)
        nil
      end

    end

    # Class level methods to let you configure your api client.
    module ClassMethods

      # When present, lets you specify the api for the given client.
      # @param [String, nil] value the endpoint to use.
      # @example Setting a string endpoint
      #   endpoint 'v1'
      # @example Unsetting the string endpoint
      #   endpoint nil
      def endpoint(value = nil)
        define_method(:endpoint) { value }
      end

    end

  end
end