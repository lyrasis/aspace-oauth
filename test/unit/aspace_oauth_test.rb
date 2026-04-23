# frozen_string_literal: true

require_relative "../test_helper"

class AspaceOauthTest < Minitest::Test
  ResponseObject = Struct.new(:name_id)

  def test_saml_logout_url_with_idp_slo_service_url
    saml_config = sample_saml_config_with_slo
    setup_app_config_with_oauth_definitions([saml_config])

    result = AspaceOauth.saml_logout_url

    assert_equal "https://example.com/slo", result
  end

  def test_saml_logout_url_without_idp_slo_service_url
    saml_config = sample_saml_config
    setup_app_config_with_oauth_definitions([saml_config])

    result = AspaceOauth.saml_logout_url

    expected_url = "https://archives.edu/staff/auth/saml/spslo"
    assert_equal expected_url, result
  end

  def test_cas_logout_url
    cas_config = sample_cas_config
    setup_app_config_with_oauth_definitions([cas_config])

    result = AspaceOauth.cas_logout_url

    expected_url = "https://login.example.edu/cas/logout?service=https%3A%2F%2Farchives.edu"
    assert_equal expected_url, result
  end

  def test_saml_logout_url_with_empty_oauth_definitions
    setup_app_config_with_oauth_definitions([])

    result = AspaceOauth.saml_logout_url

    assert_nil result
  end

  def test_saml_logout_url_with_different_frontend_proxy_settings
    saml_config = sample_saml_config
    AppConfig[:oauth_definitions] = [saml_config]
    AppConfig[:frontend_proxy_url] = "https://archives.example.edu"
    AppConfig[:frontend_proxy_prefix] = "/archives/"

    result = AspaceOauth.saml_logout_url

    expected_url = "https://archives.example.edu/archives/auth/saml/spslo"
    assert_equal expected_url, result
  end

  def test_saml_logout_url_with_empty_idp_slo_service_url
    saml_config = sample_saml_config
    saml_config[:config][:idp_slo_service_url] = ""
    setup_app_config_with_oauth_definitions([saml_config])

    result = AspaceOauth.saml_logout_url

    expected_url = "https://archives.edu/staff/auth/saml/spslo"
    assert_equal expected_url, result
  end

  def test_saml_logout_url_with_nil_idp_slo_service_url
    saml_config = sample_saml_config
    saml_config[:config][:idp_slo_service_url] = nil
    setup_app_config_with_oauth_definitions([saml_config])

    result = AspaceOauth.saml_logout_url

    expected_url = "https://archives.edu/staff/auth/saml/spslo"
    assert_equal expected_url, result
  end

  def test_get_oauth_config_for_saml
    saml_config = sample_saml_config
    cas_config = sample_cas_config
    setup_app_config_with_oauth_definitions([saml_config, cas_config])

    result = AspaceOauth.get_oauth_config_for("saml")

    assert_equal saml_config, result
  end

  def test_get_oauth_config_for_nonexistent_provider
    saml_config = sample_saml_config
    setup_app_config_with_oauth_definitions([saml_config])

    result = AspaceOauth.get_oauth_config_for("nonexistent")

    assert_nil result
  end

  def test_build_url_method_with_params
    host = "https://example.com"
    path = "/auth/saml/spslo"
    params = {service: "https://archives.edu"}

    result = AspaceOauth.build_url(host, path, params)

    expected_url = "https://example.com/auth/saml/spslo?service=https%3A%2F%2Farchives.edu"
    assert_equal expected_url, result
  end

  def test_build_url_method_without_params
    host = "https://example.com"
    path = "/auth/saml/spslo"

    result = AspaceOauth.build_url(host, path)

    expected_url = "https://example.com/auth/saml/spslo"
    assert_equal expected_url, result
  end

  def test_get_info_returns_empty_hash_for_missing_info
    assert_equal({}, AspaceOauth.get_info(nil))
    assert_equal({}, AspaceOauth.get_info({}))
  end

  def test_get_extra_returns_empty_hash_for_missing_extra
    assert_equal({}, AspaceOauth.get_extra(nil))
    assert_equal({}, AspaceOauth.get_extra({}))
  end

  def test_get_email_returns_nil_for_missing_auth_hash_sections
    assert_nil AspaceOauth.get_email(nil)
    assert_nil AspaceOauth.get_email({})
  end

  def test_get_email_prefers_info_email
    auth = {
      info: {email: "info@example.com"},
      extra: {email: "extra@example.com"}
    }

    assert_equal "info@example.com", AspaceOauth.get_email(auth)
  end

  def test_get_email_falls_back_to_extra_and_response_object
    auth_with_extra = {
      info: {},
      extra: {email: "extra@example.com"}
    }
    auth_with_response_object = {
      info: {},
      extra: {response_object: ResponseObject.new("nameid@example.com")}
    }

    assert_equal "extra@example.com", AspaceOauth.get_email(auth_with_extra)
    assert_equal "nameid@example.com", AspaceOauth.get_email(auth_with_response_object)
  end

  def test_get_uid_handles_missing_auth
    assert_nil AspaceOauth.get_uid(nil)
    assert_nil AspaceOauth.get_uid({})
    assert_equal "abc123", AspaceOauth.get_uid({uid: "abc123"})
  end
end
