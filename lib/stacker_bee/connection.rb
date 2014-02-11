require "faraday"
require "uri"
require "stacker_bee/middleware/signed_query"
require "stacker_bee/middleware/detokenizer"

module StackerBee
  class ConnectionError < StandardError
  end

  class Connection
    attr_accessor :configuration

    def initialize(configuration)
      @configuration = configuration
      uri = URI.parse(self.configuration.url)
      uri.path = ''
      fail ConnectionError, "no protocol specified" unless uri.scheme
      initialize_faraday(uri)
    end

    def initialize_faraday(uri)
      @faraday = Faraday.new(url: uri.to_s) do |faraday|
        faraday.use      Middleware::Detokenizer
        faraday.use      Middleware::SignedQuery, configuration.secret_key
        configuration.middlewares.call faraday
        faraday.adapter  Faraday.default_adapter  # Net::HTTP
      end
    end

    def get(request, path)
      @faraday.get(path, request.query_params)
    rescue Faraday::Error::ConnectionFailed => error
      raise ConnectionError,
        "Failed to connect to #{configuration.url}, #{error}"
    end
  end
end
