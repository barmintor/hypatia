# just grabbing a bunch of useful step definitions from hydra-head plugin
HydraHead::Engine.paths["test_support/features/step_definitions"].each do p
  require p unless p.nil?
end
# require "test_support/features/step_definitions/html_validity_steps"
# require "test_support/features/step_definitions/user_steps"
# require "test_support/features/step_definitions/show_document_steps"

Given /I am logged in as the "(.*)" user/ do |login|
  email = "#{login}@#{login}.com"
  # Given %{a User exists with a Login of "#{login}"}
  user = User.create(:login => login, :email => email, :password => "password", :password_confirmation => "password")
  User.find_by_login(login).should_not be_nil
  visit destroy_user_session_path
  visit new_user_session_path
  fill_in "Login", :with => login
  fill_in "Password", :with => "password"
  click_button "Login"
  Then %{I should see "#{login}"} 
  And %{I should see "Log Out"} 
end
