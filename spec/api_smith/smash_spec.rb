require 'spec_helper'

describe APISmith::Smash do

  let(:my_smash) { Class.new(APISmith::Smash) }

  describe 'transformers' do

    it 'should let you define a transformer via transformer_for' do
      my_smash.property :name
      my_smash.transformers['name'].should be_nil
      my_smash.transformer_for :name, lambda { |v| v.to_s.upcase }
      my_smash.transformers['name'].should_not be_nil
      my_smash.transformers['name'].call('a').should == 'A'
    end

    it 'should let you pass a block to transformer_for' do
      my_smash.property :name
      my_smash.transformers['name'].should be_nil
      my_smash.transformer_for(:name) { |v| v.to_s.upcase }
      my_smash.transformers['name'].should_not be_nil
      my_smash.transformers['name'].call('a').should == 'A'
    end

    it 'should accept a symbol for transformer' do
      my_smash.property :name
      my_smash.transformers['name'].should be_nil
      my_smash.transformer_for :name, :to_i
      my_smash.transformers['name'].should_not be_nil
      my_smash.transformers['name'].call('1').should == 1
    end

    it 'should let you define a transformer via the :transformer property option' do
      my_smash.transformers['name'].should be_nil
      my_smash.property :name, :transformer => lambda { |v| v.to_s.upcase }
      my_smash.transformers['name'].should_not be_nil
      my_smash.transformers['name'].call('a').should == 'A'
    end

    it 'should automatically transform the incoming value' do
      my_smash.property :count, :transformer => lambda { |v| v.to_i }
      instance = my_smash.new
      instance.count = '1'
      instance.count.should == 1
    end

  end

  describe 'key transformations' do

    it 'should let you specify it via from' do
      my_smash.property :name, :from => :fullName
      my_smash.key_mapping['fullName'].should == 'name'
      my_smash.new(:fullName => 'Bob').name.should == 'Bob'
    end

    it 'should alias it for reading' do
      my_smash.property :name, :from => :fullName
      my_smash.new(:name => 'Bob')[:fullName].should == 'Bob'
    end

    it 'should alias it for writing' do
      my_smash.property :name, :from => :fullName
      instance = my_smash.new
      instance[:fullName] = 'Bob'
      instance.name.should == 'Bob'
    end

  end

  describe 'inheritance' do

    let(:parent_smash) { Class.new(APISmith::Smash) }
    let(:client_smash) { Class.new(parent_smash) }

    it 'should not overwrite parent class transformers' do
      parent_smash.transformers['a'].should be_nil
      client_smash.transformers['a'].should be_nil
      client_smash.transformer_for :a, :to_s
      parent_smash.transformers['a'].should be_nil
      client_smash.transformers['a'].should_not be_nil
    end

    it 'should not overwrite parent class key mapping' do
      parent_smash.key_mapping['b'].should be_nil
      client_smash.key_mapping['b'].should be_nil
      client_smash.property :a, :from => :b
      parent_smash.key_mapping['b'].should be_nil
      client_smash.key_mapping['b'].should_not be_nil
    end

    it 'should not overwrite the parent classes unknown key error' do
      parent_smash.exception_on_unknown_key?.should be_false
      client_smash.exception_on_unknown_key?.should be_false
      client_smash.exception_on_unknown_key = true
      parent_smash.exception_on_unknown_key?.should be_false
      client_smash.exception_on_unknown_key?.should be_true
    end

  end

  describe 'overriding the default key transformations' do

    it 'should let you override the default transformation method' do
      my_smash.property :name
      my_smash.class_eval do
        def default_key_transformation(key)
          key.to_s.downcase.gsub(/\d/, '')
        end
      end
      smash = my_smash.new
      smash[:NAME1] = 'Bob Smith'
      smash.name.should == 'Bob Smith'
    end

    it 'should default to transforming via to_s' do
      smash = my_smash.new
      smash.send(:default_key_transformation, :another).should == 'another'
    end

  end

  describe 'extending Hashie::Dash' do

    it 'should let you swallow errors on unknown keys' do
      my_smash.properties.should_not include(:name)
      my_smash.exception_on_unknown_key?.should be_false
      expect do
        my_smash.new(:name => 'Test')
      end.should_not raise_error
      my_smash.exception_on_unknown_key?.should be_false
    end

    it 'should raise an exception correctly when not ignoring unknown keys' do
      my_smash.properties.should_not include(:name)
      my_smash.exception_on_unknown_key = true
      my_smash.exception_on_unknown_key?.should be_true
      expect do
        my_smash.new(:name => 'Test')
      end.should raise_error(NoMethodError)
      my_smash.exception_on_unknown_key?.should be_true
    end

    it 'should default to ignoring unknown key errors' do
      klass = Class.new(APISmith::Smash)
      klass.exception_on_unknown_key?.should be_false
    end

    it 'should include aliases in :from when checking if properties are valid' do
      my_smash.should_not be_property(:name)
      my_smash.should_not be_property(:fullName)
      my_smash.property :name, :from => :fullName
      my_smash.should be_property(:name)
      my_smash.should be_property(:fullName)
    end

  end

  describe 'being a callable object' do

    before :each do
      my_smash.property :name
      my_smash.property :age, :transformer => :to_i
    end

    it 'should respond to call' do
      my_smash.should respond_to(:call)
    end

    it 'should correctly transform a hash' do
      instance = my_smash.call(:name => 'Bob', :age => '18')
      instance.should be_a(my_smash)
      instance.name.should == 'Bob'
      instance.age.should == 18
    end

    it 'should correctly transform an array' do
      instance = my_smash.call([{:name => 'Bob', :age => '18'}, {:name => 'Rick', :age => '19'}])
      instance.should be_a(Array)
      instance.first.should be_a(my_smash)
      instance.first.name.should == 'Bob'
      instance.first.age.should == 18
      instance.last.should be_a(my_smash)
      instance.last.name.should == 'Rick'
      instance.last.age.should == 19
    end

  end

end
