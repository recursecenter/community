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
          @subscriptions[message.channel][ws] = true
        elsif message.unsubscribe?
          @subscriptions[message.channel].delete(ws)
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
    loop do
      sleep 2
    end
  end

  class Message
    class MessageError < StandardError; end

    attr_reader :channel, :type

    def initialize(event)
      begin
        data = JSON.parse(event.data)
      rescue JSON::JSONError => e
        raise MessageError, "error parsing JSON: #{e.message}"
      end

      missing_fields = []

      @channel = data["channel"] || missing_fields << "channel"
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
