require 'rubygems'
require 'hashie/dash'

module APISmith
  class Smash < Hashie::Dash
    class UnknownKey < StandardError; end
    # TODO: Some way to silence property changes.
    
    def self.transformers
      (@transformers ||= {})
    end
    
    def self.key_mapping
      (@key_mapping ||= {})
    end
    
    def self.exception_on_unknown_key?
      defined?(@exception_on_unknown_key) && @exception_on_unknown_key
    end
    
    def self.exception_on_unknown_key=(value)
      @exception_on_unknown_key = value
    end
    
    def self.transformer_for(key, value = nil, &blk)
      if blk.nil? && value
        blk = value.respond_to?(:call) ? value : value.to_sym.to_proc
      end
      raise ArgumentError, 'must provide a transformation' if blk.nil?
      transformers[key.to_s] = blk
      # For each subclass, set the transformer.
      Array(@subclasses).each { |klass| klass.transformer_for(key, value) }
    end
    
    def self.inherited(klass)
      super
      klass.instance_variable_set '@transformers',             transformers.dup
      klass.instance_variable_set '@key_mapping',              key_mapping.dup
      klass.instance_variable_set '@exception_on_unknown_key', exception_on_unknown_key?
    end
    
    def self.property(property_name, options = {})
      super
      if options[:from]
        property_name = property_name.to_s
        Array(options[:from]).each do |k|
          key_mapping[k.to_s] = property_name
        end
      end
      if options[:transformer]
        transformer_for property_name, options[:transformer]
      end
    end
    
    def self.property?(key)
      super || key_mapping.has_key?(key.to_s)
    end
    
    def self.call(value)
      if value.is_a?(Array)
        value.map { |v| call v }.compact
      elsif value.is_a?(Hash)
        self.new value
      else
        nil
      end
    end
    
    def [](property)
      super transform_key(property)
    rescue UnknownKey
      nil
    end
    
    def []=(property, value)
      key = transform_key(property)
      super key, transform_property(key, value)
    rescue UnknownKey
      nil
    end
    
    protected
    
    def assert_property_exists!(property)
      has_property = self.class.property?(property)
      unless has_property
        exception = self.class.exception_on_unknown_key? ? NoMethodError : UnknownKey
        raise exception, "The property '#{property}' is not defined on this #{self.class.name}"
      end
    end
    
    def transform_key(key)
      self.class.key_mapping[key.to_s] || default_key_transformation(key)
    end
    
    def default_key_transformation(key)
      key.to_s
    end
    
    def transform_property(key, value)
      transformation = self.class.transformers[key.to_s]
      transformation ? transformation.call(value) : value
    end
    
  end
end