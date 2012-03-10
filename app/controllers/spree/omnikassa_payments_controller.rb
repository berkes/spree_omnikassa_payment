module Spree
  class OmnikassaPaymentsController < ApplicationController
    def homecoming
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


