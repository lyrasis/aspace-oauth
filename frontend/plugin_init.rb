oauth_definitions = AppConfig[:authentication_sources].find_all { |as|
  as[:model] == 'ASOauth'
}
raise "OmniAuth plugin enabled but no definitions provided =(" unless oauth_definitions.any?

# GOOGLE STRATEGY FOR TESTING [DO NOT USE IN PROD UNLESS YOU MEAN TO]
def google_oauth_enabled?
  ENV.has_key?('GOOGLE_CLIENT_ID') and ENV.has_key?('GOOGLE_CLIENT_SECRET')
end

# also used for ui [refactor]
AppConfig[:oauth_definitions] = oauth_definitions.delete_if { |oauth_definition|
  oauth_definition[:provider] == 'google_oauth2' and not google_oauth_enabled?
}

ArchivesSpace::Application.extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

require 'omniauth'
require 'omniauth-google-oauth2' if google_oauth_enabled?

Rails.application.config.middleware.use OmniAuth::Builder do
  oauth_definitions.each do |oauth_definition|
    if oauth_definition[:provider] == 'google_oauth2'
      provider :google_oauth2,
        ENV['GOOGLE_CLIENT_ID'],
        ENV['GOOGLE_CLIENT_SECRET'],
        access_type: 'online',
        prompt: ''
    else
      provider oauth_definition[:provider], oauth_definition[:config]
    end
  end
end