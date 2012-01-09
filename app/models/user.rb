class User < ActiveRecord::Base
# Connects this user object to Blacklights Bookmarks and Folders. 
 include Blacklight::User
  include Blacklight::User
  
  #
  # Does this user actually exist in the db?
  #
  def is_real?
    self.class.count(:conditions=>['id = ?',self.id]) == 1
  end
end
