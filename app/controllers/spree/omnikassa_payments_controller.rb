module Spree
  class OmnikassaPaymentsController < ApplicationController
    skip_before_filter :verify_authenticity_token

    def homecoming
      payment_response = payment_response_from_params(params)

      if not payment_response.valid?
        flash[:error] = "Invalid request"
        redirect_to(root_url) and return
      end

      case payment_response.response_level
      when :success
        flash[:info] = "Success!"
        payment_response.payment.pend
      when :pending
        flash[:info] = "Still pending. You will recieve a message"
        payment_response.payment.pend
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
      payment_response = payment_response_from_params(params)
      message = "OmnikassaPaymentResponse posted: payment: #{payment_response.payment.id}; params: #{params.inspect}"

      if payment_response.valid?
        case payment_response.response_level
        when :success
          Rails.logger.info message
          payment_response.payment.complete
        when :pending
          Rails.logger.info message
          payment_response.payment.pend
        when :cancelled
          Rails.logger.info message
          payment_response.payment.void
        when :failed
          Rails.logger.error message
          payment_response.payment.failure
        else
          Rails.logger.error message
          payment_response.payment.pend
        end
      else
        Rails.logger.error message
        payment_response.payment.pend
      end
      render :text => payment_response.response_level.to_s
    end

    private
    def payment_response_from_params params
      Spree::OmnikassaPaymentResponse.new(params["Seal"], params["Data"])
    end
  end
end


