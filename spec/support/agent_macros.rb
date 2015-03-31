require "fakeweb"


module AgentMacros

  def url
    "http://foo.com"
  end

  def fake_get(&block)
    FakeWeb.register_uri(:get, url + "/get",
      body: block_given? ? block.call : "fake_get",
      status:   ["200", "OK"]
    )
  end

  def fake_post(&block)
    FakeWeb.register_uri(:post, url + "/post",
      body: block_given? ? block.call : "fake_post",
      status:   ["201", "Created"]
    )
  end

end