ActionController::Routing::Routes.draw do |map|
  
  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  map.login "/login", :controller=>'user_sessions',:action=>'new'
  map.resources :users
  map.resource :user_session

  map.update_benchmark "benchmark/update", :controller => 'benchmark',:action => 'update'
  map.benchmark "benchmark", :controller => 'benchmark',:action => 'show'

  map.root :controller => 'benchmark',:action => 'show'

end
