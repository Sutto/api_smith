module APISmith
  module WebMockExtensions
    
    def subject_api_class
      subject.is_a?(Class) ? subject : subject.class
    end
    
    def subject_class_instance
      @subject_class_instance ||= subject_api_class.allocate
    end
    
    def api_url_for(path)
      path     = subject_class_instance.send(:path_for, path)
      base_uri = subject_api_class.base_uri
      File.join base_uri, path
    end
    
    def stub_api(type, path)
      stub_request(type, api_url_for(path))
    end
    
  end
end