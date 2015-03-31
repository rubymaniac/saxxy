require "spec_helper"
require "saxxy/utils/agent"


describe Saxxy::Agent do
  include AgentMacros

  it "should set a proxy when proxy settings are passed" do
    agent = Saxxy::Agent.new(url, proxy: { address: "my.proxy.com", port: 3128 })
    agent.proxy.should_not be_empty
  end

  it "#agent should return Net::HTTP if no proxy settings" do
    agent = Saxxy::Agent.new(url)
    agent.agent.should eql(Net::HTTP)
  end

  it "#agent should return a class that behaves like Net::HTTP if proxy settings are present" do
    agent = Saxxy::Agent.new(url, proxy: { address: "my.proxy.com", port: 3128 })
    agent.agent.should_not eql(Net::HTTP)
    agent.agent.proxy_class?.should be_true
    agent.agent.instance_methods.should eql(Net::HTTP.instance_methods)
  end

  it "#get should issue a GET request to the url provided in initialization without argument" do
    fake_get
    agent = Saxxy::Agent.new(url + "/get")
    agent.get.should eql("fake_get")
    FakeWeb.last_request.method.should eql("GET")
  end

  it "#get should replace the agent's url and uri instance variables when called with argument" do
    fake_get
    first_url   = url + "/anything"
    second_url  = url + "/get"
    agent       = Saxxy::Agent.new(first_url)
    agent.url.should eql(first_url)
    agent.uri.should eql(URI(first_url))
    agent.get(second_url)
    agent.url.should eql(second_url)
    agent.uri.should eql(URI(second_url))
  end

  it "#post should issue a POST request to the url provided in initialization without arguments" do
    fake_post
    agent = Saxxy::Agent.new(url + "/post")
    agent.post.should eql("fake_post")
    FakeWeb.last_request.method.should eql("POST")
  end

  it "#post should replace the agent's url and uri instance variables when called with arguments" do
    fake_post
    first_url   = url + "/anything"
    second_url  = url + "/post"
    agent       = Saxxy::Agent.new(first_url)
    agent.url.should eql(first_url)
    agent.uri.should eql(URI(first_url))
    agent.post(second_url)
    agent.url.should eql(second_url)
    agent.uri.should eql(URI(second_url))
  end

end