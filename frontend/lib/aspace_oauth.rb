module AspaceOauth

  def self.cas_logout_url
    config = get_oauth_cas_config
    return unless config
    params = { service: AppConfig[:frontend_proxy_url] }
    URI::HTTPS.build(
      host: config[:config][:url].gsub(/https?:\/\//, ''),
      path: config[:config][:logout_url],
      query: URI.encode_www_form(params)
    ).to_s
  end

  def self.get_oauth_cas_config
    AppConfig[:oauth_definitions].find { |oauth| oauth[:provider] == 'cas' }
  end

end
