namespace :wp do
  namespace :cache do
    desc "Load all objects from Wordpress"
    task :refresh => :environment do
      Rails.application.eager_load!
      ActiveRecord::Base.descendants
      WpCache.classes.each do |wpclass|
        wpclass.constantize.create_or_update_all(wpclass)
      end
    end
  end
end
