Foo::Application.routes.draw do
  root to: 'home#index'

  get '/about' => 'pages#about'

  resources :users
  resource :profile
end
