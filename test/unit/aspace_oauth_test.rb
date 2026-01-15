# frozen_string_literal: true

require_relative "../test_helper"

class AspaceOauthTest < Minitest::Test
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
end
