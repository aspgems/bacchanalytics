require 'test_helper'
require 'bacchanalytics'

ENV['RACK_ENV'] = 'test'

class WebsiteOptimizerTest < Test::Unit::TestCase
  include Rack::Test::Methods
  include Bacchanalytics::GoogleAnalytics::Base
  extend Bacchanalytics::GoogleAnalytics::Base

  WEB_PROPERTY_ID = "UA-12345-6"

  def app
    response = Rack::Response.new(HTML_DOCUMENT)
    mock_app = lambda do |env|
      [200, {'Content-Type' => 'text/html'}, response]
    end
    Bacchanalytics::WebsiteOptimizer.new(mock_app, {:skip_ga_src => true,
                                                    :account_id => 'UA-20891683-1',
                                                    :ab => {'1924712694' => {:a => ["/"],
                                                                             :b => ["/home"],
                                                                             :goal => ["/welcome"]}}})
  end

  def test_must_not_include_if_specify_skip
    get "/", {}, {"REQUEST_URI" => "/"}

    times = 0
    last_response.body.gsub(load_ga_src) { |m| times += 1 }

    assert_equal 1, times
  end

  HTML_DOCUMENT = <<-HTML
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
       "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
  <meta http-equiv="content-type" content="text/html;charset=UTF-8" />
  <title>Listing things</title>
  #{load_ga_src}
</head>
<body>

<h1>Listing things</h1>

<table>
  <tr>
    <th>Name</th>
  </tr>
  <tr>
    <td>Thing 1</td>
  </tr>
  <tr>
    <td>Thing 2</td>
  </tr>
</table>

</body>
</html>
  HTML
end