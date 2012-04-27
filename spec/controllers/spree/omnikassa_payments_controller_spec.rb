require "spec_helper"

describe Spree::OmnikassaPaymentsController do

  before(:each) do
    @routes = Spree::Core::Engine.routes

    @merchant_id = "123abc"
    @key_version = "1"
    @secret_key = "002020000000001_KEY1"

    @pm = Spree::PaymentMethod::Omnikassa.new(:name => "Omnikassa")
    @pm.save
    @pm.preferred_merchant_id = @merchant_id
    @pm.preferred_key_version = @key_version
    @pm.preferred_secret_key = @secret_key

    @params = {
      "InterfaceVersion"  => "HP_1.0",
      "Data"              => "amount=24900|captureDay=0|captureMode=AUTHOR_CAPTURE|currencyCode=978|merchantId=002020000000001|orderId=null|transactionDateTime=2012-04-25T14:41:01+02:00|transactionReference=0020200000000011028|keyVersion=1|authorisationId=0020000006791167|paymentMeanBrand=IDEAL|paymentMeanType=CREDIT_TRANSFER|responseCode=00",
      "Encode"            => "",
      "Seal"              => "57262b8054ef2043b90de99954c0cbba213d03ea360103a32514ae154cfcd08d"
    }
    @payment_response = Spree::OmnikassaPaymentResponse.new(@params['Seal'], @params['Data'])
    @payment = Spree::Payment.new(:amount => @payment_response.attributes[:amount], :order_id => @payment_response.attributes[:order_id], :payment_method_id => 200123)
    @payment.id = 1234
    Spree::OmnikassaPaymentResponse.any_instance.stub(:payment).and_return(@payment)
  end

  response_args = %w[
   Data
   Seal
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
    it 'should redirect to "/checkout/confirm"' do
      post :homecoming, @params
      response.should redirect_to("/checkout/confirm")
    end

    describe "fields" do
      describe "success" do
        before :each do
          Spree::OmnikassaPaymentResponse.any_instance.stub(:response_level).and_return(:success)
        end
        it 'should set payment state to pending' do
          @payment.should_receive("pend")
          post :homecoming, @params
        end
        it 'should set a flash' do
          post :homecoming, @params
          flash[:info].should_not be_nil
          flash[:info].downcase.should match /success/
        end

      end
    end
  end

  describe '#reply' do
    it 'should handle a post' do
      post :reply, @params
      response.status.should == 200
    end

    response_args.each do |field|
      it "should recieve param #{field}" do
        post :reply, @params
        controller.params[field].should_not be_nil
      end
    end #describe fields

    describe 'success (00)' do
      before :each do
        Spree::OmnikassaPaymentResponse.any_instance.stub(:response_level).and_return(:success)
      end

      it 'should set payment state to completed' do
        @payment.should_receive(:complete)
        post :reply, @params
      end
      it 'should log the response with level :info' do
        Rails.logger.should_receive(:info).with( /OmnikassaPaymentResponse posted: payment: .*; params: .*/ )
        post :reply, @params
      end
    end
    describe "pending (#{response_codes[:pending].join(',')})" do
      before :each do
        Spree::OmnikassaPaymentResponse.any_instance.stub(:response_level).and_return(:pending)
      end

      it 'should set payment state to pending' do
        Spree::Payment.any_instance.should_receive(:pend)
        post :reply, @params
      end
      it 'should log the response with level :info' do
        Rails.logger.should_receive(:info).with( /OmnikassaPaymentResponse posted: payment: .*; params: .*/ )
        post :reply, @params
      end
    end
    describe "cancelled (#{response_codes[:cancelled].join(',')})" do
      before :each do
        Spree::OmnikassaPaymentResponse.any_instance.stub(:response_level).and_return(:cancelled)
      end
      it 'should set payment state to void' do
        Spree::Payment.any_instance.should_receive(:void)
        post :reply, @params
      end
      it 'should log the response with level :info' do
        Rails.logger.should_receive(:info).with( /OmnikassaPaymentResponse posted: payment: .*; params: .*/ )
        post :reply, @params
      end
    end
    describe "failed (#{response_codes[:failed].join(',')})" do
      before :each do
        Spree::OmnikassaPaymentResponse.any_instance.stub(:response_level).and_return(:failed)
      end
      it 'should set payment state to failed' do
        Spree::Payment.any_instance.should_receive(:failure)
        post :reply, @params
      end
      it 'should log the response with level :error' do
        Rails.logger.should_receive(:error).with( /OmnikassaPaymentResponse posted: payment: .*; params: .*/ )
        post :reply, @params
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
