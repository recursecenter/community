module ConnectionMonitor
  CONNECTIONS = {}

  def checkout
    conn = super
    CONNECTIONS[conn.object_id] = {call_stack: caller, time: Time.now.to_s}

    if CONNECTIONS.size > 3 # we should have a max of 3 connections per-process, so log if we ever have more
      puts_formatted_error
    end

    conn
  end

  def checkin(conn)
    CONNECTIONS.delete(conn.object_id)
    super
  end

private
  def puts_formatted_error
    Rails.logger.error "DB per-process connection limit exceeded: #{CONNECTIONS.count}"
    CONNECTIONS.each do |k, conn_info|
      Rails.logger.error "#{conn_info[:time]} " + '='*60
      Rails.logger.error conn_info[:call_stack].join("\n")
    end
  end
end

if Rails.env.production?
  class ActiveRecord::ConnectionAdapters::ConnectionPool
    prepend ConnectionMonitor
  end
end
