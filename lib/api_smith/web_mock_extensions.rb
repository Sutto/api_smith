module APISmith
  # A set of extensions to make using APISmith with WebMock (or most test utilities in general)
  # simpler when it comes checking values. Please note this is primarily intended for use with
  # rspec due to dependence on subject in some places.
  #
  # @author Darcy Laycock
  # @author Steve Webb
  module WebMockExtensions

    # Returns the class of the current subject
    # @return [Class] the subject class
    def subject_api_class
      subject.is_a?(Class) ? subject : subject.class
    end

    # Returns an instance of the subject class, created via allocate (vs. new). Useful
    # for giving access to utility methods used inside of the class without having to\
    # initialize a new client.
    # @return [Object] the instance
    def subject_class_instance
      @subject_class_instance ||= subject_api_class.allocate
    end

    # Expands the given path relative to the API for the current subject class.
    # Namely, this makes it possible to convert a relative path to an endpoint-specified
    # path.
    # @param [String] path the path to expand, minus endpoint etc.
    # @return [String] the expanded path
    def api_url_for(path)
      path     = subject_class_instance.send(:path_for, path)
      base_uri = subject_api_class.base_uri
      File.join base_uri, path
    end

    # Short hand for #stub_request that lets you give it a relative path prior to expanding it.
    # @param [:get, :post, :put, :delete] the verb for the request
    # @param [String] the relative path for the api
    # @return [Object] the result from stub_request
    def stub_api(type, path)
      stub_request type, api_url_for(path)
    end

  end
end