class User < ActiveRecord::Base
# Connects this user object to Blacklights Bookmarks and Folders. 
 include Blacklight::User
 include Hydra::User
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :encryptable,
         :authentication_keys => [:login]

  # Setup accessible (or protected) attributes for your model
  attr_accessible :login, :email, :password, :password_confirmation, :remember_me

  validates_uniqueness_of :login, :email, :case_sensitive => false

  def login
    read_attribute(:login).to_s
  end

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account. 
  def to_s
    email
  end

  protected
  def self.find_for_database_authentication(conditions)
    value = conditions.dup.delete(:login)
    value = value.strip.downcase
    where(["lower(login) = :value OR lower(email) = :value", {:value => value}]).first
  end
end
