Hypatia::Application.routes.draw do
  root :to => "catalog#index"

  Blacklight.add_routes(self)
  HydraHead.add_routes(self)
  match 'catalog/:id/edit_members' => "catalog#edit_members"
  match 'catalog/:id/update_members' => "catalog#update_members"
  # default routes
  match ':controller/:action/:id'
  match ':controller/:action/:id.:format'
  resources :users
  resources :user_sessions
end
