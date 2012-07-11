module Spree
  class OmnikassaPaymentResponse
    attr_accessor :data
    attr_reader :seal, :attributes, :payment_method

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
    def payment
      Spree::Payment.find(:first, :conditions => {
        :payment_method_id => @payment_method.id,
        :order_id => @attributes[:order_id]} ) || raise(ActiveRecord::RecordNotFound)
    end

    # Finds the order trough ActiveRecord
    def order
      Spree::Order.find(@attributes[:order_id].to_i)
    end

    # Level can be :success, :pending, :cancelled or :failed
    def response_level
      response_codes.each do |level, codes|
        if codes.include?(@attributes[:response_code].to_i)
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
        key = k.underscore
        preparator = "prepare_#{key}"
        if self.respond_to? preparator, true
          v = self.send(preparator, v)
        end
        h[key.to_sym] = v if valid_attributes.include? k
      end
      h
    end

    # Callback for the to_h.
    # Converts the amount to BigDecimal and from cents to currency.
    def prepare_amount amount
      BigDecimal.new(amount)/100
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
        orderId
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
