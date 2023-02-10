Rails.application.routes.draw do
  root 'pages#index'

  get 'nope', to: 'pages#nope'
  get 'threadlist', to: 'pages#threadlist'

  resources :sessions
  get 'login', to: 'sessions#new'
  get 'logout', to: 'sessions#destroy'
  get 'login/complete', to: 'sessions#complete'

  # client side routes
  get '/settings', to: 'pages#index'
  get '/f/*path', to: 'pages#index'
  get '/t/:slug/:id', to: 'pages#index', as: 'thread'
  get '/t/:slug/:thread_id/:post_number', to: 'pages#index', as: 'post'
  get '/s', to: 'pages#index'
  get '/s/:query', to: 'pages#index'

  get '/threads/:id/unsubscribe', to: 'threads#unsubscribe', as: :unsubscribe_thread
  get '/threads/:id/subscribe', to: 'threads#subscribe', as: :subscribe_thread
  get '/threads/unsubscribe/:token', to: 'threads#unsubscribe_with_reply_info'
  get '/threads/subscribe/:token', to: 'threads#subscribe_with_reply_info'

  # sudo for development only
  namespace :admin do
    if Rails.env.development?
      get 'su', to: 'su#index'
      post 'su', to: 'su#create'
    end
  end

  namespace :api, format: false, defaults: {format: 'json'} do
    post 'welcome_message/read', to: 'welcome_messages#read'
    get 'search', to: 'search#search'
    get 'suggestions', to: 'search#suggestions'

    resources :users do
      get :me, on: :collection
      post :deactivate, on: :collection
    end

    resources :notifications do
      post :read, on: :collection
    end

    resource :settings

    shallow do
      resources :subforum_groups do
        resources :subforums do
          post :subscribe, on: :member
          post :unsubscribe, on: :member

          resources :threads do
            post :subscribe, on: :member
            post :unsubscribe, on: :member
            post :pin, on: :member
            post :unpin, on: :member
            resources :posts
          end
        end
      end
    end

    namespace :private do
      post :reply, to: 'email_webhooks#reply'
      post :opened, to: 'email_webhooks#opened'
    end
  end
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
