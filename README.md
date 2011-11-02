Bacchanalytics
==============

Bacchanalytics is a rack middleware that inserts the Asynchronous Google Analytics
Tracking Code in your application.

Usage in a Rails Application
----------------------------

Add the following line in your config/environment.rb:

````ruby
  config.middleware.use "Bacchanalytics::Analytics", :web_property_id => "UA-XXXXX-X"
````

You have to replace "UA-XXXXX-X" with the Google Analytics property ID of your site.
You can find more information on the Google Analytics property ID in
http://code.google.com/apis/analytics/docs/concepts/gaConceptsAccounts.html#accountID

You are able to set the domain name of your site.

````ruby
  config.middleware.use "Bacchanalytics::Analytics", :web_property_id => "UA-XXXXX-X"
                                                     :domain_name => ".facturagem.com"
````


You can also use "ignored organic" features in your pages with:

````ruby
config.middleware.use "Bacchanalytics::Analytics", :web_property_id => "UA-XXXXXXX-X",
                                                   :ignored_organic => ["yoursite",
                                                                        "yoursite.com",
                                                                        "www.yoursite.com",
                                                                        "http://www.yoursite.com",
                                                                        "http://yoursite.com"]
````



Google Website Optimizer
------------------------

In order to use A/B tests, just add the following lines to your config/environment.rb:

````ruby
config.middleware.use "Bacchanalytics::WebsiteOptimizer", :account_id => 'UA-XXXXXXXX-X',
                                                          :ab => { 'NNNNNNNNNN' => {:a => ["/", "/public/index"],
                                                                                    :b => "/home2",
                                                                                    :goal => "/public/signup"}
                                                          }
````

where 'UA-XXXXXXXX-X' is the ID of the Website Optimizer account and 'NNNNNNNNNN' is the track page id, a key provided in the Website Optimizer javascript. The 'ab' hash contains the A (origin) pages, the B (variations) pages and the goal pages.

The embeded javascript looks like:

````javascript
      <!-- Google Website Optimizer Tracking Script -->
      <script type="text/javascript">
        var _gaq = _gaq || [];
        _gaq.push(['gwo._setAccount', 'UA-XXXXXXXX-X']);
        _gaq.push(['gwo._trackPageview', '/3203696384/test']);
        (function() {
          var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
          ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
          var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
        })();
      </script>
      <!-- End of Google Website Optimizer Tracking Script -->
````

As you can see, the 'NNNNNNNNNN' is the '3203696384' track page ID.


Google Adwords Conversions
--------------------------

````ruby
config.middleware.use "Bacchanalytics::AdwordsConversion", [
                                                            {:id => 'NNNNNNNNNN',
                                                             :label => 'oIiDCJe__QEQqcrF-gM',
                                                             :language => 'es',
                                                             :format => 3,
                                                             :value => 3.5,
                                                             :description => '',
                                                             :pages=>[ "/welcome", "/en/welcome", "/es/welcome", "/ca/welcome", "/eu/welcome"]
                                                            }
                                                           ]
````

Copyright (c) 2011 ASPgems, released under the MIT license
