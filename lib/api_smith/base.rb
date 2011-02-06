require 'api_smith/client'
module APISmith
  # A base class for building api clients (with a specified endpoint and general
  # shared options) on top of HTTParty, including response unpacking and transformation.
  #
  # Used to convert APISmith::Client to a general inheritence pattern (versus as a mixin).
  #
  # @author Darcy Laycock
  # @author Steve Webb
  class Base
    include APISmith::Client
  end
end
