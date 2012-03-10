Spree::CheckoutController.class_eval do
  def edit
    if ((@order.state == "payment") && @order.valid?)
      payment = Spree::Payment.new
      payment.amount = @order.total

      payment.payment_method_id = Spree::PaymentMethod::Omnikassa.fetch_payment_method.id
      @order.payments << payment
      payment.started_processing

      @payment_request = Spree::OmnikassaPaymentRequest.new(payment.amount, @order.id)
      render "omnikassa_edit"
    end
  end
end
