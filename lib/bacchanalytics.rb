module GoogleAnalyticsTrackingCode
  
  # Construct the new asynchronous version of the Google Analytics code.
  # http://code.google.com/apis/analytics/docs/tracking/asyncTracking.html
  def google_analytics_tracking_code(web_property_id)

    gatc = <<-SCRIPT
    <script type="text/javascript">

    var _gaq = _gaq || [];
    _gaq.push(['_setAccount', '#{web_property_id}']);
    _gaq.push(['_trackPageview']);

    (function() {
      var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
      ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
      var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
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
    if !headers["Content-Type"].nil? && (headers["Content-Type"].include? "text/html")
      body = response.body
      body.sub! /<[bB][oO][dD][yY]>/, "<body>\n\n#{google_analytics_tracking_code(@web_property_id)}"
      headers["Content-Length"] = body.length.to_s
      [status, headers, body]
    else
      [status, headers, response]
    end
  end

end

