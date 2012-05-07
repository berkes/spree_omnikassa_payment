Spree::CheckoutController.class_eval do
  def edit
    if ((@order.state == "payment") && @order.valid?)
      payment = Spree::Payment.new
      payment.amount = @order.total

      payment_method = Spree::PaymentMethod::Omnikassa.fetch_payment_method
      payment.payment_method_id = payment_method.id
      @order.payments << payment
      payment.started_processing

      transaction_reference = Spree::OmnikassaPaymentRequest.build_transaction_reference(@order.id)
      @payment_request = Spree::OmnikassaPaymentRequest.new(payment.amount, transaction_reference)

      render "omnikassa_edit"
    end
  end
end
