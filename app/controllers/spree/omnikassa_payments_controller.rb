module Spree
  class OmnikassaPaymentsController < ApplicationController
    def homecoming
      # @TODO: postback is actually Parameters: {"InterfaceVersion"=>"HP_1.0", "Data"=>"amount=1022|captureDay=0|captureMode=AUTHOR_CAPTURE|currencyCode=978|merchantId=002020000000001|orderId=null|transactionDateTime=2012-03-10T17:01:03+01:00|transactionReference=1069267047|keyVersion=1|authorisationId=0020000006791167|paymentMeanBrand=IDEAL|paymentMeanType=CREDIT_TRANSFER|responseCode=00", "Encode"=>"", "Seal"=>"76623e59dce80c79264d3445b12fa8d6028a6120043347e5a24d879001b35121"}

      [:amount, :transactionReference, :responseCode].each do |required|
        if !params.include?(required) || params[required].nil?
          flash[:error] = "Invalid request"
          redirect_to(root_url) and return
        end
      end

      payment_request = payment_request_from_params(params)
      case payment_request.response_level
      when :success
        flash[:info] = "Success!"
        payment_request.payment.pend
      when :pending
        flash[:info] = "Still pending. You will recieve a message"
        payment_request.payment.pend
      when :cancelled
        flash[:error] = "Order cancelled"
      when :failed
        flash[:error] = "Error occurred"
      else
        flash[:error] = "Unknown Error occurred"
      end

      redirect_to("/checkout/confirm") and return
    end

    def reply
      payment_request = payment_request_from_params(params)

      message = "OmnikassaPaymentRequest response posted: payment: #{payment_request.payment.id}; params: #{params.inspect}"

      case payment_request.response_level
      when :success
        Rails.logger.info message
        payment_request.payment.complete
      when :pending
        Rails.logger.info message
        payment_request.payment.pend
      when :cancelled
        Rails.logger.info message
        payment_request.payment.void
      when :failed
        Rails.logger.error message
        payment_request.payment.failure
      else
        Rails.logger.error message
        payment_request.payment.pend
      end
      render :text => payment_request.response_level.to_s
    end

    private
    def payment_request_from_params params
      amount = params[:amount].to_f / 100
      payment_request = Spree::OmnikassaPaymentRequest.new(amount, params[:transactionReference], params[:responseCode])

      if payment_request.payment.nil?
        raise ActiveRecord::RecordNotFound
        return
      end

      payment_request
    end
  end
end


