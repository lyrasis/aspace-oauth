class ASOauthException < StandardError
end

class ASOauth

  include JSONModel

  def initialize(definition)
    @config   = definition[:config]
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

    id_path = File.join(Dir.tmpdir, password)
    return nil unless File.exists? id_path

    user = JSON.parse(File.read(id_path))["info"]
    # username param is downcased internally
    return nil unless username == user["name"].downcase

    user_data = {
      username: username,
      name:     user["name"]
    }
    user_data[:email] = user["email"] if user.has_key? "email"

    JSONModel(:user).from_hash(user_data)
  end

end