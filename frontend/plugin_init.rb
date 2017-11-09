oauth_definition = AppConfig[:authentication_sources].find { |as|
  as[:model] == 'ASOauth'
}
raise "OmniAuth plugin enabled but no definition provided =(" unless oauth_definition

# GOOGLE STRATEGY FOR TESTING [DO NOT USE IN PROD UNLESS YOU MEAN TO]
def google_oauth_enabled?
  ENV.has_key?('GOOGLE_CLIENT_ID') and ENV.has_key?('GOOGLE_CLIENT_SECRET')
end

AppConfig[:oauth_provider] = oauth_definition[:provider]
ArchivesSpace::Application.extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

require 'omniauth'
require 'omniauth-google-oauth2' if google_oauth_enabled?

Rails.application.config.middleware.use OmniAuth::Builder do
  if google_oauth_enabled?
    provider :google_oauth2,
      ENV['GOOGLE_CLIENT_ID'],
      ENV['GOOGLE_CLIENT_SECRET'],
      access_type: 'online',
      prompt: ''
  else
    provider oauth_definition[:provider], oauth_definition[:config]
  end
end