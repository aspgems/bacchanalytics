require "google_analytics"

class Bacchanalytics
  include GoogleAnalytics::Base
  include GoogleAnalytics::TrackingCode

  def initialize(app, options = {})
    @app = app
    @web_property_id = options[:web_property_id] || "UA-XXXXX-X"
    @domain_name = options[:domain_name]
    @ignored_organic = options[:ignored_organic]
    @skip_ga_src = options[:skip_ga_src] || false
  end

  def call(env)
    status, headers, response = @app.call(env)

    if should_instrument?(headers) && (source = response_source(response))
      @skip_ga_src = true if env["bacchanlytics.loaded_ga_src"]
      tracking_code = google_analytics_tracking_code(@web_property_id, @domain_name)

      env["bacchanalytics.loaded_ga_src"] = true
      new_body = source.sub /<[hH][eE][aA][dD]\s*>/, "<head>\n\n#{tracking_code}"
      headers["Content-Length"] = new_body.length.to_s
      Rack::Response.new(new_body, status, headers).finish
    else
      [status, headers, response]
    end
  end

  def self.track_page_view_code(page)
    "_gaq.push(['_trackPageview', '#{page}'])"
  end

  def self.track_page_view_script(page)
    <<-SCRIPT
    <script type="text/javascript">
    #{track_page_view_code(page)};
    </script>
    SCRIPT
  end

  def self.track_event(category, action, opt_label = nil, opt_value = nil, options = {})
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

  private
  def load_ga_src
    @skip_ga_src ? "" : super
  end
end

