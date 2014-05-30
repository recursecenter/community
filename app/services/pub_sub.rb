class PubSub
  def initialize
    @subscriptions = ThreadSafe::Hash.new { |h, k| h[k] = ThreadSafe::Hash.new } # Using a ThreadSafe::Hash as a Set

    Thread.new { run_publish_loop }
  end

  def register(user, ws)
    ws.on :message do |event|
      begin
        message = Message.new(event)

        if message.subscribe?
          if ability(user).can? :read, message.topic
            @subscriptions[message.feed][ws] = true
          end
        elsif message.unsubscribe?
          @subscriptions[message.feed].delete(ws)
        else
          Rails.logger.warn "Unknown message type #{message}"
        end
      rescue Message::MessageError => e
        Rails.logger.warn "#{e.class.name}: #{e.message}"
      end
    end

    ws.on :close do |event|
      @subscriptions.each do |_, web_sockets|
        web_sockets.delete(ws)
      end
    end

    ws
  end

private
  def ability(user)
    Ability.new(user.reload)
  end

  def run_publish_loop
    $redis.subscribe(:posts) do |on|
      on.message do |_, message|
        data = JSON.parse(message)
        feed = "thread-#{data["thread_id"]}"

        @subscriptions[feed].each do |ws, _|
          ws.send(JSON.dump({type: "publish", feed: feed, data: message}))
        end
      end
    end
  end

  class Message
    class MessageError < StandardError; end

    MODELS = {
      "thread" => DiscussionThread
    }

    attr_reader :feed, :type, :topic

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

      @topic = model.where(id: model_id).first or raise MessageError, "model '#{model_name}' with id '#{model_id}' does not exist"
    end

    def subscribe?
      type == "subscribe"
    end

    def unsubscribe?
      type == "unsubscribe"
    end
  end
end
