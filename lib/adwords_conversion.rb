require "google_analytics"

module AdwordsConversionTrackingCode

  # Construct the Adwords conversion tracking code.
  def adwords_tracking_code(page, conversions=[])
    return if page.blank?

    tracking_code = ""    
    conversions.each do |conversion|
      begin
        next unless valid_conversion?(conversion)

        # Check the requested page, to include the A, B or goal tracking code.
        if conversion[:pages].include?(page)
          cid = conversion[:id]
          label = conversion[:label]

          description = conversion[:description] || 'adwords conversion'
          language = conversion[:language] || 'en'
          format = conversion[:format] || 3
          value = conversion[:value] || 0

          tracking_code = conversion_code(cid, label, language, format, value, description)
          break
        end
      rescue
        tracking_code = ""
      end
    end
    tracking_code
  end

  private

  def valid_conversion?(conversion)
    !(conversion[:id].blank? || conversion[:label].blank? || conversion[:pages].empty?)
  end

  def conversion_code(cid, label, language, format, value, description)
    <<-SCRIPT
    <!-- Google Code for #{description} Conversion Page -->
    <script type="text/javascript">
      /* <![CDATA[ */
      var google_conversion_id = #{cid};
      var google_conversion_language = "#{language}";
      var google_conversion_format = "#{format}";
      var google_conversion_color = "ffffff";
      var google_conversion_label = "#{label}";
      var google_conversion_value = 0;
      if (#{value}) {
        google_conversion_value = #{value};
      }
    /* ]]> */
    </script>
    <script type="text/javascript" src="https://www.googleadservices.com/pagead/conversion.js">
    </script>
    <noscript>
      <div style="display:inline;">
      <img height="1" width="1" style="border-style:none;" alt="" src="https://www.googleadservices.com/pagead/conversion/#{cid}/?value=#{value}&amp;label=#{label}&amp;guid=ON&amp;script=0"/>
      </div>
    </noscript>
    SCRIPT
  end
end

### 
#
#example of initialization
#
# config.middleware.use "AdwordsConversion", [ 
#                    {:id => '1062298921', :label=>'oIiDCJe__QEQqcrF-gM', :language=>'es', :format=>3, :value=>3.5, :description=>'', 
#                    :pages=>[ "/welcome", "/en/welcome", "/es/welcome", "/ca/welcome", "/eu/welcome"] 
#                    } 
#                    ]
#
####

class AdwordsConversion
  include GoogleAnalytics::Base
  include AdwordsConversionTrackingCode

  def initialize(app, conversions = [])
    @app = app
    @conversions = conversions     
  end

  def call(env)
    status, headers, response = @app.call(env)

    if should_instrument?(headers) && (source = response_source(response))
      page = env['REQUEST_URI']
      page.gsub!(/\?.*/, '') if page  #remove url parameters

      tracking_code = adwords_tracking_code(page, @conversions)
      return [status, headers, response] if tracking_code.to_s == ""

      new_body = source.sub /<\/[bB][oO][dY][yY]\s*>/, "#{tracking_code}\n</body>"
      headers["Content-Length"] = new_body.length.to_s
      Rack::Response.new(new_body, status, headers).finish
    else
      [status, headers, response]
    end
  end

end

