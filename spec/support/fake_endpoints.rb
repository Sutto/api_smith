class TestApplication < Sinatra::Application

  def json!(response)
    content_type "application/json"
    JSON.dump response
  end

  get '/simple' do
    json! name: "Darcy"
  end

  get '/nested' do
    json! response: {
      name: "Steve"
    }
  end

  get '/collection' do
    json! response: [
      {name: "Bob"},
      {name: "Reginald"}
    ]
  end

  get '/a' do
    json! a: "outer"
  end

  get '/namespaced/a' do
    json! a: "namespaced"
  end

  get '/namespaced/test' do
    json! response: {age: 20, name: "Roger"}
  end

  get '/namespaced/complex' do
    json! response: {
      data: [{
        inner: {name: 'Charles', secret_identity: true}
      }]
    }
  end

  %w(get post put delete).each do |verb|
    send(verb, '/echo') do
      json! verb: verb, echo: params[:echo]
    end
  end

  get '/erroring' do
    json! error_name: 'Totally confused.'
  end

end

Faraday.default_adapter = [:rack, TestApplication.new]