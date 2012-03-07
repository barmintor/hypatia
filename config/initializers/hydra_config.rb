require "hydra"
# The following lines determine which user attributes your hydrangea app will use
# This configuration allows you to use the out of the box ActiveRecord associations between users and user_attributes
# It also allows you to specify your own user attributes
# The easiest way to override these methods would be to create your own module to include in User
# For example you could create a module for your local LDAP instance called MyLocalLDAPUserAttributes:
#   User.send(:include, MyLocalLDAPAttributes)
# As long as your module includes methods for full_name, affiliation, and photo the personalization_helper should function correctly
#
# NOTE: For your development environment, also specify the module in lib/user_attributes_loader.rb
User.send(:include, Hydra::GenericUserAttributes)
# 

if Hydra.respond_to?(:configure)
  Hydra.configure(:shared) do |config|
  
    config[:file_asset_types] = {
      :default => FileAsset, 
      :extension_mappings => {
        AudioAsset => [".wav", ".mp3", ".aiff"] ,
        VideoAsset => [".mov", ".flv", ".mp4", ".m4v"] ,
        ImageAsset => [".jpeg", ".jpg", ".gif", ".png"] 
      }
    }
    config[:submission_workflow] = {
        :hypatia_collections        => [{:name => "description",     :edit_partial => "hypatia_collections/description_form",      :show_partial => "hypatia_collections/show_description"},
                                        {:name => "files",           :edit_partial => "file_assets/file_assets_form",              :show_partial => "shared/show_files"},
                                        {:name => "technical_info",  :edit_partial => "hypatia_collections/technical_form",        :show_partial => "hypatia_collections/show_technical"},
                                        {:name => "permissions",     :edit_partial => "permissions/permissions_form",              :show_partial => "shared/show_permissions"}
                                       ],        
        :hypatia_ftk_items          => [{:name => "description",     :edit_partial => "hypatia_ftk_items/description_form",        :show_partial => "hypatia_ftk_items/show_description"},
                                        {:name => "files",           :edit_partial => "file_assets/file_assets_form",              :show_partial => "hypatia_ftk_items/show_files"},
                                        {:name => "technical_info",  :edit_partial => "hypatia_ftk_items/tech_info_form",          :show_partial => "hypatia_ftk_items/show_technical"},
                                        {:name => "permissions",     :edit_partial => "permissions/permissions_form",              :show_partial => "shared/show_permissions"}
                                      ],
        :hypatia_disk_image_items   => [{:name => "description",     :edit_partial => "hypatia_disk_image_items/description_form", :show_partial => "hypatia_disk_image_items/show_description"},
                                        {:name => "files",           :edit_partial => "file_assets/file_assets_form",              :show_partial => "shared/show_files"},
                                        {:name => "technical_info",  :edit_partial => "hypatia_disk_image_items/technical_form",   :show_partial => "hypatia_disk_image_items/show_technical"},
                                        {:name => "permissions",     :edit_partial => "permissions/permissions_form",              :show_partial => "shared/show_permissions"}
                                       ],
        :hypatia_sets               => [{:name => "description",     :edit_partial => "hypatia_sets/description_form",             :show_partial => "hypatia_sets/show_description"},
                                        {:name => "files",           :edit_partial => "file_assets/file_assets_form",              :show_partial => "shared/show_files"},
                                        {:name => "permissions",     :edit_partial => "permissions/permissions_form",              :show_partial => "shared/show_permissions"}
                                       ]
      }
      config[:permissions] = {
            :catchall => "access_t",
            :discover => {:group =>"discover_access_group_t", :individual=>"discover_access_person_t"},
            :read => {:group =>"read_access_group_t", :individual=>"read_access_person_t"},
            :edit => {:group =>"edit_access_group_t", :individual=>"edit_access_person_t"},
            :edit_members => {:group =>"edit_access_group_t", :individual=>"edit_access_person_t"},
            :owner => "depositor_t",
            :embargo_release_date => "embargo_release_date_dt"
          }
      # configure the local models and their workflows
      bag_steps = []
      bag_steps << {:name => "description", :edit_partial => "bag_aggregators/description_form", :show_partial => "bag_aggregators/show_description"}
      bag_steps << {:name => "permissions",     :edit_partial => "permissions/permissions_form", :show_partial => "shared/show_permissions"}
      static_image_steps = []
      static_image_steps << {:name => "description", :edit_partial => "static_image_aggregators/description_form", :show_partial => "static_image_aggregators/show_description"}
      static_image_steps << {:name => "files", :edit_partial => "shared/edit_resources", :show_partial => "shared/show_files"}
      static_image_steps << {:name => "permissions",     :edit_partial => "permissions/permissions_form", :show_partial => "shared/show_permissions"}
      content_steps = []
      content_steps << {:name => "description", :edit_partial => "content_aggregators/description_form", :show_partial => "content_aggregators/show_description"}
      content_steps << {:name => "permissions",     :edit_partial => "permissions/permissions_form", :show_partial => "shared/show_permissions"}
      resource_steps = []
      resource_steps << {:name => "description", :edit_partial => "resources/description_form", :show_partial => "resources/show_description"}
      resource_steps << {:name => "content", :edit_partial => "resources/replace", :show_partial => "resources/show_content"}
      resource_steps << {:name => "permissions",     :edit_partial => "permissions/permissions_form", :show_partial => "shared/show_permissions"}
      config[:submission_workflow][:bag_aggregators] = bag_steps
      config[:submission_workflow][:content_aggregators] = content_steps
      config[:submission_workflow][:static_image_aggregators] = static_image_steps
      config[:submission_workflow][:resources] = resource_steps
      
  end
end
