# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.9' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Specify gems that this application depends on and have them installed with rake gems:install
  config.gem "amee", :version => "~> 2.5.1"
  config.gem "amee-internal", :version => "~> 3.6.3"
  config.gem "my_amee_users", :version => '>= 1.3.0'
  config.gem "uuidtools"
  config.gem "hoptoad_notifier", :version => "~> 2.3.8"
  config.gem "WikiCreole", :lib => "wiki_creole", :version => '~> 0.1.3'

  config.gem 'god', :lib => false, :version => '~> 0.11'
  config.gem 'bunny', :lib => false, :version => '~> 0.6.0'
  config.gem 'daemons', :lib => false, :version => '1.0.10'

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de

  
end

require 'hpricot'
require 'open-uri'
require 'timeout'
require 'csv'

require 'recursive_map'

config = RAILS_ROOT + "/config/my_amee.yml"
raise "#{config} not found" unless File.exist?(config)
$my_amee_config = YAML.load_file(config)[RAILS_ENV] or
    raise "No environment '#{RAILS_ENV}' in config file '#{config}'"

module ActiveSupport
  module Dependencies
    extend self

    #def load_missing_constant(from_mod, const_name)

    def forgiving_load_missing_constant( from_mod, const_name )
      begin
        old_load_missing_constant(from_mod, const_name)
      rescue ArgumentError => arg_err
        if arg_err.message == "#{from_mod} is not missing constant #{const_name}!"
          return from_mod.const_get(const_name)
        else
          raise
        end
      end
    end
    alias :old_load_missing_constant :load_missing_constant
    alias :load_missing_constant :forgiving_load_missing_constant
  end
end

module ActionController
  module Caching
    module Actions
      class ActionCachePath
        def extract_extension(foo)
          nil
        end
      end
    end
  end
end

require "#{RAILS_ROOT}/lib/amee-internal-patches.rb"
require "#{RAILS_ROOT}/lib/string_extensions.rb"
require "#{RAILS_ROOT}/config/groups.rb"
