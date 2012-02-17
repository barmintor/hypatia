class User < ActiveRecord::Base
# Connects this user object to Blacklights Bookmarks and Folders. 
 include Blacklight::User
 include Hydra::User
 include Devise::Models::DatabaseAuthenticatable # this is a hack for encryptable to work
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :wind_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :encryptable,
         :authentication_keys => [:login]
  wind_host "wind.columbia.edu"
  wind_service "culscv"
  # Setup accessible (or protected) attributes for your model
  attr_accessible :login, :email, :password, :password_confirmation, :remember_me

  validates_uniqueness_of :login, :email, :case_sensitive => false

  before_validation(:default_email, :on => :create) 
  before_validation(:generate_password, :on => :create) 
  before_create :set_personal_info_via_ldap
  
  def last_login_at
    read_attribute(:last_sign_in_at).to_s
  end
  
  def current_login_at
    read_attribute(:current_sign_in_at).to_s
  end

  def login
    read_attribute(:login).to_s
  end

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account. 
  def to_s
    email
  end
  
  def default_email
    login = self.send User.wind_login_field
    mail = "#{login}@columbia.edu"
    self.email = mail
  end
  
  def generate_password
    self.password = ActiveSupport::SecureRandom.base64(8)
  end
  
  def set_personal_info_via_ldap
    if wind_login
      entry = Net::LDAP.new({:host => "ldap.columbia.edu", :port => 389}).search(:base => "o=Columbia University, c=US", :filter => Net::LDAP::Filter.eq("uid", wind_login)) || []
      entry = entry.first

      if entry
        _mail = entry[:mail].to_s
        if _mail.length > 6 and _mail.match(/^[\w.]+[@][\w.]+$/)
          self.email = _mail
        else
          self.email = wind_login + '@columbia.edu'
        end
        if User.column_names.include? :last_name
          self.last_name = entry[:sn].to_s
        end
        if User.column_names.include? :first_name
          self.first_name = entry[:givenname].to_s
        end
      end
    end

    return self
  end

  protected
  def self.find_for_database_authentication(conditions)
    value = conditions.dup.delete(:login)
    value = value.strip.downcase
    where(["lower(login) = :value OR lower(email) = :value", {:value => value}]).first
  end
end
