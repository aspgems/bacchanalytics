module WebsiteOptimizerTrackingCode

  # Construct the Google WebSite Optimizer tracking code.
  def website_optimizer_tracking_code(page, account_id, ab)
    if page.blank? || account_id.blank? || !ab_options_valid?(ab)
      return ""
    end

    gotc = ""
    begin
      goal_keys = [] # Multiple tests and the same goal
      for key in ab.keys do
        value = ab[key]
        next unless value[:locales].nil? || [value[:locales]].flatten.map(&:to_s).include?(I18n.locale.to_s)

        a = value[:a].to_a
        b = value[:b].to_a
        g = value[:goal].to_a

        # Check the requested page, to include the A, B or goal tracking code.
        if a.include?(page)
          gotc = a_tracking_code(account_id, key)
          break
        elsif b.include?(page)
          gotc = b_tracking_code(account_id, key)
          break
        elsif g.include?(page)
          goal_keys << key
        end
      end

      if gotc.blank?
        gotc = goal_tracking_code(account_id, goal_keys)
      end

    rescue Exception => e
      logger.debug "#{e.message}"
      gotc = ""
    end

    gotc
  end

  private

  # Returns the A (original page) website optimizer code. Look at the html comments before
  # the javascript code: use them to pass W3C validations.
  def a_tracking_code(account_id, track_page_id)
    result = <<-SCRIPT
      <!-- Google Website Optimizer Control Script -->
      <script type="text/javascript">
<!--
        function utmx_section(){}function utmx(){}
        (function(){var k='#{track_page_id}',d=document,l=d.location,c=d.cookie;function f(n){
        if(c){var i=c.indexOf(n+'=');if(i>-1){var j=c.indexOf(';',i);return escape(c.substring(i+n.
        length+1,j<0?c.length:j))}}}var x=f('__utmx'),xx=f('__utmxx'),h=l.hash;
        d.write('<sc'+'ript src="'+
        'http'+(l.protocol=='https:'?'s://ssl':'://www')+'.google-analytics.com'
        +'/siteopt.js?v=1&utmxkey='+k+'&utmx='+(x?x:'')+'&utmxx='+(xx?xx:'')+'&utmxtime='
        +new Date().valueOf()+(h?'&utmxhash='+escape(h.substr(1)):'')+
        '" type="text/javascript" charset="utf-8"></sc'+'ript>')})();
-->
      </script>
      <script type="text/javascript">utmx("url",'A/B');</script>
      <!-- End of Google Website Optimizer Control Script -->

      <!-- Google Website Optimizer Tracking Script -->
      <script type="text/javascript">
        var _gaq = _gaq || [];
        _gaq.push(['gwo._setAccount', '#{account_id}']);
        _gaq.push(['gwo._trackPageview', '/#{track_page_id}/test']);
        #{load_ga}
      </script>
      <!-- End of Google Website Optimizer Tracking Script -->
    SCRIPT

    return result
  end

  # Returns the B (variation page) website optimizer code.
  def b_tracking_code(account_id, track_page_id)
    <<-SCRIPT
      <!-- Google Website Optimizer Tracking Script -->
      <script type="text/javascript">
        var _gaq = _gaq || [];
        _gaq.push(['gwo._setAccount', '#{account_id}']);
        _gaq.push(['gwo._trackPageview', '/#{track_page_id}/test']);
        #{load_ga}
      </script>
      <!-- End of Google Website Optimizer Tracking Script -->
    SCRIPT
  end

  # Returns the goal (conversion page) website optimizer code.
  def goal_tracking_code(account_id, track_page_ids = [])
    track_page_ids = Array(track_page_ids)

    <<-SCRIPT
      <!-- Google Website Optimizer Tracking Script -->
      <script type="text/javascript">
        var _gaq = _gaq || [];
        _gaq.push(['gwo._setAccount', '#{account_id}']);
        #{track_page_ids.map{|id| "_gaq.push(['gwo._trackPageview', '/#{id}/goal']);" }.join("\n")}
        #{load_ga}
      </script>
      <!-- End of Google Website Optimizer Tracking Script -->
    SCRIPT
  end

  # Are the options of the tests valid?
  def ab_options_valid?(ab_options = {})
    return false if ab_options.empty?

    unless ab_options_is_complete?(ab_options)
      logger.info "**********************************************************************************************************"
      logger.info "[Bachanalytics] You need to specify the :a, b: and :goal options for your WebSiteOptimizer tests, aborting"
      logger.info "**********************************************************************************************************"
      return false
    end

    unless uniq_goals?(ab_options)
      logger.info "**************************************************************************************************"
      logger.info "[Bachanalytics] You can't specify a :goal as part of the your WebSiteOptimizer tests, not applying"
      logger.info "**************************************************************************************************"
      return false
    end

    true
  end

  # Each A/B test need at least: :a, :b and :goal keys
  def ab_options_is_complete?(ab_options = {})
    result = true

    ab_options.values.each do |value|
      # Has :a, :b and :goal options
      result = value.keys.size >= 3 && value.key?(:a) && value.key?(:b) && value.key?(:goal)
      break if result == false
    end

    result
  end

  # One goal option must not be an a or b option
  # A conversion (goal) option can't ba an a or b option (a original or test option)
  def uniq_goals?(ab_options = {})
    uniq_goals, test_pages = [], []

    ab_options.values.each do |value|
      uniq_goals << value[:goal]
      test_pages << value[:a]
      test_pages << value[:b]
    end

    uniq_goals.flatten!.uniq!
    test_pages.flatten!.uniq!

    (uniq_goals & test_pages).size == 0
  end

  # Return the javascript code used to load google analytics code
  def load_ga
    <<-SCRIPT
    (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
    })();
    SCRIPT
  end

end

class WebsiteOptimizer

  include WebsiteOptimizerTrackingCode

  def initialize(app, options = {})
    @app = app
    @account_id = options[:account_id] || "UA-XXXXX-X"
    @ab = options[:ab] || {}
  end

  def call(env)
    status, headers, response = @app.call(env)
    # headers["Content-Type"] will be nil if the status of the response is 304 (Not Modified)
    # From the HTTP Status Code Definitions:
    # If the client has performed a conditional GET request and access is allowed,
    # but the document has not been modified, the server SHOULD respond with this status code.
    # http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
    if !headers["Content-Type"].nil? && (headers["Content-Type"].include? "text/html")
      head = response.body
      page = env['REQUEST_URI']
      page.gsub!(/\?.*/, '') if page  #remove url parameters
      new_head = head.sub /<[hH][eE][aA][dD]\s*>/, "<head>\n\n#{website_optimizer_tracking_code(page, @account_id, @ab)}"
      headers["Content-Length"] = new_head.length.to_s
      new_response = Rack::Response.new
      new_response.body = new_head
      [status, headers, new_response]
    else
      [status, headers, response]
    end
  end

  private
  def logger
    defined?(Rails.logger) ? Rails.logger : Logger.new($stderr)
  end
end