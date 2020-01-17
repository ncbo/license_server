Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root :to => 'license_server#index'

  resources :license_server
  resources :login
  resources :licenses

  # User
  get '/logout' => 'login#destroy', :as => :logout
  get '/login_as/:login_as' => 'login#login_as'


end
