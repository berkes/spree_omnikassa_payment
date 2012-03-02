module Spree
  class OmnikassaPaymentsController < ApplicationController
    def return
      text = "meh";
      ["amount", "transactionReference", "responseCode"].each do |required|
        if !params.include?(required)
          flash[:error] = "Invalid request"
          redirect_to root_url
        end
      end

      amount = params["amount"].to_f / 100
      payment_request = OmnikassaPaymentRequest.new(amount, params["transactionReference"], params["responseCode"])

      if payment_request.payment.nil?
        flash[:error] = "Payment not found"
        text = "payment not found"
        redirect_to root_url
      end

      case payment_request.response_level
      when :success
        flash[:info] = "Success!"
        payment_request.payment.complete
      when :pending
        flash[:info] = "Still pending. You will recieve a message"
        payment_request.payment.pend
      when :cancelled
        flash[:error] = "Order cancelled"
        payment_request.payment.failure
      when :failed
        flash[:error] = "Error occurred"
        payment_request.payment.failure
      else
        flash[:error] = "Unknown Error occurred"
        payment_request.payment.pend
      end
      # render :text => text
      redirect_to root_url
    end
  end
end
