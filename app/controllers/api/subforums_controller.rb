class Api::SubforumsController < Api::ApiController
  load_and_authorize_resource :subforum

  def show
    @threads = @subforum.threads_for_user(current_user).includes(:created_by).order(last_posted_to: :desc)
  end
end
