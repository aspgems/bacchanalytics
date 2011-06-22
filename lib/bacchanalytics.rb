module GoogleAnalyticsTrackingCode

  # Construct the new asynchronous version of the Google Analytics code.
  # http://code.google.com/apis/analytics/docs/tracking/asyncTracking.html
  def google_analytics_tracking_code(web_property_id, domain_name = nil)
    gatc = <<-SCRIPT
    <script type="text/javascript">

    var _gaq = _gaq || [];
    _gaq.push(['_setAccount', '#{web_property_id}']);
    if ('#{domain_name}' !== ''){
      _gaq.push(['_setDomainName', '#{domain_name}']);
    }
#{ignored_organic_script}
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

  def ignored_organic_script
    script = ""

    begin
      if @ignored_organic.is_a?(Array)
        @ignored_organic.each{|item|
          script << <<-CODE
    _gaq.push(['_addIgnoredOrganic', '#{item}']);
          CODE
        }
      elsif @ignored_organic.is_a?(String)
          script << <<-CODE
    _gaq.push(['_addIgnoredOrganic', '#{@ignored_organic}']);
          CODE
      end
    rescue
    end

    script
  end

end

class Bacchanalytics

  include GoogleAnalyticsTrackingCode

  def initialize(app, options = {})
    @app = app
    @web_property_id = options[:web_property_id] || "UA-XXXXX-X"
    @domain_name = options[:domain_name]
    @ignored_organic = options[:ignored_organic]
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
      new_body = body.sub /<[hH][eE][aA][dD]\s*>/, "<head>\n\n#{google_analytics_tracking_code(@web_property_id, @domain_name)}"
      headers["Content-Length"] = new_body.length.to_s
      new_response = Rack::Response.new
      new_response.body = [new_body]
      [status, headers, new_response]
    else
      [status, headers, response]
    end
  end

  def self.track_page_view_code(page)
    "_gaq.push(['_trackPageview', '#{page}'])"
  end  
  
  def self.track_page_view_script(page)
    gatc = <<-SCRIPT
    <script type="text/javascript">    
    #{track_page_view_code(page)};
    </script>
    SCRIPT
    return gatc    
  end

  def self.track_event(category, action, opt_label=nil, opt_value=nil, options = {})
    if opt_label.blank? || opt_value.blank?
      track_event_code = "_gaq.push(['_trackEvent', '#{category}', '#{action}'])"
    else
      track_event_code = "_gaq.push(['_trackEvent', '#{category}', '#{action}', '#{opt_label}', '#{opt_value}'])"
    end


    timeout = options[:timeout] rescue nil
    if timeout
      "#{track_event_code};setTimeout('void(0)', #{timeout});"
    else
      track_event_code
    end
  end

end

