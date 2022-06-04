Rails.application.routes.draw do


  # Set Project Root Directory #
  root 'static_pages#home'

  # Set Project Base Pages #
  get 'about',     to: 'static_pages#about'
  get 'contact',   to: 'static_pages#contact'

  # Set User Directories #
  get    'signup',   to: 'users#new'
  get    '/login',   to: 'sessions#new'
  post   '/login',   to: 'sessions#create'
  delete '/logout',  to: 'sessions#destroy'
  get    'admin',    to: 'users#admin'
  get    'agency-information',   to: 'users#agency_information'
  post   'update-agency-information', to: 'users#rails_settings_setting_user', as: 'rails_settings_setting_user'
  patch   'update-agency-information', to: 'users#rails_settings_setting_user'

  # Set Project Resources #
  resources :users
  resources :submissions
  resources :business_infos
  get 'classcode/search', to: 'business_infos#search'

  post 'form-type', to: "submissions#form_type"
end
