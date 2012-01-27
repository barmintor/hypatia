class UserSessionsController < ApplicationController
  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      redirect_to account_url
    else
      render :action => :new
    end
  end

  def destroy
    current_user_session.destroy
    redirect_to new_user_session_url
  end

  def superuser
    if session[:superuser_mode]
      session[:superuser_mode] = nil
    elsif current_user.can_be_superuser?
      session[:superuser_mode] = true
    end
    redirect_to :back
  end

end
