module GoogleAnalyticsTrackingCode
  
  # Construct the new asynchronous version of the Google Analytics code.
  # http://code.google.com/apis/analytics/docs/tracking/asyncTracking.html
  def google_analytics_tracking_code(web_property_id)

    gatc = <<-SCRIPT
    <script type="text/javascript">

    var _gaq = _gaq || [];
    _gaq.push(['_setAccount', '#{web_property_id}']);
    _gaq.push(['_trackPageview()']);

    (function() {
      var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
      ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
      (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(ga);
    })();

    </script>
    SCRIPT

    return gatc

  end

end

class Bacchanalytics

  include GoogleAnalyticsTrackingCode

  def initialize(app, options = {})
    @app = app
    @web_property_id = options[:web_property_id] || "UA-XXXXX-X"
  end

  def call(env)
    status, headers, response = @app.call(env)
    # headers["Content-Type"] will be nil if the status of the response is 304 (Not Modified)
    # From the HTTP Status Code Definitions:
    # If the client has performed a conditional GET request and access is allowed,
    # but the document has not been modified, the server SHOULD respond with this status code.
    # http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
    if !headers["Content-Type"].nil? && (headers["Content-Type"].include? "text/html")
      body = response.body
      new_body = body.sub /<[bB][oO][dD][yY]\s*>/, "<body>\n\n#{google_analytics_tracking_code(@web_property_id)}"
      headers["Content-Length"] = new_body.length.to_s
      new_response = Rack::Response.new
      new_response.body = new_body
      [status, headers, new_response]
    else
      [status, headers, response]
    end
  end

end

