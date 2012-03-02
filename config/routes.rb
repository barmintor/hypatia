Hypatia::Application.routes.draw do
  root :to => "catalog#index"
  #devise_for :users, :controllers => {:sessions => 'sessions'}

  Blacklight.add_routes(self)
  HydraHead.add_routes(self)
  DeviseWind.add_routes(self)
  resources :users, :only => :show
  resources :resources
  match 'catalog/:id/edit' => "catalog#edit", :as => 'catalog_edit'
  match 'catalog/:id/edit_members' => "catalog#edit_members", :as => 'catalog_edit_members'
  match 'catalog/:id/update_members' => "catalog#update_members", :as => 'catalog_update_members'
  match 'assets/:asset_id/downloads' => "assets#download"

  # default routes
  match ':controller/:action/:id'
  match ':controller/:action/:id.:format'
end
