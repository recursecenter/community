class PubSub
  def initialize
    @subscriptions = ThreadSafe::Hash.new { |h, k| h[k] = ThreadSafe::Hash.new } # Using a ThreadSafe::Hash as a Set

    Thread.new do
      redis_run_loop
    end
  end

  def register(ws)
    ws.on :message do |event|
      begin
        message = Message.new(event)

        if message.subscribe?
          @subscriptions[message.feed][ws] = true
        elsif message.unsubscribe?
          @subscriptions[message.feed].delete(ws)
        else
          Rails.logger.warn "Unknown message type #{message}"
        end
      rescue Message::MessageError => e
        Rails.logger.warn "MessageError: #{e.message}"
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
  def redis_run_loop
    $redis.subscribe(:posts) do |on|
      on.message do |_, message|
        data = JSON.parse(message)
        @subscriptions["thread-#{data["thread_id"]}"].each { |ws, _| ws.send(message) }
      end
    end
  end

  class Message
    class MessageError < StandardError; end

    attr_reader :feed, :type

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
    end

    def subscribe?
      type == "subscribe"
    end

    def unsubscribe?
      type == "unsubscribe"
    end
  end
end
