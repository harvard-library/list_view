class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  private

  def authenticate_login!
    if !user_signed_in?
      redirect_to('/users/sign_in')
    end
  end
end
