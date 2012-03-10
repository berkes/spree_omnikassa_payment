require "spec_helper"

describe Spree::OmnikassaPaymentsController do

  before(:each) { @routes = Spree::Core::Engine.routes }

  response_args = [
   :amount,
   :currencyCode,
   :merchantId,
   :transactionReference,
   :keyVersion,
   :orderId,
   :responseCode,
   :transactionDateTime
  ]

  response_codes = {
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

  describe "#homecoming" do
    it 'should handle a post' do
      post :homecoming
      response.should redirect_to root_url
    end

    describe "fields" do
      before :each do
        @args = {
          :amount => 123,
          :transactionReference => 100123,
          :responseCode => 00
        }
        @payment = Spree::Payment.new(:amount => @args["amount"], :order_id => @args["transactionReference"], :payment_method_id => 200123)

        Spree::OmnikassaPaymentRequest.any_instance.stub(:payment).and_return(@payment)
        Spree::PaymentMethod.any_instance.stub(:fetch_payment_method).and_return(Spree::PaymentMethod.new(:name => "Omnikassa"))
      end

      [ :amount,
        :transactionReference,
        :responseCode].each do |requirement|
          it "should require param #{requirement}" do
            @args[requirement] = nil
            post :homecoming, @args
            flash[:error].downcase.should match /invalid request/
          end
      end

      it 'should raise a RecordNotFound error when no payment was found' do
        Spree::OmnikassaPaymentRequest.any_instance.stub(:payment).and_return(nil)
        expect { post :homecoming, @args }.to raise_error(ActiveRecord::RecordNotFound)
      end

      describe "success" do
        before :each do
          Spree::OmnikassaPaymentRequest.any_instance.stub(:response_level).and_return(:success)
        end
        it 'should set payment state to pending' do
          @payment.should_receive("pend")
          post :homecoming, @args
        end
        it 'should set a flash' do
          post :homecoming, @args
          flash[:info].should_not be_nil
          flash[:info].downcase.should match /success/
        end
        it 'should redirect to "/checkout/confirm"' do
          post :homecoming, @args
          response.should redirect_to("/checkout/confirm")
        end
      end
    end
  end

  describe '#reply' do
    before(:each) do
      @args = {
        :amount => 123,
        :currencyCode => 62,
        :merchantId => 002020000000001,
        :transactionReference => 200123,
        :keyVersion => 1,
        :orderId => 100123,
        :responseCode => 00,
        :transactionDateTime => Date.new
      }
      @payment = Spree::Payment.new(:amount => @args["amount"], :order_id => @args["transactionReference"], :payment_method_id => 200123)

      Spree::OmnikassaPaymentRequest.any_instance.stub(:payment).and_return(@payment)
      Spree::PaymentMethod.any_instance.stub(:fetch_payment_method).and_return(Spree::PaymentMethod.new(:name => "Omnikassa"))
    end
    it 'should handle a post' do
      post :reply
      response.status.should == 200
    end

    response_args.each do |field|
      it "should recieve param #{field}" do
        post :reply, @args
        controller.params[field].should_not be_nil
      end
    end #describe fields

    describe 'authenticity' do
      it 'should check for autheticity by ?' do
        pending "@TODO: waiting for details from bank regarding the authenticity check."
      end
    end

    describe 'success (00)' do
      before :each do
        Spree::OmnikassaPaymentRequest.any_instance.stub(:response_level).and_return(:success)
      end

      it 'should set payment state to completed' do
        Spree::Payment.any_instance.should_receive(:complete)
        post :reply, @args
      end
      it 'should log the response with level :info' do
        Rails.logger.should_receive(:info).with( /OmnikassaPaymentRequest response posted: payment: .*; params: .*/ )
        post :reply, @args
      end
    end
    describe "pending (#{response_codes[:pending].join(',')})" do
      before :each do
        Spree::OmnikassaPaymentRequest.any_instance.stub(:response_level).and_return(:pending)
      end

      it 'should set payment state to pending' do
        Spree::Payment.any_instance.should_receive(:pend)
        post :reply, @args
      end
      it 'should log the response with level :info' do
        Rails.logger.should_receive(:info).with( /OmnikassaPaymentRequest response posted: payment: .*; params: .*/ )
        post :reply, @args
      end
    end
    describe "cancelled (#{response_codes[:cancelled].join(',')})" do
      before :each do
        Spree::OmnikassaPaymentRequest.any_instance.stub(:response_level).and_return(:cancelled)
      end
      it 'should set payment state to void' do
        Spree::Payment.any_instance.should_receive(:void)
        post :reply, @args
      end
      it 'should log the response with level :info' do
        Rails.logger.should_receive(:info).with( /OmnikassaPaymentRequest response posted: payment: .*; params: .*/ )
        post :reply, @args
      end
    end
    describe "failed (#{response_codes[:failed].join(',')})" do
      before :each do
        Spree::OmnikassaPaymentRequest.any_instance.stub(:response_level).and_return(:failed)
      end
      it 'should set payment state to failed' do
        Spree::Payment.any_instance.should_receive(:failure)
        post :reply, @args
      end
      it 'should log the response with level :error' do
        Rails.logger.should_receive(:error).with( /OmnikassaPaymentRequest response posted: payment: .*; params: .*/ )
        post :reply, @args
      end
    end
  end
end

=begin
Spree Payment states from http://guides.spreecommerce.com/payments.html#payment
checkout 	Checkout has not been completed
processing 	The payment is being processed (temporary – intended to prevent double submission)
pending 	The payment has been processed but not yet complete (ex. authorized but not captured)
completed 	The payment is completed – only payments in this state count against the order total
failed 	The payment was rejected (ex. credit card was declined)
void 	The payment should not be counted against the order
=end
