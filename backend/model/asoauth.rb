# frozen_string_literal: true

class ASOauthException < StandardError
end

class InvalidLoginTokenException < ASOauthException
end

class ASOauth
  include JSONModel

  def initialize(definition)
    @provider = definition[:provider]
  end

  def name
    "ArchivesSpace Oauth - #{@provider}"
  end

  # For Oauth authentication has already happened
  # via the frontend. As part of that process a
  # file is written to the system tmpdir and the
  # filename is provided as the "password".
  # The file and contents are checked to verify the user.
  def authenticate(username, password)
    begin
      info = validate_login_token_and_extract_user_info(password)
    rescue InvalidLoginTokenException => e
      Log.warn("ASOauth: rejected authentication with invalid login token: #{e}")
      return nil
    end

    return nil unless username == info['username'].downcase

    JSONModel(:user).from_hash(
      username: username,
      name: info['name'],
      email: info['email'],
      first_name: info['first_name'],
      last_name: info['last_name'],
      telephone: info['phone'],
      additional_contact: info['description']
    )
  end

  def get_oauth_shared_secret
    if AppConfig.has_key? :oauth_shared_secret
      secret = AppConfig[:oauth_shared_secret]
    else
      # When a value for oauth_shared_secret isn't explicitly configured, the
      # frontend generates a value which it saves in a JVM system property. When
      # the frontend and backend are running in the same JVM (which is the
      # default) we can pick up the generated value.
      secret = java.lang.System.get_property("aspace.config.oauth_shared_secret")
      unless secret.nil?
        AppConfig[:oauth_shared_secret] = secret
      end
    end

    unless secret.is_a? String and secret.length > 0
      raise ASOauthException.new(":oauth_shared_secret config option is not set")
    end
    secret
  end

  def validate_login_token_and_extract_user_info(login_token)
    begin
      unverified_token = JSON.parse(login_token)
    rescue JSON::ParserError => e
      raise InvalidLoginTokenException.new("login_token is not valid JSON")
    end

    signature = unverified_token["signature"] if unverified_token.is_a? Hash
    json_payload = unverified_token["payload"] if unverified_token.is_a? Hash

    unless signature.is_a? String and json_payload.is_a? String
      raise InvalidLoginTokenException.new("login_token content is invalid")
      return nil
    end

    secret = get_oauth_shared_secret
    expected_signature = OpenSSL::HMAC.hexdigest("SHA256", secret, json_payload)
    unless Rack::Utils.secure_compare(expected_signature, signature)
      raise InvalidLoginTokenException.new(
        "login_token signature does not match the signature expected by our oauth_shared_secret"
      )
    end

    begin
      payload = JSON.parse(json_payload)
    rescue JSON::ParserError => e
      raise InvalidLoginTokenException.new("login_token payload is not valid JSON")
    end

    unless payload["created_by"] == "aspace-oauth-#{@provider}"
      raise InvalidLoginTokenException.new("rejected login_token from unexpected provider")
    end

    begin
      created_at = DateTime.rfc3339(payload["created_at"])
    rescue ArgumentError
      raise InvalidLoginTokenException.new("login_token's created_at is not a rfc3339 date-time")
    end
    delta_seconds = ((DateTime.now - created_at).abs * 24 * 60 * 60).to_f
    unless delta_seconds <= 60
      raise InvalidLoginTokenException.new(
        "login_token's created_at is not within 60 seconds of current time"
      )
    end

    user_info = payload["user_info"]
    unless user_info.is_a? Hash and user_info.has_key? "username"
      raise InvalidLoginTokenException.new(
        "login_token's payload user_info is invalid"
      )
    end
    user_info
  end

  def matching_usernames(query)
    DB.open do |db|
      query = query.gsub(/[%]/, '').downcase
      db[:user]
        .filter(Sequel.~(is_system_user: 1))
        .filter(Sequel.like(
                  Sequel.function(:lower, :username), "#{query}%"
                ))
        .filter(Sequel.like(:source, name))
        .select(:username)
        .limit(AppConfig[:max_usernames_per_source].to_i)
        .map { |row| row[:username] }
    end
  end
end
