class PubSub
  def self.publish(event, type, resource)
    Publisher.new(event, type, resource).publish
  end

  attr_reader :logger

  def initialize
    @logger = Rails.logger

    @subscriptions = ThreadSafe::Hash.new { |h, k| h[k] = ThreadSafe::Hash.new } # Using a ThreadSafe::Hash as a Set

    uri = URI.parse(ENV["REDIS_URL"])
    @redis_sub = Redis.new(host: uri.host, port: uri.port, password: uri.password)

    Thread.new { pubsub_loop }
  end

  def register(session)
    session.ws.on :message do |event|
      begin
        message = Message.new(event)

        if message.subscribe?
          logger.info "PubSub subscribe: #{{user_id: session.current_user.id, feed: message.feed}}"
          if ability(session.current_user).can? :read, message.resource
            logger.info "  request approved"
            @subscriptions[message.feed][session] = true
          else
            logger.info "  request denied :("
          end
        elsif message.unsubscribe?
          logger.info "PubSub unsubscribe: #{{user_id: session.current_user.id, feed: message.feed}}"
          @subscriptions[message.feed].delete(session)
        else
          logger.warn "Unknown message type #{message}"
        end
      rescue Message::MessageError => e
        logger.warn "#{e.class.name}: #{e.message}"
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

  def pubsub_loop
    @redis_sub.subscribe(:pubsub) do |on|
      on.message do |_, data|
        with_logged_exceptions do
          params = JSON.parse(data).with_indifferent_access

          logger.info "PubSub publish: #{data}"
          logger.info "  publishing to #{@subscriptions[params[:feed]].size} subscribers"

          @subscriptions[params[:feed]].each do |session, _|
            emitter = params[:emitter].constantize.new(session, params)
            emitter.emit_event(params[:event])

            output = build_json_message(emitter.response_body, params)
            session.ws.send(output)
          end
        end
      end
    end
  end

  def build_json_message(json_string, params)
    %Q({"feed":"#{params[:feed]}","event":"#{params[:event]}","data":#{json_string}})
  end

  def with_logged_exceptions
    begin
      yield
    rescue Exception => e
      log_exception(e)
    end
  end

  def log_exception(exception)
    message = "\n#{exception.class} (#{exception.message}):\n"
    message << exception.annoted_source_code.to_s if exception.respond_to?(:annoted_source_code)
    message << "  " << exception.backtrace.join("\n  ")
    logger.fatal("#{message}\n\n")
  end

  class Message
    class MessageError < StandardError; end

    RESOURCE_QUERIES = {
      "thread" => ->(id) { DiscussionThread.where(id: id).first },
      "notifications" => ->(id) { User.where(id: id).first.try(:notifications).try(:build) }
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

      match = /\A([^-]+)-([^-]+)\z/.match(@feed) or raise MessageError, "invalid feed syntax: #{@feed}"
      feed_type, resource_id = match.captures
      resource_query = Message::RESOURCE_QUERIES[feed_type] or raise MessageError, "invalid feed type: #{feed_type}"

      @resource = resource_query.call(resource_id) or raise MessageError, "#{@feed} does not exist"
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
      @redis_pub = RedisCache.redis
    end

    def publish
      json = JSON.dump(emitter: emitter, event: event, feed: feed, id: resource.id)

      @redis_pub.publish :pubsub, json
    end

    def feed
      case type
      when :post
        "thread-#{resource.thread_id}"
      when :notification
        "notifications-#{resource.user_id}"
      end
    end

    def emitter
      "#{type.to_s.pluralize.capitalize}Emitter"
    end
  end
end
