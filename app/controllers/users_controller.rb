class UsersController < ApplicationController
  helper :hydra_fedora_metadata
  helper :generic_content_objects
  helper :hydra_uploader
  helper :article_metadata
  before_filter :store_bounce
  before_filter :set_x_ua_compat
  before_filter :load_css
  before_filter :load_js
  before_filter :check_scripts
  before_filter :verify_user, :only => :show # can't show without a logged in user
  def show
  end
  
  def new
    @user ||= User.new(params[:user])
  end
  
  def create
    @user ||= User.new(params[:user])
    if @user.save
      flash[:notice] = "Welcome #{@user.login}"
      redirect_to user_path(@user.id)
    else
      render :action => "new"
    end    
  end
          
  protected
  def verify_user
    flash[:notice] = "Please log in to view your profile." and raise Blacklight::Exceptions::AccessDenied  unless current_user
  end
  
    def store_bounce 
      session[:bounce]=params[:bounce]
    end

    def check_scripts
      session[:scripts] ||= (params[:combined] and params[:combined] == "true")
    end

    #
    # These are all setting view stuff in the style of Rails2 Blacklight.  
    # Current versions of Blacklight have pushed this stuff back out of the controllers and into views.
    #
    def set_x_ua_compat
      # Always force latest IE rendering engine & Chrome Frame through header information.
      response.headers["X-UA-Compatible"] = "IE=edge,chrome=1"
    end

    def load_css
      stylesheet_links << ["hydra/html_refactor", {:media=>"all"}]
    end

    def load_js
      # This JS file implementes Blacklight's JavaScript framework and simply assigns all of the Blacklight provided JS functionality to empty functions.
      # We can use this file in the future, however we will want to implement a jQuery plugin architecture as we actually add in JS functionality.
      javascript_includes << ["hydra/hydra-head"]
      javascript_includes << ['jquery.form.js']
      javascript_includes << ['spin.min.js' ]
    end
  
end
