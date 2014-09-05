require 'delayed/plugin'

class DelayedJobClassReloader < Delayed::Plugin
  callbacks do |lifecycle|
    lifecycle.around(:perform) do |*args, &block|
      begin
        ActionDispatch::Reloader.prepare!
        block.call(*args)
      ensure
        ActionDispatch::Reloader.cleanup!
      end
    end
  end
end
