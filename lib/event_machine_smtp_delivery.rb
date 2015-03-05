require 'eventmachine'
require 'pg/em'

class EventMachineSmtpDelivery
  class ConfigurationError < StandardError; end

  attr_reader :settings

  class << self
    def send_smtp(em_smtp_options, attempt_number, max_attempts)
      ensure_reactor_running

      smtp = EM::Protocols::SmtpClient.send(em_smtp_options)

      smtp.errback do |e|
        em_delivery = RetryEventMachineSmtpDelivery.new(em_smtp_options, attempt_number + 1, max_attempts)

        if max_attempts && max_attempts > attempt_number
          async_enqueue em_delivery, run_at: delay(attempt_number)
        else
          async_insert_failed_job em_delivery, e
          Rails.logger.error("EventMachineSmtpDelivery Failure:\nTo: #{em_smtp_options[:to]}\n\n#{em_smtp_options[:content]}")
        end
      end
    end

    def delay(attempt_number)
      if attempt_number == 1
        Time.zone.now
      else
        (5 + (attempt_number - 1) ** 4).seconds.from_now
      end
    end

    def async_enqueue(payload, options = {})
      async_insert_job(new_delayed_job(payload, options))
    end

    def async_insert_failed_job(payload, error)
      failed_job = new_delayed_job(payload)
      failed_job.failed_at = Time.zone.now
      failed_job.last_error = error
      async_insert_job(failed_job)
    end

    def new_delayed_job(payload, options = {})
      options[:payload_object] = payload
      options[:priority]       ||= Delayed::Worker.default_priority
      options[:queue]          ||= Delayed::Worker.default_queue_name

      unless options[:payload_object].respond_to?(:perform)
        raise ArgumentError, 'Cannot enqueue items which do not respond to perform'
      end

      Delayed::Job.new(options)
    end

    def async_insert_job(job)
      now = Time.zone.now
      job.created_at = now
      job.updated_at = now

      EventMachine.schedule do
        Fiber.new { pg.query(to_insert_sql(job)) }.resume
      end
    end

    def to_insert_sql(record)
      insert_manager = record.class.arel_table.create_insert
      insert_manager.insert(record.send(:arel_attributes_with_values_for_create, record.attribute_names))
      insert_manager.to_sql
    end

    def ensure_reactor_running
      Thread.new { EventMachine.run } unless EventMachine.reactor_running?
      Thread.pass until EventMachine.reactor_running?
    end

    def pg
      if defined? @pg
        return @pg
      end

      db_config = ActiveRecord::Base.connection_config

      em_db_config = {}

      em_db_config[:dbname]   = db_config[:database]
      em_db_config[:host]     = db_config[:host]     if db_config[:host]
      em_db_config[:port]     = db_config[:port]     if db_config[:port]
      em_db_config[:user]     = db_config[:username] if db_config[:username]
      em_db_config[:password] = db_config[:password] if db_config[:password]

      @pg = PG::EM::Client.new(em_db_config)
    end
  end

  def initialize(values)
    @settings = {
      address:              "localhost",
      port:                 25,
      domain:               'localhost.localdomain',
      user_name:            nil,
      password:             nil,
      authentication:       nil,
      enable_starttls_auto: true,
      max_attempts:          nil
    }.merge!(values)
  end

  def deliver!(message)
    options = {
      domain:   settings[:domain],
      host:     settings[:address],
      port:     settings[:port],
      starttls: settings[:enable_starttls_auto]
    }

    if settings[:authentication] == :plain
      options[:auth] = {
        type:     :plain,
        username: settings[:user_name],
        password: settings[:password]
      }
    elsif settings[:authentication].present?
      raise ConfigurationError, "EventMachineSmtpDelivery only supports :plain authentication"
    end

    options[:from]    = message.from.first
    options[:to]      = message.to
    options[:content] = "#{message.to_s}\r\n.\r\n"

    self.class.send_smtp(options, 1, settings[:max_attempts])
  end
end
