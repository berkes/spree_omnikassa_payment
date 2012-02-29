Spree::CheckoutController.class_eval do
  def edit
    if ((@order.state == "payment") && @order.valid?)
      payment = Spree::Payment.new
      payment.amount = @order.total

      payment.payment_method = Spree::PaymentMethod.select{ |pm| pm.name.downcase =~ /omni/}.first
      @order.payments << payment
      payment.started_processing
      render "omnikassa_edit"
    end
  end
end
