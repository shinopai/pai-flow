# frozen_string_literal: true

module Users
  class ConfirmationsController < Devise::ConfirmationsController
    # POST /resource/confirmation
    def create
      return handle_rate_limited_resend if resend_rate_limited?(user_for_resend)

      super
    end

    private

    def user_for_resend
      email = resource_params[:email].to_s.strip.downcase
      resource_class.find_by(email: email)
    end

    def handle_rate_limited_resend
      set_flash_message!(:notice, :send_instructions)
      respond_with(
        {},
        location: after_resending_confirmation_instructions_path_for(resource_name)
      )
    end

    def resend_rate_limited?(user)
      return false unless user&.confirmation_instructions_sent_at

      user.confirmation_instructions_sent_at > 60.seconds.ago
    end
  end
end
