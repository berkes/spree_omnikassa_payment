require "spec_helper"

describe Spree::OmnikassaPaymentsController do

  before(:each) { @routes = Spree::Core::Engine.routes }

  response_args = [
    "amount",
    "currencyCode",
    "merchantId",
    "transactionReference",
    "keyVersion",
    "orderId",
    "responseCode",
    "transactionDateTime"
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
      14,
      30,
      34,
      40,
      63,
      94,
      97]
  }

  describe "return" do
    it 'should handle a post' do
      debugger
      # { :post => "omnikassa_payments/return" }
      # {:action=>"return", :method=>:post, :controller=>"spree/omnikassa_payments"}
      post :return
      assert_response :success
    end

    describe "fields" do
      before :each do
        @args = {}
        response_args.each do |field|
          @args[field] = "#{field}Value123"
        end
      end

      [ "amount",
        "transactionReference",
        "responseCode"].each do |requirement|
          it "should require param #{requirement}" do
            @args[requirement] = nil
            { :post => "omnikassa_payments/return", :payment_request => @args }
            assert_equal 'invalid', flash[:error]
          end
      end

      it "should get a responsecode 00 on success" do
        pending "@TODO check for responsecode"
      end

      describe "success" do
        it 'should set payment state to pending' do
          pending "@TODO:Implement"
        end
        it 'should set a flash' do
          pending "@TODO:Implement"
        end
        it 'should redirect to "/checkout/confirm"' do
          pending "@TODO:Implement"
        end
      end
    end
  end

  describe 'response' do
    it 'should handle a post' do
      pending "@TODO:Implement"
    end

    response_args.each do |field|
      it "should recieve param #{field}" do
        pending "@TODO: check for posted parameters"
      end

      it "should get a responsecode 00 on success" do
        pending "@TODO check for responsecode"
      end
    end #describe fields

    describe 'success (00)' do
      it 'should set payment state to completed' do
        pending "@TODO:Implement"
      end
      it 'should log the response with level :info' do
        pending "@TODO:Implement"
      end
    end
    describe "pending (#{response_codes[:pending].join(',')})" do
      it 'should set payment state to pending' do
        pending "@TODO:Implement"
      end
      it 'should log the response with level :info' do
        pending "@TODO:Implement"
      end
    end
    describe "cancelled (#{response_codes[:cancelled].join(',')})" do
      it 'should set payment state to pending' do
        pending "@TODO:Implement"
      end
      it 'should log the response with level :info' do
        pending "@TODO:Implement"
      end
    end
    describe "failed (#{response_codes[:failed].join(',')})" do
      it 'should set payment state to pending' do
        pending "@TODO:Implement"
      end
      it 'should log the response with level :error' do
        pending "@TODO:Implement"
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
