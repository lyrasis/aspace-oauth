# frozen_string_literal: true

require "date"

module AspaceOauth
  # Auth hash extraction
  def self.get_auth_section(auth, section)
    return {} unless auth.respond_to?(:[])

    value = auth[section] || auth[section.to_s]
    value.is_a?(Hash) ? value : {}
  end

  def self.get_info(auth)
    get_auth_section(auth, :info)
  end

  def self.get_extra(auth)
    get_auth_section(auth, :extra)
  end

  def self.get_email(auth)
    info = get_info(auth)
    extra = get_extra(auth)
    email = info[:email] || info["email"]
    email = extra[:email] || extra["email"] if email.nil?

    if email.nil?
      response_object = extra[:response_object] || extra["response_object"]
      email = response_object.name_id if response_object&.respond_to?(:name_id) && response_object.name_id
    end

    email
  end

  def self.get_uid(auth)
    return unless auth

    return auth.uid if auth.respond_to?(:uid)
    return unless auth.respond_to?(:[])

    auth[:uid] || auth["uid"]
  end

  # Provider config and URL helpers
  def self.get_oauth_config_for(strategy)
    AppConfig[:oauth_definitions].find { |oauth| oauth[:provider] == strategy }
  end

  def self.build_url(host, path, params = {})
    URI::HTTPS.build(
      host: URI(host).host,
      path: path,
      query: params.any? ? URI.encode_www_form(params) : nil
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

  def self.saml_logout_url
    config = get_oauth_config_for("saml")
    return unless config

    host = config[:config][:idp_slo_service_url]

    if host && !host.empty?
      host.to_s
    else
      build_url(
        AppConfig[:frontend_proxy_url],
        "#{AppConfig[:frontend_proxy_prefix]}auth/saml/spslo"
      )
    end
  end

  # Feature and config flags
  def self.debug?
    AppConfig.has_key?(:oauth_debug) && AppConfig[:oauth_debug] == true
  end

  def self.use_uid?
    AppConfig.has_key?(:oauth_idtype) && AppConfig[:oauth_idtype] == :uid
  end

  def self.username_is_email?
    AppConfig.has_key?(:oauth_username_is_email) && AppConfig[:oauth_username_is_email] == true
  end

  # Shared secret and token signing
  def self.get_oauth_shared_secret
    secret = AppConfig[:oauth_shared_secret] if AppConfig.has_key? :oauth_shared_secret

    raise ":oauth_shared_secret config option is not set" unless secret.is_a?(String) && (secret.length > 0)

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
