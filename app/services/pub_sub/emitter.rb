class PubSub
  class Emitter < AbstractController::Base
    include AbstractController::Rendering
    include AbstractController::Helpers
    include AbstractController::AssetPaths
    include ActionView::Layouts

    include CanCan::ControllerAdditions

    include CurrentUser

    self.view_paths = "app/views"

    attr_reader :session, :params

    def initialize(session, params)
      @session = session
      @params = params.with_indifferent_access
    end

    def emit_event(event)
      send(event)
    end
  end
end
