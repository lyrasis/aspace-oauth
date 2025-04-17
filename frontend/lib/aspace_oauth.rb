# frozen_string_literal: true

require "date"

module AspaceOauth
  def self.build_url(host, path, params = {})
    URI::HTTPS.build(
      host: URI(host).host,
      path: path,
      query: URI.encode_www_form(params)
    ).to_s
  end

  def self.cas_logout_url
    config = get_oauth_config_for("cas")
    return unless config

    host = config[:config][:url]
    path = config[:config][:logout_url]
    params = {service: AppConfig[:frontend_proxy_url]}
    build_url(host, path, params)
  end

  def self.debug?
    AppConfig.has_key?(:oauth_debug) && AppConfig[:oauth_debug] == true
  end

  def self.get_email(auth)
    email = nil
    if auth[:info].key?(:email) && !auth[:info][:email].nil?
      email = auth[:info][:email]
    elsif auth[:extra].key?(:email) && !auth[:extra][:email].nil?
      email = auth[:extra][:email]
    elsif auth[:extra].key?(:response_object)
      if auth[:extra][:response_object].name_id
        email = auth[:extra][:response_object].name_id
      end
    end
    email
  end

  def self.get_oauth_config_for(strategy)
    AppConfig[:oauth_definitions].find { |oauth| oauth[:provider] == strategy }
  end



  def self.saml_logout_url
    config = get_oauth_config_for("saml")
    return unless config

    host = config[:config][:idp_slo_service_url]

    if host
      host.to_s
    else
      build_url(
        AppConfig[:frontend_proxy_url],
        "#{AppConfig[:frontend_proxy_prefix]}auth/saml/spslo"
      )
    end
  end

  def self.use_uid?
    AppConfig.has_key?(:oauth_idtype) && AppConfig[:oauth_idtype] == :uid
  end

  def self.username_is_email?
    AppConfig.has_key?(:oauth_username_is_email) && AppConfig[:oauth_username_is_email] == true
  end

  def self.get_oauth_shared_secret
    secret = AppConfig[:oauth_shared_secret] if AppConfig.has_key? :oauth_shared_secret

    if !(secret.is_a?(String) && (secret.length > 0))
      raise ":oauth_shared_secret config option is not set"
    end

    secret
  end

  def self.encode_user_login_token(auth_hash)
    payload = JSON.generate({
      created_by: "aspace-oauth-#{auth_hash[:provider]}",
      created_at: DateTime.now.rfc3339,
      user_info: auth_hash[:info]
    })
    signature = OpenSSL::HMAC.hexdigest("SHA256", get_oauth_shared_secret, payload)
    JSON.generate({signature: signature, payload: payload})
  end
end
