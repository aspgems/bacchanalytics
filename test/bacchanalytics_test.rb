require 'test_helper.rb'
require 'rack/test'
require 'nokogiri'
require 'bacchanalytics'

class BacchanalyticsTest < ActiveSupport::TestCase
  include Rack::Test::Methods
  include GoogleAnalyticsTrackingCode

  WEB_PROPERTY_ID = "UA-12345-6"

  def app
    Rack::Builder.app do
      response = Rack::Response.new
      response.body = HTML_DOCUMENT
      rack_app = lambda { |env| [200, {'Content-Type' => 'text/html'}, response] }
      run Bacchanalytics.new(rack_app, :web_property_id => WEB_PROPERTY_ID)
    end
  end

  def test_gatc_must_be_present_after_body
    get "/"
    gatc_expected = google_analytics_tracking_code(WEB_PROPERTY_ID).gsub(/\s/, '')
    gatc_rack = Nokogiri::HTML(last_response.body).xpath("/html/body/script")[0].to_html.gsub(/\s/, '')
    assert_equal gatc_expected, gatc_rack
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