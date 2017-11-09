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
    File.open(id_path, 'w') { |f| f.write(JSON.generate(auth_hash)) }

    backend_session = User.login(auth_hash[:info][:name], id)

    if backend_session
      User.establish_session(self, backend_session, auth_hash[:info][:name])
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

  protected

  def auth_hash
    request.env['omniauth.auth']
  end

end