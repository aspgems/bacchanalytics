class Bacchanalytics

  def initialize(app, options = {})
    @app = app
    @web_property_id = options[:web_property_id] || "UA-XXXXX-X"
  end

  def call(env)
    status, headers, response = @app.call(env)
    if !headers["Content-Type"].nil? && (headers["Content-Type"].include? "text/html")
      body = response.body
      body.sub! /<[bB][oO][dD][yY]>/, "<body>\n\n#{google_analytics_tracking_code}"
      headers["Content-Length"] = body.length.to_s
      [status, headers, body]
    else
      [status, headers, response]
    end
  end

  # Construct the new asynchronous version of the Google Analytics code.
  # http://code.google.com/apis/analytics/docs/tracking/asyncTracking.html
  def google_analytics_tracking_code

    gatc = <<-SCRIPT
    <script type="text/javascript">

    var _gaq = _gaq || [];
    _gaq.push(['_setAccount', '#{@web_property_id}']);
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