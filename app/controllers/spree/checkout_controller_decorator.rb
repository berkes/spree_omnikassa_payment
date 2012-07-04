Spree::CheckoutController.class_eval do
  def edit
    if ((@order.state == "payment") && @order.valid?)
      transaction_reference = Spree::OmnikassaPaymentRequest.build_transaction_reference(@order.id)
      @payment_request = Spree::OmnikassaPaymentRequest.new(@order.total, transaction_reference)

      render "omnikassa_edit"
    end
  end
end
