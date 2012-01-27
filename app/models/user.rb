class User < ActiveRecord::Base
  include Blacklight::User
  include Hydra::User
  acts_as_authentic do |c|
  end

  validates_presence_of :email
  validates_uniqueness_of :email

  validates_presence_of :password, :on => :create
  validates_confirmation_of :password
  
  validates_presence_of :login
  validates_uniqueness_of :login
  #
  # Does this user actually exist in the db?
  #
  def is_real?
    self.class.count(:conditions=>['id = ?',self.id]) == 1
  end
end
