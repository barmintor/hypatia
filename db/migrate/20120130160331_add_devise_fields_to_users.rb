class AddDeviseFieldsToUsers < ActiveRecord::Migration
  def self.up
    rename_column :users, :crypted_password, :encrypted_password
    rename_column :users, :current_login_at, :current_sign_in_at
    rename_column :users, :last_login_at, :last_sign_in_at
    
    remove_column :users, :persistence_token
    remove_column :users, :perishable_token
    
    add_column :users, :unlock_token, :string, :limit => 255
    add_column :users, :failed_attempts, :integer, :default => 0
    add_column :users, :locked_at, :timestamp
    add_column :users, :sign_in_count, :integer, :default => 0
    add_column :users, :reset_password_token, :string, :limit => 255
    add_column :users, :remember_token, :string, :limit => 255
    add_column :users, :remember_created_at, :timestamp
    add_column :users, :current_sign_in_ip, :string
    add_column :users, :last_sign_in_ip, :string
    add_column :users, :authentication_token, :string
    
    add_index :users, :email,                :unique => true
    add_index :users, :reset_password_token, :unique => true
    add_index :users, :unlock_token,         :unique => true
    add_index :users, :authentication_token, :unique => true
  end

  def self.down
    
    remove_column :users, :unlock_token
    remove_column :users, :failed_attempts
    remove_column :users, :locked_at
    remove_column :users, :sign_in_count
    remove_column :users, :reset_password_token
    remove_column :users, :remember_token
    remove_column :users, :remember_created_at
    remove_column :users, :current_sign_in_ip
    remove_column :users, :last_sign_in_ip
    remove_column :users, :authentication_token

    add_column :users, :persistence_token, :string
    add_column :users, :perishable_token, :string
    
    rename_column :users, :encrypted_password, :crypted_password   
    rename_column :users, :current_sign_in_at, :current_login_at
    rename_column :users, :last_sign_in_at, :last_login_at
  end
end
