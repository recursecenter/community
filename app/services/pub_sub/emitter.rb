class PubSub
  class Emitter < AbstractController::Base
    include AbstractController::Rendering
    include AbstractController::Helpers
    include AbstractController::AssetPaths
    include ActionView::Layouts
    include ActionController::Renderers::All

    include CanCan::ControllerAdditions

    include CurrentUser

    self.view_paths = "app/views"

    attr_reader :session, :params
    attr_accessor :content_type

    def initialize(session, params)
      @session = session
      @params = params.with_indifferent_access
    end

    def emit_event(event)
      send(event)

      unless response_body
        render event
      end
    end
  end
end
