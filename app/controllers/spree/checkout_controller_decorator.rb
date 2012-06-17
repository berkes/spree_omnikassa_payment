Spree::CheckoutController.class_eval do
  def edit
    if ((@order.state == "payment") && @order.valid?)
      payment_method = Spree::PaymentMethod::Omnikassa.fetch_payment_method

      payment = Spree::Payment.new( :amount => @order.total, :payment_method_id => payment_method.id )
      payment.started_processing!
      @order.payments << payment

      transaction_reference = Spree::OmnikassaPaymentRequest.build_transaction_reference(@order.id)
      @payment_request = Spree::OmnikassaPaymentRequest.new(payment.amount, transaction_reference)

      render "omnikassa_edit"
    end
  end
end
