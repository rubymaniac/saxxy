# `Saxxy` A Ruby DSL for SAX parsers [![Build Status](https://travis-ci.org/rubymaniac/saxxy.png?branch=master)](https://travis-ci.org/rubymaniac/saxxy)

Saxxy is designed to be a DSL for creating SAX parsers. If anyone tells you that you are masochist 'cause you are SAX parsing HTML show her `Saxxy`.

It currently supports [Nokogiri](https://github.com/sparklemotion/nokogiri), [Ox](https://github.com/ohler55/ox), [LibXML](https://github.com/xml4r/libxml-ruby) and is really easy to implement your own parser bindings. It can parse XML out of the box but HTML SAX parsing heavily depends on how the parser handles HTML. Libxml cannot handle malformed HTML at all. Ox and Nokogiri handles the parsing of HTML (even malformed) really well and thus I recommend them.


## Dependencies

`Saxxy` requires Ruby >=1.9 or JRuby with JRUBY_OPTS=--1.9


## Installation

Add this line to your application's Gemfile:

    gem 'saxxy'

Or install it independently of Bundler

    $ gem install saxxy


## Getting started

### Overview
First you must create a service object with a specified parser. It accepts a symbol (`:nokogiri`, `:libxml`, `:ox`) or a class if you made your own parser implementation. It will create a context tree (see `Saxxy::ContextTree` for more details) and will register the callbacks it will call when parsing, as soon as you provide a block. E.g.

```ruby
require "saxxy/parsers/nokogiri"

service = Saxxy::Service.new(:nokogiri) do
  under("div", class: /cool$/) do
    on(/span|div/, rel: "foo") do |inner_text, element, attributes|
      puts "Under a #{element} found some text: " + inner_text
    end

    under("table", class: "main") do
      under("tr", class: "header") do
        on("td") do |inner_text, element, attributes|
          puts "Found some other text in a table cell: " + inner_text
        end
      end
    end
  end
end
```
The service provides either `parse_file`, `parse_string` or `parse_io` methods, depending on you needs. Every method accepts it's corresponding source (with the respective source type) as first argument and an optional encoding as a second argument.

```ruby
service.parse_string <<-eos
  <html>
    <span>
      Hey I am in a span! <em>And I am nested in a span!</em>
    </span>
    <div>
      Hey I am in a div!
    </div>
  </html>
eos

# => Under a span found some text: Hey I am in a span! And I am nested in a span!
# => Under a div found some text: Hey I am in a div!
```
If the parser doesn't raise some funny error you should be seeing your registered callbacks getting called with the
text, the element name and the attributes found at the matching node.



### The DSL
Saxxy uses a DSL in order to create a context tree and register callbacks. The two most significant methods for doing so is `on` and `under`. The `on` method is used to signify a specific condition and the block it accepts is the callback it will run when the condition is met on a node.

The following example shows a callback that is run when the parser encounters a header element with a class that matches `/foo$/`

```ruby
on(/^h[1-6]{1}/, class: /foo$/) do |text, element, attributes|
  p "Element name is: #{element} and the inner text is: #{text}".
end
```
There is now the case where you want to restrict the range of the `on` call only, say, to headers inside a div element with a class footer. To do that you nest the `on` in an `under` call which is used for restricting callbacks' range. E.g.

```ruby
under("div", class: "footer") do
  on(/^h[1-6]{1}/, class: /foo$/) do |text, element, attributes|
    p "Element name is: #{element} and the inner text is: #{text}".
  end
end
```

## Documentation
You can find the documentation [here](http://rdoc.info/github/rubymaniac/saxxy/frames).

## TODO
1. Add support for a clean DSL for easily constructing highly nested contexts
2. Switch to a lazy evaluated context tree
3. Add more integration tests

## Known Issues
### Nokogiri
No issues

### Ox
No issues

### Libxml
1. Does not handle the malformed HTML (raises exceptions)
2. Triggers twice the callbacks on the nodes


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
[![githalytics.com alpha](https://cruel-carlota.pagodabox.com/c6bbeb377f74da9f3e282fa2fbf4b6a3 "githalytics.com")](http://githalytics.com/rubymaniac/saxxy)
