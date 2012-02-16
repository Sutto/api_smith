require 'spec_helper'

describe APISmith::Client do

  let(:client_klass) do
    Class.new do
      include APISmith::Client
      base_uri "http://sham.local"
      persistent
    end
  end

  let(:client) { client_klass.new }

  it 'should let you provide instrumentation' do
    second_klass = Class.new(client_klass) do
      attr_accessor :hits
      def instrument_request(*args)
        (self.hits ||= []) << args
        yield if block_given?
      end
    end
    client = second_klass.new
    client.get('/echo')
    hits = client.hits
    hits.should_not be_nil
    hits.should_not be_empty
    hit = hits.first
    hit[0].should == :get
    hit[1].should include "/echo"
  end

  it 'should allow you to perform get requests' do
    client.get('/echo').should == {"verb" => "get", "echo" => nil}
  end

  it 'should allow you to perform post requests' do
    client.post('/echo').should == {"verb" => "post", "echo" => nil}
  end

  it 'should allow you to perform put requests' do
    client.put('/echo').should == {"verb" => "put", "echo" => nil}
  end

  it 'should allow you to perform delete requests' do
    client.delete('/echo').should == {"verb" => "delete", "echo" => nil}
  end

  it 'should default to returning a httparty response' do
    response = client.get('/echo')
    response.class.should == HTTParty::Response
  end

  describe 'passing options' do

    it 'should allow you to pass extra query string options' do
      response = client.get('/echo', :extra_query => {:echo => "Hello"})
      response["echo"].should == "Hello"
    end

    it 'should work with ampersands as expected' do
      response = client.get('/echo', :extra_query => {:echo => "a & b"})
      response["echo"].should == "a & b"
    end

    it 'should allow you to pass extra body options' do
      response = client.post('/echo', :extra_body => {:echo => "Hello"})
      response["echo"].should == "Hello"
    end

    it 'should allow you to pass extra request options' do
      mock.proxy(client_klass).get('/a', hash_including(:awesome => true))
      client.get '/a', :extra_request => {:awesome => true}
    end

    it 'should let you add query options on an instance level' do
      client.send :add_query_options!, :echo => "Hello"
      client.get('/echo')["echo"].should == "Hello"
    end

    it 'should let you add body options on an instance level' do
      client.send :add_body_options!, :echo => "Hello"
      client.post('/echo')["echo"].should == "Hello"
    end

    it 'should let you add request options on an instance level' do
      mock.proxy(client_klass).get('/a', hash_including(:awesome => true))
      client.send :add_request_options!, :awesome => true
      client.get('/a')
    end

    it 'should let you override the base level body options' do
      mock(client).base_body_options { {:echo => "Hello"} }
      client.post('/echo')["echo"].should == "Hello"
    end

    it 'should let you override the base level query string options' do
      mock(client).base_query_options { {:echo => "Hello"} }
      client.get('/echo')["echo"].should == "Hello"
    end

    it 'should let you override the base level request options' do
      mock.proxy(client_klass).get('/a', hash_including(:awesome => true))
      mock(client).base_request_options { {:awesome => true} }
      client.get('/a')
    end

  end

  describe 'unpacking requests' do

    it 'should let you specify a response container' do
      client.get('/nested', :response_container => %w(response)).should == {
        "name" => "Steve"
      }
    end

    it 'should handle indices correctly' do
      client.get('/namespaced/complex', :response_container => ["response", "data", 0, "inner"]).should == {
        "name"            => "Charles",
        "secret_identity" => true
      }
    end

    it 'should let you override the default response container' do
      mock(client).default_response_container('/namespaced/test', anything) { %w(response age) }
      client.get('/namespaced/test').should == 20
    end

    it 'should let you always skip the response container' do
      dont_allow(client).default_response_container.with_any_args
      client.get('/namespaced/test', :response_container => nil).should == {
        "response" => {
          "age"  => 20,
          "name" => "Roger"
        }
      }
    end

  end

  describe 'transforming requests' do

    let(:my_smash) do
      Class.new(APISmith::Smash).tap do |t|
        t.property :name
      end
    end

    it 'should let you pass a transformer' do
      response = client.get('/simple', :transform => lambda { |v| v["name"].upcase })
      response.should == "DARCY"
    end

    it 'should use .call on the transformer' do
      transformer = Object.new
      mock(transformer).call({"name" => "Darcy"}) { 42 }
      response = client.get('/simple', :transform => transformer)
      response.should == 42
    end

    it 'should transform the unpacked data' do
      transformer = lambda { |v| v.to_s.downcase.reverse }
      response = client.get('simple', :response_container => 'name', :transform => transformer)
      response.should == 'ycrad'
    end

    it 'should work with smash transformers for single objects' do
      response = client.get('/nested', :transform => my_smash, :response_container => %w(response))
      response.should be_kind_of my_smash
      response.name.should == 'Steve'
    end

    it 'should work with smash transformers for collections' do
      response = client.get('/collection', :transform => my_smash, :response_container => %w(response))
      response.should be_kind_of Array
      response.should be_all { |item| item.kind_of?(my_smash) }
      response.map(&:name).should == ["Bob", "Reginald"]
    end

    it 'should work with the transformer option as well' do
      response = client.get('/simple', :transformer => lambda { |v| v["name"].upcase })
      response.should == "DARCY"
    end

  end

  describe 'checking for errors' do

    it 'should invoke the errors hook' do
      mock(client).check_response_errors(anything)
      client.get('/simple')
    end

    it 'should do it before unpack the response' do
      mock(client).check_response_errors("response" => {"name" => "Steve"})
      client.get('/nested', :response_container => %w(response))
    end

    it 'should let you prevent unpacking / transformation from happening' do
      transformer = Object.new
      dont_allow(transformer).call.with_any_args
      mock(client).check_response_errors(anything) { raise StandardError }
      expect do
        client.get('/simple', :transform => transformer)
      end.to raise_error(StandardError)
    end

  end

  describe 'endpoints' do

    it 'should act correctly without an endpoint' do
      client.send(:endpoint).should be_nil
      client.send(:path_for, 'test').should == "/test"
      client.get('a')["a"].should == "outer"
    end

    it 'should let you set an endpoint at the class level' do
      client_klass.endpoint 'namespaced'
      client.send(:endpoint).should == 'namespaced'
      client.send(:path_for, 'test').should == "/namespaced/test"
      client.get('a')["a"].should == "namespaced"
    end

    it 'should let you override it on an instance level' do
      mock(client).endpoint { 'test/nested' }
      client.send(:path_for, 'test2').should == "/test/nested/test2"
    end

    it 'should let you skip the endpoint' do
      client_klass.endpoint 'namespaced'
      client.get('/a', :extra_request => {:skip_endpoint => true})["a"].should == "outer"
    end

  end

end
