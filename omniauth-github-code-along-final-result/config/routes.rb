Rails.application.routes.draw do

root 'users#new'
get 'users/new'

get 'auth/:provider/callback' => 'sessions#create'
get 'auth/github', as: 'github_login'

get 'logout' => 'sessions#destroy'
end