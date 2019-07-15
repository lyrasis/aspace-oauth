class OauthController < ApplicationController
  skip_before_action :unauthorised_access
  skip_before_action :verify_authenticity_token

  # IMPLEMENTS: /auth/:provider/callback
  # Successful authentication populates the auth_hash with data
  # that is written to the system tmpdir. This is used to verify
  # the user for the backend and then deleted.
  def create
    id      = "aspace-oauth-#{auth_hash[:provider]}-#{SecureRandom.uuid}"
    id_path = File.join(Dir.tmpdir, id)
    puts "Received callback for: #{id}"
    backend_session = nil

    email = get_email auth_hash
    if email
      # ensure this is set regardless of how, required by the backend
      auth_hash[:info][:email] ||= email
      File.open(id_path, 'w') { |f| f.write(JSON.generate(auth_hash)) }

      # usernames cannot be email addresses
      username        = email.split('@')[0]
      backend_session = User.login(username, id)
    end

    if backend_session
      User.establish_session(self, backend_session, username)
      load_repository_list
    else
      flash[:error] = "Authentication error, unable to login."
    end

    File.delete id_path if File.exists? id_path
    redirect_to :controller => :welcome, :action => :index
  end

  def failure
    flash[:error] = params[:message]
    redirect_to :controller => :welcome, :action => :index
  end

  def cas_logout
    reset_session
    redirect_to AspaceOauth.cas_logout_url
  end

  def saml_logout
    reset_session
    redirect_to AspaceOauth.saml_logout_url
  end

  protected

  def auth_hash
    request.env['omniauth.auth']
  end

  def get_email(auth)
    email = nil
    if auth[:info].has_key?(:email) and !auth[:info][:email].nil?
      email = auth[:info][:email]
    elsif auth[:extra].has_key?(:email) and !auth[:extra][:email].nil?
      email = auth[:extra][:email]
    elsif auth[:extra].has_key?(:response_object)
      if auth[:extra][:response_object].name_id
        email = auth[:extra][:response_object].name_id
      end
    end
    email
  end

end
