class SessionsController < ApplicationController
  # login
  def create
    # omniauth stores data in the request.env instead of params
    auth = request.env["omniauth.auth"]

    # even though this is a login action, an OAuth login can be a login *or* a registration
    #
    # if the user exists, log her in
    # if the user doesn't exist, create her, then log her in
    user =
      User.find_by(provider: auth['provider'], uid: auth['uid']) ||
      User.create_with_omniauth(auth)

    session[:user_id] = user.id
    redirect_to root_url, notice: "Signed in!"
  end

  # logout
  def destroy
    session[:user_id] = nil
    redirect_to root_url, notice: "Signed out!"
  end
end