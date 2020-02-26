# frozen_string_literal: true

class ASOauthException < StandardError
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
    return nil unless password.start_with?("aspace-oauth-#{@provider}")

    pw_path = File.join(Dir.tmpdir, password)
    return nil unless File.exist? pw_path

    info = JSON.parse(File.read(pw_path))['info']
    return nil unless username == info['username']

    JSONModel(:user).from_hash(
      username: username,
      name: info['name'],
      email: info['email']
    )
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
