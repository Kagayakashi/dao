Rails.application.routes.draw do
  scope "(:locale)", locale: /en|ru/ do
    root "cultivation#show"
    get "cultivation/panel" => "cultivation#panel", as: :cultivation_panel
    post "cultivation/breakthrough" => "cultivation#breakthrough", as: :cultivation_breakthrough
    resource :temple, only: :show, controller: :temples do
      post :pray
    end
    resource :leaderboard, only: :show
    resource :inventory, only: :show
    resources :events, only: :index
    resource :artifact_refinement, only: :show do
      post :reroll
    end
    resource :adventure, only: :show
    resource :spirit_expedition, only: %i[ show create ]
    resources :news, only: %i[ index show ] do
      collection do
        post :read_all
      end
    end
    resource :sparring, only: %i[ show create ], controller: :sparring do
      post :change_opponent
    end
    resources :characters, only: :show
    resources :inventory_items, only: :destroy do
      member do
        post :equip
        post :unequip
      end
    end
    resources :users, only: %i[ new create ]
    resource :registration_completion, only: %i[ new create ]

    namespace :admin do
      root "dashboard#show"
      resource :session, only: %i[ new create destroy ]
      resources :items, only: %i[ new create ]
      resources :news_posts, except: :show
      resource :qi_adjustment, only: %i[ new create ]
    end

    resource :session
    resources :passwords, param: :token
    get "cookie-policy" => "pages#cookie_policy", as: :cookie_policy
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
