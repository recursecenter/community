# TODO:
# - pseudomethod "run_the_query" has not been defined yet.
# - finish implementing EventMachineSmtpDelivery.pg
#
# How to test:
#
# Spin up an AWS instance:
#
# $ ssh ubuntu@ec2-52-0-170-254.compute-1.amazonaws.com
# $ sudo smtp-sink -u ubuntu -v :25 1000

require 'eventmachine'
require 'pg/em'

class EventMachineSmtpDelivery
  class ConfigurationError < StandardError; end

  attr_reader :settings

  class << self
    def send_smtp(em_smtp_options, attempt_number, max_retries)
      ensure_reactor_running

      smtp = EM::Protocols::SmtpClient.send(em_smtp_options)

      smtp.errback do |e|
        if max_retries && max_retries > attempt_number
          async_enqueue RetryEventMachineSmtpDelivery.new(em_smtp_options, attempt_number + 1, max_retries), run_at: delay(attempt_number)
        else
          insert_failed_job
        end
      end
    end

    def ensure_reactor_running
      Thread.new { EventMachine.run } unless EventMachine.reactor_running?
      Thread.pass until EventMachine.reactor_running?
    end

    def pg
      @pg ||= PG::EM::Client.new db_options_from_active_record?
    end

    def delay(attempt_number)
      if attempt_number == 1
        Time.zone.now
      else
        (5 + (attempt_number - 1) ** 4).seconds.from_now
      end
    end

    def async_enqueue(payload, options = {})
      options[:payload_object] = payload
      options[:priority]       ||= Delayed::Worker.default_priority
      options[:queue]          ||= Delayed::Worker.default_queue_name

      unless options[:payload_object].respond_to?(:perform)
        raise ArgumentError, 'Cannot enqueue items which do not respond to perform'
      end

      job = Delayed::Job.new(options)

      # TODO: This doesn't do anything!
      run_the_query(insert_sql(job))
    end

    def insert_sql(job)
      insert_manager = job.class.arel_table.create_insert
      insert_manager.insert(job.send(:arel_attributes_with_values_for_create, job.attribute_names))
      insert_manager.to_sql
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
      max_retries:          nil
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

    self.class.send_smtp(options, 1, settings[:max_retries])
  end
end
