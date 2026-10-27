# frozen_string_literal: true

require "omniauth"
require "omniauth/rails_csrf_protection"
require "omniauth-saml"
require "omniauth-cas"

require_relative "lib/aspace_oauth"

oauth_definitions = AppConfig[:authentication_sources].find_all do |as|
  as[:model] == "ASOauth"
end
raise "OmniAuth plugin enabled but no definitions provided =(" unless oauth_definitions.any?

AppConfig[:oauth_debug] = false unless AppConfig.has_key? :oauth_debug

# oauth_shared_secret is used to authenticate internal login requests from the
# frontend to the backend. It needs to be explicitly specified if the backend is
# not running in the same JVM as the frontend. When they're in the same JVM the
# secret generated here is propagated between them automatically via the system
# property set here.
unless AppConfig.has_key? :oauth_shared_secret
  require "securerandom"
  AppConfig[:oauth_shared_secret] = SecureRandom.uuid
  java.lang.System.set_property(
    "aspace.config.oauth_shared_secret", AppConfig[:oauth_shared_secret]
  )
end

# also used for ui [refactor]
AppConfig[:oauth_definitions] = oauth_definitions

# core login form (core views only, so not this plugin's override) for shared/_login
begin
  AspaceOauth::CORE_LOGIN_FORM = ActionView::LookupContext.new(
    Rails.root.join("app", "views").to_s
  ).find_template("login", ["shared"], true)
rescue ActionView::MissingTemplate
  raise "aspace-oauth: core login form app/views/shared/_login.html.erb not found, " \
        "this ArchivesSpace version is not supported by frontend/views/shared/_login.html.erb"
end

ArchivesSpace::Application.extend_aspace_routes(
  File.join(File.dirname(__FILE__), "routes.rb")
)

# staff interface password login, checked after routing so every path to
# session#login is covered. API logins go straight to the backend.
Rails.application.config.to_prepare do
  SessionController.before_action(only: :login) do |controller|
    if AspaceOauth.password_login_blocked?(controller.params[:username])
      controller.render json: {error: "Password login is disabled"}, status: :forbidden
    end
  end
end

Rails.application.config.middleware.use OmniAuth::Builder do
  oauth_definitions.each do |oauth_definition|
    verify_ssl = oauth_definition.fetch(:verify_ssl, true)
    config = oauth_definition[:config]
    if oauth_definition.key? :metadata_parser_url
      idp_metadata_parser = OneLogin::RubySaml::IdpMetadataParser.new
      idp_metadata = idp_metadata_parser.parse_remote_to_hash(
        oauth_definition[:metadata_parser_url], verify_ssl
      )
      config = idp_metadata.merge(config)
    end
    if config.key? :security
      # replace strings with constants for *_method
      %i[digest_method signature_method].each do |m|
        config[:security][m] = config[:security][m].constantize if config[:security].key? m
      end
    end
    provider oauth_definition[:provider], config
    $stdout.puts "REGISTERED OAUTH PROVIDER: #{oauth_definition[:provider]}" if AspaceOauth.debug?
  end
end
