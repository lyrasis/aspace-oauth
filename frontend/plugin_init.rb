oauth_definition = AppConfig[:authentication_sources].find { |as|
  as[:model] == 'ASOauth'
}
raise "OmniAuth plugin enabled but no definition provided =(" unless oauth_definition

AppConfig[:oauth_provider] = oauth_definition[:provider]
ArchivesSpace::Application.extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

OAUTH_STRATEGIES = [
  'cas',
  'saml',
].freeze

require 'omniauth'
if OAUTH_STRATEGIES.include? oauth_definition[:provider]
  require "omniauth/#{oauth_definition[:provider]}"
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider oauth_definition[:provider], oauth_definition[:config]
end