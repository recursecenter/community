module SubscriptionActions
  extend ActiveSupport::Concern

  included do
    delegate :subscribe, :unsubscribe, to: :subscription

    def self.has_subscribable(attribute)
      define_method :subscribable do
        self.instance_variable_get("@#{attribute}")
      end
    end
  end

private
  def subscription
    return @subscription if @subscription
    @subscription = subscribable.subscription_for(current_user)
    authorize! :update, @subscription
    @subscription
  end
end
