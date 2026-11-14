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
        to: "devise/registrations#edit",
        as: :edit_user_registration

    patch "/users",
          to: "devise/registrations#update"
  end

  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
