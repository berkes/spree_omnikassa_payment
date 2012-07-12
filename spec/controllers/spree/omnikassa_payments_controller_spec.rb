require "spec_helper"

describe Spree::OmnikassaPaymentsController do

  before(:each) do
    @routes = Spree::Core::Engine.routes

    @merchant_id = "123abc"
    @key_version = "1"
    @secret_key = "002020000000001_KEY1"

    @pm = Spree::PaymentMethod::Omnikassa.new(:name => "Omnikassa", :environment => "test")
    @pm.save
    @pm.preferred_merchant_id = @merchant_id
    @pm.preferred_key_version = @key_version
    @pm.preferred_secret_key = @secret_key

    Spree::Order.stub(:create_user)
    Spree::Order.any_instance.stub(:payment_required?).and_return(true)
    @order = Spree::Order.new(:email => "foo@example.com", :state => "delivery")
    @order.save!

    @data = "amount=24900|captureDay=0|captureMode=AUTHOR_CAPTURE|currencyCode=978|merchantId=002020000000001|orderId=#{@order.id}|transactionDateTime=2012-04-25T14:41:01+02:00|transactionReference=0020200000000011028|keyVersion=1|authorisationId=0020000006791167|paymentMeanBrand=IDEAL|paymentMeanType=CREDIT_TRANSFER|responseCode=00"
    @seal = ::Digest::SHA2.hexdigest(@data + @secret_key)

    @params = {
      "InterfaceVersion"  => "HP_1.0",
      "Data"              => @data,
      "Encode"            => "",
      "Seal"              => @seal
    }
    @payment_response = Spree::OmnikassaPaymentResponse.new(@params['Seal'], @params['Data'])
    @payment = Spree::Payment.new(
      :amount => @payment_response.attributes[:amount], 
      :order_id => @payment_response.attributes[:order_id], 
      :payment_method_id => 200123
    )
    @payment.id = 1234

    Spree::Payment.stub(:new).and_return(@payment)

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
    it 'should redirect to root_url' do
      post :homecoming, @params
      response.should redirect_to(root_url)
    end

    describe "fields" do
      describe "success" do
        before :each do
          Spree::OmnikassaPaymentResponse.any_instance.stub(:response_level).and_return(:success)
        end
        it 'should set a flash' do
          post :homecoming, @params
          flash[:info].should_not be_nil
          flash[:info].downcase.should match /success/
        end
      end
    end

    it 'should remove order_id from session' do
      session[:order_id] = 123
      post :homecoming, @params
      session[:order_id].should be_nil
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
        post :reply, @params
        @payment.state.should == "completed"
      end
      it 'should log the response with level :info' do
        Rails.logger.should_receive(:info).with( /OmnikassaPaymentResponse posted: payment: .*; params: .*/ )
        post :reply, @params
      end
      it 'should set the order state to completed' do
        post :reply, @params
        @payment_response.order.state.should == "complete"
      end
    end
    describe "pending (#{response_codes[:pending].join(',')})" do
      before :each do
        Spree::OmnikassaPaymentResponse.any_instance.stub(:response_level).and_return(:pending)
      end

      it 'should set payment state to pending' do
        post :reply, @params
        @payment.state == "pending"
      end
      it 'should log the response with level :info' do
        Rails.logger.should_receive(:info).with( /OmnikassaPaymentResponse posted: payment: .*; params: .*/ )
        post :reply, @params
      end
      it 'should set the order state to payment' do
        post :reply, @params
        @payment_response.order.state.should == "payment"
      end
    end
    describe "cancelled (#{response_codes[:cancelled].join(',')})" do
      before :each do
        Spree::OmnikassaPaymentResponse.any_instance.stub(:response_level).and_return(:cancelled)
      end
      it 'should set payment state to failed' do
        post :reply, @params
        @payment.state == "failed"
      end
      it 'should log the response with level :info' do
        Rails.logger.should_receive(:info).with( /OmnikassaPaymentResponse posted: payment: .*; params: .*/ )
        post :reply, @params
      end
      it 'should set the order state to cancelled' do
        Spree::Order.any_instance.should_receive(:cancel)
        post :reply, @params
      end
    end
    describe "failed (#{response_codes[:failed].join(',')})" do
      before :each do
        Spree::OmnikassaPaymentResponse.any_instance.stub(:response_level).and_return(:failed)
      end
      it 'should set payment state to failed' do
        post :reply, @params
        @payment.state == "failed"
      end
      it 'should log the response with level :error' do
        Rails.logger.should_receive(:error).with( /OmnikassaPaymentResponse posted: payment: .*; params: .*/ )
        post :reply, @params
      end
      it 'should set the order state to cancelled' do
        Spree::Order.any_instance.should_receive(:cancel)
        post :reply, @params
      end
    end

    it 'should add a payment to order if not exists' do
      @payment.started_processing!
      Spree::OmnikassaPaymentsController.any_instance.should_receive(:add_payment_if_not_exists)
      post :reply, @params
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
