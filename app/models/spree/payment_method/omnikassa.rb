module Spree
  class PaymentMethod::Omnikassa < PaymentMethod
    preference :merchant_id, :string,  :default => "002020000000001"
    preference :key_version, :integer, :default => 1
    preference :secret_key,  :string,  :default => "002020000000001_KEY1"

    def actions
      %w{capture}
    end

    def can_capture?(payment)
      ['checkout', 'pending'].include?(payment.state)
    end

    def capture(payment)
      #payments with state "checkout" must be moved into state "pending" first:
      payment.update_attribute(:state, "pending") if payment.state == "checkout"
      payment.complete
      true
    end

    def url
      if self.environment == "production"
        "https://payment-webinit.omnikassa.rabobank.nl"
      else
        "https://payment-webinit.simu.omnikassa.rabobank.nl/paymentServlet"
      end
    end

    def self.fetch_payment_method
      # @TODO fail and report user when no paymentmethod with name "omni" is provided.
      Spree::PaymentMethod.select{ |pm| pm.name.downcase =~ /omni/}.first
    end
  end
end
