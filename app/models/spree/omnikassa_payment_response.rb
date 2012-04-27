module Spree
  class OmnikassaPaymentResponse
    attr_accessor :data
    attr_reader :seal, :attributes

    def initialize seal, data
      @payment_method = Spree::PaymentMethod::Omnikassa.fetch_payment_method
      @seal = seal
      @data = data
      @attributes = to_h
    end

    def valid?
      return false unless @seal == ::Digest::SHA2.hexdigest(@data + @payment_method.preferred_secret_key)

      required_attributes.each do |required_attribute|
        return false unless @attributes.has_key? required_attribute.underscore.to_sym
      end

      true
    end

    # Finds a payment with provided parameters trough activeRecord.
    def payment(state = :processing)
      # @TODO should use :payment_method_id => @payment_method.id too
      Spree::Payment.find(:first, :conditions => { :amount => @attributes[:amount], :order_id => @attributes[:order_id], :state => state } ) || raise(ActiveRecord::RecordNotFound)
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

    private
    def to_h
      h = Hash.new
      @data.split("|").each do |s|
        k,v = s.split("=")
        h[k.underscore.to_sym] = v if valid_attributes.include? k
      end
      h
    end

    # As per "Tabel 5: Gegevenswoordenboek - beschrijving velden"
    # from Rabo_OmniKassa_Integratiehandleiding_v200.pdf
    def valid_attributes
      %w[
        amount
        authorisationId
        automaticResponseUrl
        captureDay
        captureMode
        complementaryCode
        complementaryInfo
        currencyCode
        customerLanguage
        expirationdate
        keyVersion
        maskedPan
        merchantId
        normalReturnUrl
        orderId
        paymentMeanBrand
        paymentMeanBrandList
        paymentMeanType
        responseCode
        transactionDateTime
        transactionReference
      ]
    end

    # attributes required for working of the class.
    def required_attributes
      %w[
        amount
        transactionReference
        responseCode
      ]
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
