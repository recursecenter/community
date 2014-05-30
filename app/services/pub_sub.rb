class PubSub
  def self.publish(event, type, resource)
    Publisher.new(event, type, resource).publish
  end

  def initialize
    @subscriptions = ThreadSafe::Hash.new { |h, k| h[k] = ThreadSafe::Hash.new } # Using a ThreadSafe::Hash as a Set

    Thread.new { run_pubsub_loop }
  end

  def register(session)
    session.ws.on :message do |event|
      begin
        message = Message.new(event)

        if message.subscribe?
          if ability(session.current_user).can? :read, message.resource
            @subscriptions[message.feed][session] = true
          end
        elsif message.unsubscribe?
          @subscriptions[message.feed].delete(session)
        else
          Rails.logger.warn "Unknown message type #{message}"
        end
      rescue Message::MessageError => e
        Rails.logger.warn "#{e.class.name}: #{e.message}"
      end
    end

    session.ws.on :close do |event|
      @subscriptions.each do |_, sessions|
        sessions.delete(session)
      end
    end

    session
  end

private
  def ability(user)
    Ability.new(user.reload)
  end

  def run_pubsub_loop
    # TODO: This acquires a lock for the global $redis and never gives
    # it up. This means that once this subscribe runs, nothing else
    # can use $redis to publish. This means that each instance of
    # PubSub needs its own personal redis connection.
    $redis.subscribe(:pubsub) do |on|
      on.message do |_, data|
        params = JSON.parse(data).with_indifferent_access

        @subscriptions[params[:feed]].each do |session, _|
          emitter = params[:emitter].constantize.new(session, params)
          emitter.emit_event(params[:event])
          binding.remote_pry
        end
      end
    end
  end

  class Message
    class MessageError < StandardError; end

    MODELS = {
      "thread" => DiscussionThread
    }

    attr_reader :feed, :type, :resource

    def initialize(event)
      begin
        data = JSON.parse(event.data)
      rescue JSON::JSONError => e
        raise MessageError, "error parsing JSON: #{e.message}"
      end

      missing_fields = []

      @feed = data["feed"] || missing_fields << "feed"
      @type = data["type"] || missing_fields << "type"

      unless missing_fields.empty?
        raise MessageError, "missing fields: #{missing_fields.join(", ")}"
      end

      match = /(.*)-(.*)/.match(@feed) or raise MessageError, "invalid feed: #{@feed}"
      model_name, model_id = match.captures
      model = Message::MODELS[model_name] or raise MessageError, "invalid model: #{model_name}"

      @resource = model.where(id: model_id).first or raise MessageError, "model '#{model_name}' with id '#{model_id}' does not exist"
    end

    def subscribe?
      type == "subscribe"
    end

    def unsubscribe?
      type == "unsubscribe"
    end
  end

  class Publisher
    attr_reader :event, :type, :resource

    def initialize(event, type, resource)
      @event = event
      @type = type
      @resource = resource
    end

    def publish
      json = JSON.dump(emitter: emitter, event: event, feed: feed, resource_id: resource.id)

      puts "BEFORE PUBLISH"
      $redis.publish :pubsub, json
      puts "AFTER PUBLISH"
    end

    def feed
      case type
      when :post
        "thread-#{resource.thread_id}"
      end
    end

    def emitter
      "#{type.to_s.pluralize.capitalize}Emitter"
    end
  end
end
