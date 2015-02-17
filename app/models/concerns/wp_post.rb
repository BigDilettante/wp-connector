module WpPost
  extend ActiveSupport::Concern

  included do
    serialize :acf_fields
  end

  class << self
    def mappable_wordpress_attributes
      %w( slug title status content excerpt acf_fields )
    end

    def create_post(json)
      mappable_wordpress_attributes.each do |wp_attribute|
        send(wp_attribute, json[wp_attribute])
      end

      self.post_id      = json['ID']
      self.author_id    = json['author']
      self.published_at = json['date']
      self.order        = json['menu_order']
      save!
    end
  end
end
