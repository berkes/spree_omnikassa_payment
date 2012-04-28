module Spree
  # OmnikassaPaymentRequest deals with the data
  # for the actual request to and fro Omnikassa.
  #
  # Not a persistent object: will not interact or
  # get saved in the database.
  #
  # It requires amount and order_id to be passed in
  # on creation.
  class OmnikassaPaymentRequest
    include Spree::Core::Engine.routes.url_helpers
    attr_accessor :amount, :order_id

    def initialize(amount, transaction_reference, response_code = nil)
      @payment_method = Spree::PaymentMethod::Omnikassa.fetch_payment_method
      if transaction_reference.to_s.include? merchant_id
        @amount = amount
        @order_id = transaction_reference.to_s.match(merchant_id).post_match
        @response_code = response_code
      else
        raise "transactionReference cannot be parsed"
      end
    end

    # Generates datastring according to omnikassa
    # requirements §9. name=value|name=value.
    def data
      "amount=#{amount}|orderId=#{order_id}|currencyCode=#{currency_code}|merchantId=#{merchant_id}|normalReturnUrl=#{normal_return_url}|automaticResponseUrl=#{automatic_response_url}|transactionReference=#{transaction_reference}|keyVersion=#{key_version}"
    end

    def interface_version
      "HP_1.0"
    end

    def seal
      ::Digest::SHA2.hexdigest(data + @payment_method.preferred_secret_key)
    end

    # to_s magic method simply wraps the data string generator.
    def to_s
      data
    end

    def self.build_transaction_reference order_id
      @payment_method ||= Spree::PaymentMethod::Omnikassa.fetch_payment_method
      @payment_method.preferred_merchant_id + order_id.to_s
    end

    private
    # @TODO implement size and format validation acc to §9.2.

    def amount
      (@amount * 100).to_i
    end

    def order_id
      @order_id
    end

    # @TODO implement currency lookup from locales and map to table in §9.3.
    def currency_code *args
      978 #hardcoded to Euro.
    end

    def merchant_id
      @payment_method.preferred_merchant_id
    end

    def normal_return_url
      return_url_for_action "homecoming"
    end

    def automatic_response_url
      return_url_for_action "reply"
    end

    def return_url_for_action action
      url_for(:controller => 'spree/omnikassa_payments', :action => action, :host => Spree::Config.preferred_site_url)
    end

    def transaction_reference
      Spree::OmnikassaPaymentRequest.build_transaction_reference order_id
    end

    def key_version
      @payment_method.preferred_key_version
    end
  end
end
