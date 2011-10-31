module GoogleAnalytics

  module Base
    # Return the javascript code used to load google analytics code
    def load_ga_src
      <<-SCRIPT
    (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
    })();
      SCRIPT
    end

    # headers["Content-Type"] will be nil if the status of the response is 304 (Not Modified)
    # From the HTTP Status Code Definitions:
    # If the client has performed a conditional GET request and access is allowed,
    # but the document has not been modified, the server SHOULD respond with this status code.
    # http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
    def should_instrument?(headers)
      !headers["Content-Type"].nil? && (headers["Content-Type"].include? "text/html")
    end

    def response_source(response)
      source = nil
      response.each { |fragment| (source) ? (source << fragment) : (source = fragment) }
      source
    end
  end

  module TrackingCode
    # Construct the new asynchronous version of the Google Analytics code.
    # http://code.google.com/apis/analytics/docs/tracking/asyncTracking.html
    def google_analytics_tracking_code(web_property_id, domain_name = nil)
      <<-SCRIPT
    <script type="text/javascript">

    var _gaq = _gaq || [];
    _gaq.push(['_setAccount', '#{web_property_id}']);
    if ('#{domain_name}' !== ''){
      _gaq.push(['_setDomainName', '#{domain_name}']);
    }
    #{ignored_organic_script}
    _gaq.push(['_trackPageview']);

    #{load_ga_src}
    </script>
      SCRIPT
    end

    def ignored_organic_script
      script = ""

      begin
        if @ignored_organic.is_a?(Array)
          @ignored_organic.each { |item|
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
end