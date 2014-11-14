wp-connector
============

This gem is part of project called WordPress Editor Platform (WPEP), that advocates using WP as a means to create and edit content while using something else (in this case a Rails application) to serve public request and provide a basis for customizations.  WPEP makes use of the following WP plugins:

* [**HookPress**](https://wordpress.org/plugins/hookpress) ([site](http://mitcho.com/code/hookpress), [repo](https://github.com/mitcho/hookpress)) — WP plugin by which WP actions van be configured to trigger HTTP request to abritrary URLs (webhooks).
* [**json-rest-api**](https://wordpress.org/plugins/json-rest-api) ([site](http://wp-api.org), [repo](https://github.com/WP-API/WP-API)) — WP plugin that adds a modern RESTful web-API to a WordPress site. This module is scheduled to be shipped as part of WordPress 4.1.

With WPEP the content's master data resides in WP, as that's where is it created and modified.  The Rails application that is connected to WP stores merely a copy of the data, a cache, on the basis of which the public requests are served.

The main reasons for not using WP to serve public web requests:

* **Security** — The internet is a dagerous place and WordPress has proven to be a popular target for malicious hackers. By not serving public request from WP, but only the admin interface, the attack surface is significantly reduced.
* **Performance** — Performance tuning WP can be difficult, especially when a generic caching-proxy (such as Varnish) is not viable due to dynamic content such as ads or personalization.  Application frameworks provide means for fine-grained caching strategies that are needed to serve high-traffic websites that contain dynamic content.
* **Cost (TCO) of customizations** — Customizing WP, and maintaining those customizations, is laborious and error prone compared to building custom functionality on top of an application framework (which is specifically designed for that purpose).



## How it works

After the Rails application receives the webhook call from WP, simply notifying that some content is created or modified, a delayed job to fetch the content is scheduled using [Sidekiq](http://sidekiq.org).  The content is not fetch immediately, but a fraction of a second later, for two reason: (1) the webhook call is synchronous, responding as soon as possible is needed to keep the admin interface of WP responsive, and (2) it is not guaranteed that all processing has is complete by the time the webhook call is made.

The delayed job fetches the relevant content from WP using WP's REST-API (this can be one or more requests), then possibly transforms and/or enriches the data, and finally stores it using a regular ActiveRecord model. The logic for the fetch and transform/enrich steps is simply part of the ActiveRecord model definition.



## Installation

Add this line to your application's Gemfile:

```ruby
gem 'wp-connector', :github => 'hoppinger/wp-connector'
```

Then execute `bundle install`.



## Usage

In WordPress install both the HookPress and json-rest-api plugin.

When using the wonderful ACF plugin, consider installing the `wp-api-acf` plugin that can be found in this repository (find it in `wordpress/plugin`).

In WordPress configure the "Webhooks" (provided by HookPress) from the admin backend. Make sure that it triggers webhook calls for all changes in the content that is to be served from the Rails app.  The Webhook action needs to send at least the `ID` and `Parent_ID` fields, other fields generally not needed.  Point the target URLs of the Webhooks to the `post_save` route in the Rails app.

Installing a route for the webhook endpoint (in `config/routes.rb` of your Rails app):

```ruby
post "webhooks/*more" => "wp_connector#webhook"
```

Create a `WpConnectorController` class (in `app/controllers/wp_connector_controller.rb`) that specifies a `webhook` action:

```ruby
class WpConnectorController < ApplicationController
  def webhook
    # TODO: write the implementation
  end
end
```

Finally create a model for each of the content types that you want to cache by the Rails application. This is an example for the `Post` type:

```ruby
class Post < ActiveRecord::Base
  include WpCache

  def self.on_post_save(wp_id)
    wp_json = get_from_wp('posts', wp_id)
    if p = Post.where('id= ?', wp_id).first
      p.from_wp_json(wp_json)
    else
      p = Post.new
      p.from_wp_json(wp_json)
    end
    p.save!
  end

  def from_wp_json(json)
    self.id = json["ID"]
    self.title = json["title"]
    self.content = json["content"]
    self.slug = json["slug"]
    self.excerpt = json["excerpt"]
    self.updated_at =  json["updated"]
    self.created_at =  json["date"]

    # TODO add author and other related objects
  end
end
```


## Todo

* Extend it from Post type into other types (or make it generic).
* Provide a Rake task to reload all data from WP (in a create-or-update fashion).
* Publish it to Rubygems.



## Contributing

1. Fork it.
2. Create your feature branch (`git checkout -b my-new-feature`).
3. Commit your changes (`git commit -am 'Add some feature'`).
4. Push to the branch (`git push origin my-new-feature`).
5. Submit a "Pull Request".



## License

Copyright (c) 2014, Hoppinger B.V.

Open source, under the MIT-licensed. See `LICENSE.txt` in the root of this repository.
