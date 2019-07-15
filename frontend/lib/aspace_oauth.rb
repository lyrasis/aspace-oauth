module AspaceOauth

  def self.cas_logout_url
    config = get_oauth_config_for('cas')
    return unless config
    host   = config[:config][:url]
    path   = config[:config][:logout_url]
    params = { service: AppConfig[:frontend_proxy_url] }
    build_url(host, path, params)
  end

  def self.saml_logout_url
    config = get_oauth_config_for('saml')
    return unless config
    build_url(
      AppConfig[:frontend_proxy_url],
      "#{AppConfig[:frontend_proxy_prefix]}auth/saml/spslo"
    )
  end

  def self.build_url(host, path, params = {})
    URI::HTTPS.build(
      host: URI(host).host,
      path: path,
      query: URI.encode_www_form(params)
    ).to_s
  end

  def self.get_oauth_config_for(strategy)
    AppConfig[:oauth_definitions].find { |oauth| oauth[:provider] == strategy }
  end

end
