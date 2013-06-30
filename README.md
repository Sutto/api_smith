# API Smith

API Smith makes building clients for HTTP-based APIs easy.

By building on top of HTTParty and Hashie, API Smith provides tools tailor-made for making API
clients for structured data - That is, responses with a well defined design. These tools are
made possible by two parts - APISmith::Smash, a smarter dash / hash-like object which lets
you have simple declarative data structures and APISmith::Client, a layer on top of HTTParty
that makes dealing with APIs even simpler and more consistent.

## APISmith::Smash - A Smarter Hash

API Smith's Smash class is a 'smarter' (or, alternatively, structured) hash. Built on top of
`Hashie::Dash`, `APISmith::Smash` adds several features that make it useful for making objects
that represent an external api response. On top of [the base Hashie::Dash feature set](https://github.com/intridea/hashie/blob/master/lib/hashie/dash.rb),
APISmith::Smash adds:

### Configuration of alternative names for fields

A feature useful for dealing with apis where they may have a `fullName` field in their api response
but you want to use `full_name`. Configurable by a simple  `:from` option on property declarations.

This importantly lets you deal with one format internally whilst automatically taking care of normalising
external data sources. More importantly, it also provides simple methods you can override to handle
a wide range of external schemes (e.g. always underscoring the field name).

### Configurable transformers

Essentially, any object (e.g. a lambda, a class or something else) that responds to `#call` can be used
to transform incoming data into a useable format. More importantly, your smash classes will also respond
to `#call` meaning they can intelligently be used as transformers for other classes, making complex / nested
objects simple and declarative.

On top of this, APISmith::Client also uses the same `#call`-able convention, making it even easier to
use a consistent scheme for converting data across the application.

Using it on a property is as simple as passing a `:transformer` option with the `#call`-able object
as the value.

### A well defined (and documented) api

Making it possible for you to hook in at multiple stages to further specialise your Smash objects for
specific API use cases.

## APISmith::Client - Making API Clients Sexy

APISmith::Client is a collection of tools built on top of [HTTParty](https://github.com/jnunemaker/httparty) that
adds tools to make writing API clients simpler. Namely, it adds:

### Configurable Endpoints

Put simply, even though HTTParty adds the `base_uri` class option, there are times where
we want to be able to create a class of base logic but still vary a common part of the URI. For
this, APISmith::Client supports endpoints. Essentially, a path part that is prefixed to all
paths passed to `get`, `post`, `put` and `delete`.

Using this in your client is as simple as calling the `endpoint` class method - e.g.:


    class MyAPIClient
      include APISmith::Client
      base_uri "http://example.com/"
      endpoint "api/v1"
    end
    
Then, calling `MyAPIClient.new.get('/blah')` will hit up the url at `http://example.com/api/v1/blah`.

This is most importantly useful when dealing with restful - `base_uri` can point to the site root and
then you can subclass your base client class and set the endpoint for each resource. More importantly,
because you can override `APISmith::Client::InstanceMethods#endpoint` method, you can also make
your endpoint take into account parent resource ids and the like.

### Hierarchal Request, Body and Query String options

Out of the box, we give you support for configuring options on three levels:

* The class - e.g. parameters to set the response type to JSON
* The instance - e.g. an api key parameter that all instances require
* The request - e.g. a parameter required for that specific API call.

Out of the box, it transparently supports using these options for both the request
body, the request query string and the request options in general (for HTTParty).

For each of these types (`query`, `body` and `request`), it's easy to hook in to them
and to set them. For class-level options, simply define a `base_#{type}_options` method,
e.g:

    def base_query_options
      {:format => 'json'}
    end

For per-instance options, simply use the `add_#{type}_options!` method (which takes
a hash of options). For example, see `APISmith::Client::InstanceMethods#add_query_options!`.

Finally, you can use the `:extra_#{type}` options (e.g. `:extra_query`), for example:

    get '/', :extra_query => {:before_timestamp => 2.weeks.ago.to_s}
    
### Response Unpacking

Via the `:response_container` argument to the `get`, `post`, `put` and `delete` methods, API Smith
supports automatically taking the parsed responses and getting just the bit you care about.

In cases where the API consistently packages the data in a simple manner, it's also possible to
override the default response container, making it somewhat simple to automate the whole unpacking
process. As an example, say your api returns:

    {
      "data": {
        "values": "some-other-data-here"
      }
    }
    
Via the `:response_container` option, when your transformer is called, it wont have to deal with the data and values keys,
You will only need to deal with the contents directly, in this case - `"some-other-data-here"`, simply by passing:

    :response_container => %w(data values)

### Simple Response Transformations

The most important aspect of APISmith::Client comes down to it's support of the `:transform` option. Much like
the `:transformer` option on Smash properties, Adding `:transform` with a `#call`-able object to your call to
`get`, `post`, `put` or `delete` will automatically invoke your transformer with the unpacked response.

As an added bonus, because APISmith::Smash defines a `call` class method, you can then simply pass one
of your Smash subclasses to the transform option and API Smith will intelligently unpack your data into the
objects you care about.
  
## Contributors

API Smith was written by [Darcy Laycock](https://github.com/sutto), and [Steve Webb](https://github.com/swebb)
from [The Frontier Group](https://github.com/thefrontiergroup), as part of a bigger project with [Filter Squad](https://github.com/filtersquad).

* Thanks to [Pranas Kiziela](https://github.com/Pranas) for misc. compatibility related contributions.
* Thanks to [Calinoiu Alexandru Nicolae](https://github.com/balauru) for ensuring it's updated to Hashie 2.0 compatibility.

## Contributing

We encourage all community contributions. Keeping this in mind, please follow these general guidelines when contributing:

* Fork the project
* Create a topic branch for what you’re working on (git checkout -b awesome_feature)
* Commit away, push that up (git push your\_remote awesome\_feature)
* Create a new GitHub Issue with the commit, asking for review. Alternatively, send a pull request with details of what you added.
* Once it’s accepted, if you want access to the core repository feel free to ask! Otherwise, you can continue to hack away in your own fork.

Other than that, our guidelines very closely match the GemCutter guidelines [here](http://wiki.github.com/qrush/gemcutter/contribution-guidelines).

(Thanks to [GemCutter](http://wiki.github.com/qrush/gemcutter/) for the contribution guide)

## License

API Smith is released under the MIT License (see the [license file](LICENSE)) and is
copyright Filter Squad, 2011.
