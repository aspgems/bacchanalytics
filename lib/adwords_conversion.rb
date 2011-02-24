module AdwordsConversionTrackingCode

  # Construct the Adwords conversion tracking code.
  def adwords_tracking_code(page, conversions=[])
    return if page.blank?

    tracking_code = ""    
    conversions.each do |conversion|
      begin        
        cid = conversion[:id]
        label = conversion[:label]
        pages = conversion[:pages] || []
        next if(cid.blank? || label.blank? || pages.empty?)
        
        description = conversion[:description] || 'adwords conversion'
        language = conversion[:language] || 'en'
        format = conversion[:format] || 3         
        value = conversion[:value] || 0
        
          # Check the requested page, to include the A, B or goal tracking code.
          if pages.include?(page)
            tracking_code = compose_code(cid, label, language, format, value, description)
            break
          end
      rescue
        tracking_code = ""
      end
    end
    tracking_code
  end

  private

  
  def compose_code(cid, label, language, format, value,description)
    code = <<-SCRIPT
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

    return code
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

  include AdwordsConversionTrackingCode

  def initialize(app, conversions = [])
    @app = app
    @conversions = conversions     
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
      new_head = head.sub /<\/[bB][oO][dY][yY]\s*>/, "#{adwords_tracking_code(page, @conversions)}\n</body>"
      headers["Content-Length"] = new_head.length.to_s
      new_response = Rack::Response.new
      new_response.body = new_head
      [status, headers, new_response]
    else
      [status, headers, response]
    end
  end

end

