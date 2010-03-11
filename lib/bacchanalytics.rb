class Bacchanalytics
  def initialize(app, options = {})
    @app = app
    @web_property_id = options[:web_property_id] || "UA-XXXXX-X"
  end

  def call(env)
    status, headers, response = @app.call(env)
    if headers["Content-Type"].include? "text/html"
      [status, headers, "<!-- #{@web_property_id} -->\n" + response.body]
    else
      [status, headers, response]
    end
  end
end