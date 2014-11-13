Foo::Application.routes.draw do
  root to: 'home#index'

  get '/about' => 'pages#about'

  resources :users do
    collection do
      get :example
    end
  end

  resource :profile do
    member do
      get :sync
    end
  end
end
