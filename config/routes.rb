Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root :to => 'license_server#index'

  resources :license_server
  resources :login

  resources :licenses do
    post :approve, on: :member
    post :disapprove, on: :member
    post :renew, on: :member
  end

  # User
  get '/logout' => 'login#destroy', :as => :logout
  get '/login_as/:login_as' => 'login#login_as'
end
