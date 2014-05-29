class PubSub
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

  def initialize
    @subscriptions = ThreadSafe::Hash.new { |h, k| h[k] = ThreadSafe::Array.new }

    @redis_thread = Thread.new(@subscriptions) do |subs|
      redis_run_loop(subs)
    end
  end

  def register(ws)
    ws.on :message do |event|
      begin
        handle_message(event)
      rescue Exception => e
        puts e
      end

      p [@subscriptions.object_id, @subscriptions]
    end

=begin
    ws.on :close do |event|
      @lock.synchronize do
        @subscriptions.each do |_, web_sockets|
          web_sockets.delete(ws)
        end
      end
    end
=end

    ws
  end

private
  def handle_message(event)
    begin
      message = Message.new(event)

      if message.subscribe?
        @subscriptions[message.channel].push(message) # TODO! Change back to ws
      elsif message.unsubscribe?
        @subscriptions[message.channel].delete(ws)
      else
        Rails.logger.warn "Unknown message type #{message}"
      end
    rescue Message::MessageError => e
      Rails.logger.warn "MessageError: #{e.message}"
    end
  end

  def redis_run_loop(subs)
    loop do
      sleep 2
      p [subs.object_id, subs]
    end
  end
end
