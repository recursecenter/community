Rails.application.routes.draw do
  root 'pages#index'

  resources :sessions
  get 'login' => 'sessions#new'
  get 'logout' => 'sessions#destroy'
  get 'login/complete' => 'sessions#complete'

  # client side routes
  get '/settings' => 'pages#index'
  get '/f/*path' => 'pages#index'
  get '/t/:slug/:id' => 'pages#index', as: 'thread'
  get '/t/:slug/:thread_id/:post_number' => 'pages#index', as: 'post'
  get '/s' => 'pages#index'
  get '/s/*query' => 'pages#index', as: 'search'

  get '/threads/:id/unsubscribe' => 'threads#unsubscribe', as: :unsubscribe_thread
  get '/threads/:id/subscribe' => 'threads#subscribe', as: :subscribe_thread

  # sudo for development only
  namespace :admin do
    if Rails.env.development?
      get 'su' => 'su#index'
      post 'su' => 'su#create'
    end
  end

  namespace :api, format: false, defaults: {format: 'json'} do
    post 'welcome_message/read' => 'welcome_messages#read'
    get 'search' => 'search#query'
    get 'suggestions' => 'search#suggestions'

    resources :users do
      get :me, on: :collection
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
end
