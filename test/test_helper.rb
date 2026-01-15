# frozen_string_literal: true

require "minitest/autorun"
require "mocha/minitest"

# Mock AppConfig module to simulate ArchivesSpace environment
module AppConfig
  @config = {}

  def self.[]=(key, value)
    @config[key] = value
  end

  def self.[](key)
    @config[key]
  end

  def self.has_key?(key)
    @config.has_key?(key)
  end

  def self.reset!
    @config = {}
  end
end

# Mock URI module methods that might be used
require "uri"

# Load the AspaceOauth module
require_relative "../frontend/lib/aspace_oauth"

# Test helper methods
class Minitest::Test
  def setup
    # Reset AppConfig for each test
    AppConfig.reset!
  end

  def sample_saml_config
    {
      model: "ASOauth",
      provider: "saml",
      label: "SAML Sign In",
      slo_link: false,
      config: {
        assertion_consumer_service_url: "https://archives.edu/auth/saml/callback",
        issuer: "https://archives.edu/auth/saml/metadata",
        name_identifier_format: "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
        idp_sso_target_url: "https://localhost/simplesaml/saml2/idp/SSOService.php",
        idp_cert_fingerprint: "119b9e027959cdb7c662cfd075d9e2ef384e445f"
      }
    }
  end

  def sample_saml_config_with_slo
    config = sample_saml_config
    config[:config][:idp_slo_service_url] = "https://example.com/slo"
    config
  end

  def sample_cas_config
    {
      model: "ASOauth",
      provider: "cas",
      label: "CAS Sign In",
      slo_link: true,
      config: {
        url: "https://login.example.edu",
        host: "login.example.edu",
        ssl: true,
        login_url: "/cas/login",
        logout_url: "/cas/logout",
        service_validate_url: "/cas/serviceValidate",
        uid_key: "user",
        email_key: "email"
      }
    }
  end

  def setup_app_config_with_oauth_definitions(definitions)
    AppConfig[:oauth_definitions] = definitions
    AppConfig[:frontend_proxy_url] = "https://archives.edu"
    AppConfig[:frontend_proxy_prefix] = "/staff/"
  end
end
