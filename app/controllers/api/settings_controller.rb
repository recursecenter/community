class Api::SettingsController < Api::ApiController
  skip_authorization_check only: :update

  def update
    current_user.update!(settings_params)
    render json: {}
  end

private
  def settings_params
    params.require(:settings).permit(:email_on_mention)
  end
end
