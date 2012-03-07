module Hydra::AccessControlsEvaluation
#  class << self
    alias_method :old_test_permission, :test_permission
    
    def test_permission(permission_type)    
      # if !current_user.nil?
      if (@permissions_solr_document == nil)
        logger.warn("SolrDocument is nil")
      end

      if current_user.nil? 
        user = "public"
        user_groups = []
        logger.debug("current_user is nil, assigning public")
      else
        user = user_key
        user_groups = current_user.groups
      end

      # everyone is automatically a member of the group 'public'
      user_groups.push 'public' unless user_groups.include?('public')
      # logged-in users are automatically members of the group "registered"
      user_groups.push 'registered' unless (user == "public" || user_groups.include?('registered') )

      logger.debug("User #{user} is a member of groups: #{user_groups.inspect}")
      case permission_type
        when :edit
          logger.debug("Checking edit permissions for user: #{user}")
          group_intersection = user_groups & edit_groups
          result = !group_intersection.empty? || edit_persons.include?(user)
        when :read
          logger.debug("Checking read permissions for user: #{user}")
          group_intersection = user_groups & read_groups
          result = !group_intersection.empty? || read_persons.include?(user)
        else
          result = false
      end
      logger.debug("test_permission result: #{result}")
      return result
      # else
      #   logger.debug("nil user, test_permission returning false")
      #   return false
      # end
    end
#  end
end