Rails.application.routes.draw do
  devise_for :users,
             skip: [:registrations],
             controllers: {
               confirmations: "users/confirmations"
             }

  devise_scope :user do
    get "/users/sign_up",
        to: "devise/registrations#new",
        as: :new_user_registration

    post "/users",
         to: "devise/registrations#create",
         as: :user_registration

    get "/users/edit",
        to: "users/registrations#edit",
        as: :edit_user_registration

    patch "/users",
          to: "users/registrations#update"
  end

  get "up" => "rails/health#show", as: :rails_health_check

  resources :teams, only: %i[index show edit update] do
    post :select, on: :member

    resources :members,
              controller: "memberships",
              only: %i[index update]

    patch "ownership",
          to: "memberships#transfer_ownership",
          as: :ownership

    resource :membership,
             controller: "memberships",
             only: :destroy

    resources :invitations, only: %i[index create destroy]
  end

  resources :invitations, only: [:show] do
    member do
      patch :accept
      patch :decline
    end
  end

  # Render dynamic PWA files from app/views/pwa/
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
