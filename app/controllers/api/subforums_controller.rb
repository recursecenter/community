class Api::SubforumsController < Api::ApiController
  load_and_authorize_resource :subforum

  def show
    @threads = @subforum.threads_for_user(current_user).includes(:created_by).order(marked_unread_at: :desc)
    @subforum.mark_as_visited_for(current_user)
  end
end
