require 'spec_helper'

describe APISmith::Base do

  it 'should be a class' do
    APISmith::Base.should be_a(Class)
  end

  it 'should mixin the client' do
    APISmith::Base.should be < APISmith::Client
  end

  it 'should mixin httparty' do
    APISmith::Base.should be < HTTParty
  end

  it 'should work in classes with arguments on their initializer' do
    klass = Class.new(APISmith::Base) do
      def initialize(options = {})
        super
      end
    end
    expect { klass.new }.to_not raise_error(ArgumentError)
  end

end
