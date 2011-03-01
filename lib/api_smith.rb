# Provides a simple set of tools built on top of Hashie and HTTParty to make
# it easier to build clients for different apis.

# @see APISmith::Smash
# @see APISmith::Base
#
# @author Darcy Laycock
# @author Steve Webb
module APISmith
  VERSION = "0.0.1".freeze

  require 'api_smith/smash'
  require 'api_smith/client'
  require 'api_smith/base'

end
