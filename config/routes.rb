RailsI18nOnair::Engine.routes.draw do
  # Public routes - Authentication
  get "/login", to: "sessions#new", as: "login"
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: "logout"

  # Protected dashboard routes
  root "dashboard#index"

  # Database mode: Translation management
  resources :translations, only: [:index, :show, :new, :create, :edit, :update, :destroy]

  # File mode: Locale file management
  resources :locale_files, only: [:index, :show, :edit, :update], param: :filename do
    collection do
      post :sync
      post :reload
    end
  end
end
