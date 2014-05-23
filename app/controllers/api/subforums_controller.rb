class Api::SubforumsController < Api::ApiController
  load_and_authorize_resource :subforum

  def show
  end
end
