require_relative 'lib/aspace_oauth'
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
      config = oauth_definition[:config]
      if oauth_definition.has_key? :metadata_parser_url
        idp_metadata_parser = OneLogin::RubySaml::IdpMetadataParser.new
        idp_metadata        = idp_metadata_parser.parse_remote_to_hash(oauth_definition[:metadata_parser_url])

        config = idp_metadata.merge(config)
      end
      if config.has_key? :security
        # replace strings with constants for *_method
        [:digest_method, :signature_method].each do |m|
          config[:security][m] = config[:security][m].constantize if config[:security].has_key? m
        end
      end
      provider oauth_definition[:provider], config
      $stdout.puts "\n\n\nREGISTERED OAUTH PROVIDER WITH CONFIG: #{config}\n\n\n"
    end
  end
end
