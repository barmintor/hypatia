# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller 
   include Blacklight::Controller
  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 

  include Blacklight::Controller
  include Hydra::Controller
  include HydraHead::Controller
  helper :all # include all helpers, all the time
  before_filter :inject_assets
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  def current_user_session
    user_session
  end

  def layout_name
    'application'
  end

  protected
  
  def inject_assets
    stylesheet_links << ["http://fonts.googleapis.com/css?family=Copse|Open+Sans:300,400,600|Lato:700", "hypatia", {:media=>"all"}]
    javascript_includes << ["hypatia"]
  end
end
