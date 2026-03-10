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
  resources :locale_files, only: [:index, :show, :edit, :update], param: :locale do
    collection do
      post :sync
      post :reload
    end
  end

  # Sync Locales
  resources :sync_locales, only: [:new, :create], controller: "sync" do
    collection do
      post :preview
    end
  end

  # Download all translations as ZIP
  get "/download_all", to: "downloads#all", as: "download_all"

  # Settings
  get "/settings", to: "settings#index", as: "settings"
  patch "/settings", to: "settings#update"

  # Live UI API (called by the injected Live UI script in the host app)
  namespace :api do
    patch "/live_translations/:locale", to: "live_translations#update", as: "live_translation"
  end
end
