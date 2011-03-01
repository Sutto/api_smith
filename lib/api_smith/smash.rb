require 'hashie/dash'

module APISmith
  # Extends Hashie::Dash to suppress unknown keys when passing data, but
  # is configurable to raises an UnknownKey exception when accessing keys in the
  # Smash.
  #
  # APISmith::Smash is a subclass of Hashie::Dash that adds several features
  # making it suitable for use in writing api clients. Namely,
  #
  # * The ability to silence exceptions on unknown keys (vs. Raising NoMethodError)
  # * The ability to define conversion of incoming data via transformers
  # * The ability to define aliases for keys via the from parameter.
  #
  # @author Darcy Laycock
  # @author Steve Webb
  #
  # @example a simple, structured object with the most common use cases.
  #   class MyResponse < APISmith::Smash
  #     property :full_name, :from => :fullName
  #     property :value_percentage, :transformer => :to_f
  #     property :short_name
  #     property :created, :transformer => lambda { |v| Date.parse(v) }
  #   end
  #
  #   response = MyResponse.new({
  #     :fullName         => "Bob Smith",
  #     :value_percentage => "10.5",
  #     :short_name       => 'Bob',
  #     :created          => '2010-12-28'
  #   })
  #
  #   p response.short_name # => "Bob"
  #   p response.full_name # => "Bob Smith"
  #   p response.value_percentage # => 10.5
  #   p response.created.class # => Date
  class Smash < Hashie::Dash
    # When we access an unknown property, we raise the unknown key instead of
    # a NoMethodError on undefined keys so that we can do a target rescue.
    class UnknownKey < StandardError; end

    # Returns a class-specific hash of transformers, containing the attribute
    # name mapped to the transformer that responds to call.
    # @return The hash of transformers.
    def self.transformers
      (@transformers ||= {})
    end

    # Returns a class-specific hash of incoming keys and their resultant
    # property name, useful for mapping non-standard names (e.g. displayName)
    # to their more ruby-like equivelant (e.g. display_name).
    # @return The hash of key mappings.
    def self.key_mapping
      (@key_mapping ||= {})
    end

    # Test if the object should raise a NoMethodError exception on unknown
    # property accessors or whether it should be silenced.
    #
    # @return true if an exception will be raised when accessing an unknown key
    #   else, false.
    def self.exception_on_unknown_key?
      defined?(@exception_on_unknown_key) && @exception_on_unknown_key
    end

    # Sets whether or not Smash should raise NoMethodError on an unknown key.
    # Sets it for the current class.
    #
    # @param [Boolean] value true to throw exceptions.
    def self.exception_on_unknown_key=(value)
      @exception_on_unknown_key = value
    end

    # Sets the transformer that is invoked when the given key is set.
    #
    # @param [Symbol] key The key should this transformer operate on
    # @param [#call] value If a block isn't given, used to transform via #call.
    # @param [Block] blk The block used to transform the key.
    def self.transformer_for(key, value = nil, &blk)
      if blk.nil? && value
        blk = value.respond_to?(:call) ? value : value.to_sym.to_proc
      end
      raise ArgumentError, 'must provide a transformation' if blk.nil?
      transformers[key.to_s] = blk
      # For each subclass, set the transformer.
      Array(@subclasses).each { |klass| klass.transformer_for(key, value) }
    end

    # Hook to make it inherit instance variables correctly. Called once
    # the Smash is inherited from in another object to maintain state.
    def self.inherited(klass)
      super
      klass.instance_variable_set '@transformers',             transformers.dup
      klass.instance_variable_set '@key_mapping',              key_mapping.dup
      klass.instance_variable_set '@exception_on_unknown_key', exception_on_unknown_key?
    end

    # Create a new property (i.e., hash key) for this Object type. This method
    # allows for converting property names and defining custom transformers for
    # more complex types.
    #
    # @param [Symbol] property_name The property name (duh).
    # @param [Hash] options
    # @option options [String, Array<String>] :from Also accept values for this property when
    #   using the key(s) specified in from.
    # @option options [Block] :transformer Specify a class or block to use when transforming the data.
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

    # Does this Smash class contain a specific property (key),
    # or does it have a key mapping (via :from)
    #
    # @param [Symbol] key the property to test for.
    # @return [Boolean] true if this class contains the key; else, false.
    def self.property?(key)
      super || key_mapping.has_key?(key.to_s)
    end

    # Automates type conversion (including on Array and Hashes) to this type.
    # Used so we can pass this class similarily to how we pass lambdas as an
    # object, primarily for use as transformers.
    #
    # @param [Object] the object to attempt to convert.
    # @return [Array<Smash>, Smash] The converted object / array of objects if
    #   possible, otherwise nil.
    def self.call(value)
      if value.is_a?(Array)
        value.map { |v| call v }.compact
      elsif value.is_a?(Hash)
        new value
      else
        nil
      end
    end

    # Access the value responding to a key, normalising the key into a form
    # we know (e.g. processing the from value to convert it to the actual
    # property name).
    #
    # @param [Symbol] property the key to check for.
    # @return The value corresponding to property. nil if it does not exist.
    def [](property)
      super transform_key(property)
    rescue UnknownKey
      nil
    end

    # Sets the value for a given key. Transforms the key first (e.g. taking into
    # account from values) and transforms the property using any transformers.
    #
    # @param [Symbol] property the key to set.
    # @param [String] value the value to set.
    # @return If the property exists value is returned; else, nil.
    def []=(property, value)
      key = transform_key(property)
      super key, transform_property(key, value)
    rescue UnknownKey
      nil
    end

    private

    # Overrides the Dashie check to raise a custom exception that we can
    # rescue from when the key is unknown.
    def assert_property_exists!(property)
      has_property = self.class.property?(property)
      unless has_property
        exception = self.class.exception_on_unknown_key? ? NoMethodError : UnknownKey
        raise exception, "The property '#{property}' is not defined on this #{self.class.name}"
      end
    end

    # Transforms a given key into it's normalised alternative, making it
    # suitable for automatically mapping external objects into a useable
    # local version.
    # @param [Symbol, String] key the starting key, pre-transformation
    # @return [String] the transformed key, ready for use internally.
    def transform_key(key)
      self.class.key_mapping[key.to_s] || default_key_transformation(key)
    end

    # By default, we transform the key using #to_s, making it useable
    # as a hash index. If you want to, for example, add leading underscores,
    # you're do so here.
    def default_key_transformation(key)
      key.to_s
    end

    # Given a key and a value, applies any incoming data transformations as appropriate.
    # @param [String, Symbol] key the property key
    # @param [Object] value the incoming value of the given property
    # @return [Object] the transformed value for the given key
    # @see Smash.transformer_for
    def transform_property(key, value)
      transformation = self.class.transformers[key.to_s]
      transformation ? transformation.call(value) : value
    end

  end
end
