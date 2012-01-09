class UserSessionsController < ApplicationController
  unloadable
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => :destroy

  def new
    current_user_session.destroy if current_user_session
    @user_session = UserSession.new
    params[:login_with_wind] = true if UserSession.login_only_with_wind
    session[:return_to] = params[:return_to] || root_url
    @user_session.save 
  end

 
  def create
    @user_session = UserSession.new(params[:user_session])
    @user_session.save do |result|  
      if result  
        session[:return_to] = nil if session[:return_to].to_s.include?("logout")
        redirect_back_or_default root_url  
      else  
        flash[:error] = "Unsuccessfully logged in."
        redirect_to catalog_index_url
        return
      end  
    end
    
  end
  
  def destroy
    current_user_session.destroy
    redirect_to catalog_index_url
  end

  # toggle to set superuser_mode in session
  # Only allows user who can be superusers to set this value in session
  def superuser
    if session[:superuser_mode]
      session[:superuser_mode] = nil
    elsif current_user.can_be_superuser?
      session[:superuser_mode] = true
    end
    redirect_to :back
  end
end
