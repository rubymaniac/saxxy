require "net/http"
require "uri"


module Saxxy

  # The Agent is a thin wrapper over Net::HTTP::Proxy in order to be used
  # for crawling purposes. Supports GET and POST via its get and post methods.
  class Agent
    attr_reader :url, :uri, :proxy, :agent, :response

    # Initializes an agent with optional proxy options.
    # Url: A string that it is the url that the agent is going to use for issuing
    #      requests. It can be reset to another via the self.uri = method.
    # Options:
    # - proxy:
    #   - address: The address of the proxy.
    #   - port: The port the proxy will use.
    #   - username: The username if the proxy needs auth.
    #   - password: The password if the proxy needs auth.
    def initialize(url, opts = {})
      @proxy = opts[:proxy] || {}
      @agent = proxy.empty? ? Net::HTTP : Net::HTTP::Proxy(proxy[:address], proxy[:port], proxy[:username], proxy[:password])
      self.uri = url
    end

    # Sets the url and uri by inspecting the argument. Can accept either a string
    # which must be a valid URL or a URI object.
    def uri=(url_or_uri)
      @uri = url_or_uri.is_a?(URI) ? url_or_uri : URI(url_or_uri)
      @url = uri.to_s
    end

    # Issues a get request either by using the url provided as an argument or
    # the one the agent currently holds.
    # Note: if the provided url is different from the agent's it updates the
    #       agent's url also. See set_uri_for.
    def get(url = nil)
      issue_request(url, :get_response)
    end

    # Issues a post request either by using the url provided as an argument or
    # the one the agent currently holds. Uses the post_form method of the
    # Net::HTTP::Proxy and forwards any passed options to the underlying agent.
    # Note: if the provided url is different from the agent's it updates the
    #       agent's url also. See set_uri_for.
    def post(url = nil, opts = {})
      issue_request(url, :post_form, opts)
    end

    private
    def set_uri_for(url = nil)
      self.uri = url if url
    end

    def issue_request(*args)
      new_url_or_uri = args.shift
      if new_url_or_uri.to_s != url
        set_uri_for(new_url_or_uri)
        @response = agent.public_send(args.shift, uri, *args)
      end
      response.body
    end
  end

end
