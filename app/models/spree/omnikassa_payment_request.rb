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
      "amount=#{amount}|currencyCode=#{currency_code}|merchantId=#{merchant_id}|normalReturnUrl=#{normal_return_url}|transactionReference=#{transaction_reference}|keyVersion=#{key_version}"
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

    # Finds a payment with provided parameters trough activeRecord.
    def payment(state = :processing)
      # @TODO should use :payment_method_id => @payment_method.id too
      Spree::Payment.find(:first, :conditions => { :amount => @amount, :order_id => @order_id, :state => state } ) || raise(ActiveRecord::RecordNotFound)
    end

    # Level can be :success, :pending, :cancelled or :failed
    def response_level
      response_codes.each do |level, codes|
        if codes.include?(@response_code)
          return level
        end
      end

      nil
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
      url_for(:controller => 'spree/omnikassa_payments', :action => 'homecoming', :host => Spree::Config.preferred_site_url)
    end

    def transaction_reference
      Spree::OmnikassaPaymentRequest.build_transaction_reference order_id
    end

    def key_version
      @payment_method.preferred_key_version
    end

    def response_codes
      {
        :success => [00],
        :pending => [
          90,
          99],
        :cancelled => [
          14, #invalid CSC or CVV
          17, #cancelled by user
          75], #number attempts to enter cardnumer exceeded.
        :failed => [
          02,
          03,
          05,
          12,
          30,
          34,
          40,
          63,
          94,
          97]
      }
    end
  end
end
