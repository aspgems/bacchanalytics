require 'test_helper'
require 'rack/test'
require 'nokogiri'
require 'bacchanalytics'

ENV['RACK_ENV'] = 'test'

class BacchanalyticsTest < Test::Unit::TestCase
  include Rack::Test::Methods
  include GoogleAnalytics::TrackingCode
  include GoogleAnalytics::Base

  WEB_PROPERTY_ID = "UA-12345-6"

  def app
    response = Rack::Response.new(HTML_DOCUMENT)
    mock_app = lambda do |env|
      [200, {'Content-Type' => 'text/html'}, response]
    end
    Bacchanalytics.new(mock_app, :web_property_id => WEB_PROPERTY_ID)
  end

  def test_should_only_instrument_html_requests
    assert app.should_instrument?({'Content-Type' => 'text/html'})
    assert !app.should_instrument?({'Content-Type' => 'text/xhtml'})
  end

  def test_should_insert_gatc_inside_head
    get "/"

    gatc_expected = google_analytics_tracking_code(WEB_PROPERTY_ID).gsub(/\s/, '')
    gatc_rack = Nokogiri::HTML(last_response.body).xpath("/html/head/script")[0].to_html.gsub(/\s/, '')
    assert gatc_rack.include?(gatc_expected), gatc_rack
  end

  def test_should_insert_the_web_property
    get "/"

    gatc_rack = Nokogiri::HTML(last_response.body).xpath("/html/head/script")[0].to_html
    assert gatc_rack.include?("_gaq.push(['_setAccount', 'UA-12345-6']);"), gatc_rack
  end


  HTML_DOCUMENT = <<-HTML
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
       "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
  <meta http-equiv="content-type" content="text/html;charset=UTF-8" />
  <title>Listing things</title>
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