# frozen_string_literal: true

class OauthController < ApplicationController
  skip_before_action :unauthorised_access
  skip_before_action :verify_authenticity_token

  # IMPLEMENTS: /auth/:provider/callback
  # Successful authentication populates the auth_hash with user data. We encode
  # the data in a signed token, which we send to the backend as the user's
  # password. In the backend, our ASOauth authentication source verifies the
  # token, and creates a user from the data it contains.
  #
  # The token is JSON data, signed (using HMAC) with a secret shared between us
  # and the backend. Although communication between the frontend and backend is
  # assumed to be privileged, the password field can be user-specified in a
  # normal username-password login exchange, so signing the token ensures that a
  # user-provided password can't be used to forge oauth logins.
  def create
    backend_session = nil
    email = username+"@nyu.edu"
    username = auth_hash["extra"]["raw_info"]["urn:oid:0.9.2342.19200300.100.1.1"]

    puts "Received callback for user: #{username}" if AspaceOauth.debug?

    if email && username
      username = username.split("@").first unless AspaceOauth.username_is_email?
      auth_hash[:info][:username] = username.downcase # checked in backend
      auth_hash[:info][:email] = email # ensure email is set in info
      login_token = AspaceOauth.encode_user_login_token(auth_hash)
      puts "Generated token: #{login_token}" if AspaceOauth.debug?

      backend_session = User.login(username, login_token)
    end

    if backend_session
      User.establish_session(self, backend_session, username)
      load_repository_list
    else
      flash[:error] = "Authentication error, unable to login."
    end

    redirect_to controller: :welcome, action: :index
  end

  def failure
    flash[:error] = params[:message]
    redirect_to controller: :welcome, action: :index
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
    request.env["omniauth.auth"]
  end
end
