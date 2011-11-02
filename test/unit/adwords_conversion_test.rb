require 'test_helper'
require 'bacchanalytics'

ENV['RACK_ENV'] = 'test'

class AdwordsConversionTest < Test::Unit::TestCase
  include Rack::Test::Methods

  WEB_PROPERTY_ID = "UA-12345-6"

  def app
    response = Rack::Response.new(HTML_DOCUMENT)
    mock_app = lambda do |env|
      [200, {'Content-Type' => 'text/html'}, response]
    end
    @options ||= [
        {:id => '1062298921', :label=>'oIiDCJe__QEQqcrF-gM', :language=>'es', :format=>3, :value=>3.5, :description=>'',
         :pages=>["/welcome", "/en/welcome", "/es/welcome", "/ca/welcome", "/eu/welcome"]
        }
    ]
    Bacchanalytics::AdwordsConversion.new(mock_app, @options)
  end

  def test_must_not_include_any_code_if_no_page
    get "/", {}, {'REQUEST_URI' => nil}

    assert_equal last_response.body, HTML_DOCUMENT
  end

  def test_must_not_include_any_code_if_the_page_is_not_a_goal
    get "/", {}, {'REQUEST_URI' => nil}

    assert_equal last_response.body, HTML_DOCUMENT
  end

  def test_must_include_conversion_code_if_the_page_is_a_goal
    get "/welcome", {}, {'REQUEST_URI' => "/welcome"}

    assert last_response.body.include?("Google Code for  Conversion Page "), last_response.body
  end

  def test_must_include_conversion_values_in_the_code
    get "/welcome", {}, {'REQUEST_URI' => "/welcome"}

    conversion = @options.first
    assert last_response.body.include?("google_conversion_id = #{conversion[:id]}"), last_response.body
    assert last_response.body.include?("google_conversion_language = \"#{conversion[:language]}\""), last_response.body
    assert last_response.body.include?("google_conversion_format = \"#{conversion[:format]}\""), last_response.body
    assert last_response.body.include?("google_conversion_label = \"#{conversion[:label]}\""), last_response.body
    assert last_response.body.include?("google_conversion_value = #{conversion[:value]}"), last_response.body
  end

  def text_must_not_include_any_code_if_not_a_valid_conversion
    invalid_conversion = {}
    @options = [invalid_conversion]
    get "/", {}, {'REQUEST_URI' => "/request_uri"}

    assert_equal last_response.body, HTML_DOCUMENT
  end

  def test_must_not_include_any_code_if_no_conversion
    @options = []
    get "/", {}, {'REQUEST_URI' => "/request_uri"}

    assert_equal last_response.body, HTML_DOCUMENT
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
