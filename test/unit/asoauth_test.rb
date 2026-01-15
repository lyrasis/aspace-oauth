# frozen_string_literal: true

require_relative "../test_helper"
require "json"
require "openssl"
require "date"
require "rack/utils"

# Mock Log module
module Log
  def self.warn(message)
    # No-op for tests
  end
end

# Mock JSONModel module
module JSONModel
  def self.call(_)
    Class.new do
      def self.from_hash(hash)
        hash
      end
    end
  end

  # Make JSONModel callable as a method in included classes
  def JSONModel(type)
    JSONModel.call(type)
  end
end

# Load the ASOauth model
require_relative "../../backend/model/asoauth"

class ASOauthTest < Minitest::Test
  def setup
    AppConfig.reset!
    AppConfig[:oauth_shared_secret] = "test_secret_key_123"
    AppConfig[:max_usernames_per_source] = 10
  end

  # Helper method to generate a valid login token
  def generate_login_token(provider: "saml", username: "testuser", created_at: DateTime.now, user_info: nil)
    user_info ||= {
      "username" => username,
      "name" => "Test User",
      "email" => "test@example.com",
      "first_name" => "Test",
      "last_name" => "User",
      "phone" => "555-1234",
      "description" => "Test description"
    }

    payload_hash = {
      "created_by" => "aspace-oauth-#{provider}",
      "created_at" => created_at.rfc3339,
      "user_info" => user_info
    }

    json_payload = payload_hash.to_json
    secret = AppConfig[:oauth_shared_secret]
    signature = OpenSSL::HMAC.hexdigest("SHA256", secret, json_payload)

    {
      "signature" => signature,
      "payload" => json_payload
    }.to_json
  end

  # Tests for name
  def test_name_returns_correct_format_for_saml
    definition = {provider: "saml"}
    oauth = ASOauth.new(definition)

    assert_equal "ArchivesSpace Oauth - saml", oauth.name
  end

  def test_name_returns_correct_format_for_cas
    definition = {provider: "cas"}
    oauth = ASOauth.new(definition)

    assert_equal "ArchivesSpace Oauth - cas", oauth.name
  end

  # Tests for get_oauth_shared_secret
  def test_get_oauth_shared_secret_returns_configured_secret
    AppConfig[:oauth_shared_secret] = "my_secret_key"
    oauth = ASOauth.new(provider: "saml")

    result = oauth.get_oauth_shared_secret

    assert_equal "my_secret_key", result
  end

  def test_get_oauth_shared_secret_raises_when_not_configured
    AppConfig[:oauth_shared_secret] = nil
    oauth = ASOauth.new(provider: "saml")

    error = assert_raises(ASOauthException) do
      oauth.get_oauth_shared_secret
    end

    assert_match(/oauth_shared_secret config option is not set/, error.message)
  end

  def test_get_oauth_shared_secret_raises_when_empty_string
    AppConfig[:oauth_shared_secret] = ""
    oauth = ASOauth.new(provider: "saml")

    error = assert_raises(ASOauthException) do
      oauth.get_oauth_shared_secret
    end

    assert_match(/oauth_shared_secret config option is not set/, error.message)
  end

  # Tests for validate_login_token_and_extract_user_info
  def test_validate_login_token_with_valid_token
    oauth = ASOauth.new(provider: "saml")
    token = generate_login_token

    result = oauth.validate_login_token_and_extract_user_info(token)

    assert_equal "testuser", result["username"]
    assert_equal "Test User", result["name"]
    assert_equal "test@example.com", result["email"]
  end

  def test_validate_login_token_rejects_invalid_json
    oauth = ASOauth.new(provider: "saml")

    error = assert_raises(InvalidLoginTokenException) do
      oauth.validate_login_token_and_extract_user_info("not valid json")
    end

    assert_match(/not valid JSON/, error.message)
  end

  def test_validate_login_token_rejects_missing_signature
    oauth = ASOauth.new(provider: "saml")
    invalid_token = {"payload" => "test"}.to_json

    error = assert_raises(InvalidLoginTokenException) do
      oauth.validate_login_token_and_extract_user_info(invalid_token)
    end

    assert_match(/content is invalid/, error.message)
  end

  def test_validate_login_token_rejects_missing_payload
    oauth = ASOauth.new(provider: "saml")
    invalid_token = {"signature" => "test"}.to_json

    error = assert_raises(InvalidLoginTokenException) do
      oauth.validate_login_token_and_extract_user_info(invalid_token)
    end

    assert_match(/content is invalid/, error.message)
  end

  def test_validate_login_token_rejects_tampered_signature
    oauth = ASOauth.new(provider: "saml")
    token = generate_login_token
    token_hash = JSON.parse(token)
    token_hash["signature"] = "tampered_signature_12345"

    error = assert_raises(InvalidLoginTokenException) do
      oauth.validate_login_token_and_extract_user_info(token_hash.to_json)
    end

    assert_match(/signature does not match/, error.message)
  end

  def test_validate_login_token_rejects_invalid_payload_json
    oauth = ASOauth.new(provider: "saml")
    json_payload = "not valid json"
    secret = AppConfig[:oauth_shared_secret]
    signature = OpenSSL::HMAC.hexdigest("SHA256", secret, json_payload)
    token = {"signature" => signature, "payload" => json_payload}.to_json

    error = assert_raises(InvalidLoginTokenException) do
      oauth.validate_login_token_and_extract_user_info(token)
    end

    assert_match(/payload is not valid JSON/, error.message)
  end

  def test_validate_login_token_rejects_wrong_provider
    oauth = ASOauth.new(provider: "saml")
    token = generate_login_token(provider: "cas")

    error = assert_raises(InvalidLoginTokenException) do
      oauth.validate_login_token_and_extract_user_info(token)
    end

    assert_match(/unexpected provider/, error.message)
  end

  def test_validate_login_token_rejects_expired_token
    oauth = ASOauth.new(provider: "saml")
    old_time = DateTime.now - Rational(61, 86400) # 61 seconds ago
    token = generate_login_token(created_at: old_time)

    error = assert_raises(InvalidLoginTokenException) do
      oauth.validate_login_token_and_extract_user_info(token)
    end

    assert_match(/not within 60 seconds/, error.message)
  end

  def test_validate_login_token_rejects_future_token
    oauth = ASOauth.new(provider: "saml")
    future_time = DateTime.now + Rational(61, 86400) # 61 seconds in future
    token = generate_login_token(created_at: future_time)

    error = assert_raises(InvalidLoginTokenException) do
      oauth.validate_login_token_and_extract_user_info(token)
    end

    assert_match(/not within 60 seconds/, error.message)
  end

  def test_validate_login_token_rejects_invalid_created_at
    oauth = ASOauth.new(provider: "saml")
    payload_hash = {
      "created_by" => "aspace-oauth-saml",
      "created_at" => "not a valid date",
      "user_info" => {"username" => "test"}
    }
    json_payload = payload_hash.to_json
    signature = OpenSSL::HMAC.hexdigest("SHA256", AppConfig[:oauth_shared_secret], json_payload)
    token = {"signature" => signature, "payload" => json_payload}.to_json

    error = assert_raises(InvalidLoginTokenException) do
      oauth.validate_login_token_and_extract_user_info(token)
    end

    assert_match(/not a rfc3339 date-time/, error.message)
  end

  def test_validate_login_token_rejects_missing_user_info
    oauth = ASOauth.new(provider: "saml")
    payload_hash = {
      "created_by" => "aspace-oauth-saml",
      "created_at" => DateTime.now.rfc3339
    }
    json_payload = payload_hash.to_json
    signature = OpenSSL::HMAC.hexdigest("SHA256", AppConfig[:oauth_shared_secret], json_payload)
    token = {"signature" => signature, "payload" => json_payload}.to_json

    error = assert_raises(InvalidLoginTokenException) do
      oauth.validate_login_token_and_extract_user_info(token)
    end

    assert_match(/user_info is invalid/, error.message)
  end

  def test_validate_login_token_rejects_user_info_without_username
    oauth = ASOauth.new(provider: "saml")
    payload_hash = {
      "created_by" => "aspace-oauth-saml",
      "created_at" => DateTime.now.rfc3339,
      "user_info" => {"email" => "test@example.com"}
    }
    json_payload = payload_hash.to_json
    signature = OpenSSL::HMAC.hexdigest("SHA256", AppConfig[:oauth_shared_secret], json_payload)
    token = {"signature" => signature, "payload" => json_payload}.to_json

    error = assert_raises(InvalidLoginTokenException) do
      oauth.validate_login_token_and_extract_user_info(token)
    end

    assert_match(/user_info is invalid/, error.message)
  end

  # Tests for authenticate
  def test_authenticate_with_valid_token_and_matching_username
    oauth = ASOauth.new(provider: "saml")
    token = generate_login_token(username: "testuser")

    result = oauth.authenticate("testuser", token)

    assert_equal "testuser", result[:username]
    assert_equal "Test User", result[:name]
    assert_equal "test@example.com", result[:email]
    assert_equal "Test", result[:first_name]
    assert_equal "User", result[:last_name]
    assert_equal "555-1234", result[:telephone]
    assert_equal "Test description", result[:additional_contact]
  end

  def test_authenticate_handles_case_insensitive_username
    oauth = ASOauth.new(provider: "saml")
    token = generate_login_token(username: "TestUser")

    result = oauth.authenticate("testuser", token)

    assert_equal "testuser", result[:username]
  end

  def test_authenticate_returns_nil_for_username_mismatch
    oauth = ASOauth.new(provider: "saml")
    token = generate_login_token(username: "testuser")

    result = oauth.authenticate("differentuser", token)

    assert_nil result
  end

  def test_authenticate_returns_nil_for_invalid_token
    oauth = ASOauth.new(provider: "saml")

    result = oauth.authenticate("testuser", "invalid token")

    assert_nil result
  end

  def test_authenticate_returns_nil_for_expired_token
    oauth = ASOauth.new(provider: "saml")
    old_time = DateTime.now - Rational(61, 86400)
    token = generate_login_token(created_at: old_time)

    result = oauth.authenticate("testuser", token)

    assert_nil result
  end
end
