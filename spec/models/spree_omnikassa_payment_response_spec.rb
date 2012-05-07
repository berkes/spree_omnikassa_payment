require "spec_helper"

describe Spree::OmnikassaPaymentResponse do
  before :each do
    @merchant_id = "123abc"
    @key_version = "1"
    @secret_key = "002020000000001_KEY1"

    @pm = Spree::PaymentMethod::Omnikassa.new(:name => "Omnikassa")
    @pm.save
    @pm.preferred_merchant_id = @merchant_id
    @pm.preferred_key_version = @key_version
    @pm.preferred_secret_key = @secret_key
    @payment_method = Spree::PaymentMethod::Omnikassa.fetch_payment_method
    # Parameters: {"InterfaceVersion"=>"HP_1.0", "Data"=>"amount=24900|captureDay=0|captureMode=AUTHOR_CAPTURE|currencyCode=978|merchantId=002020000000001|orderId=null|transactionDateTime=2012-04-25T14:41:01+02:00|transactionReference=0020200000000011028|keyVersion=1|authorisationId=0020000006791167|paymentMeanBrand=IDEAL|paymentMeanType=CREDIT_TRANSFER|responseCode=00", "Encode"=>"", "Seal"=>"57262b8054ef2043b90de99954c0cbba213d03ea360103a32514ae154cfcd08d"}
    @seal = "57262b8054ef2043b90de99954c0cbba213d03ea360103a32514ae154cfcd08d"
    @data = "amount=24900|captureDay=0|captureMode=AUTHOR_CAPTURE|currencyCode=978|merchantId=002020000000001|orderId=123|transactionDateTime=2012-04-25T14:41:01+02:00|transactionReference=0020200000000011028|keyVersion=1|authorisationId=0020000006791167|paymentMeanBrand=IDEAL|paymentMeanType=CREDIT_TRANSFER|responseCode=00"

  end

  describe '#initialize' do
    it 'should require seal and data' do
      Spree::OmnikassaPaymentResponse.should_receive(:new).with(@seal, @data).and_return(Spree::OmnikassaPaymentResponse)
      Spree::OmnikassaPaymentResponse.new(@seal, @data)
    end
    it 'should fill @attributes with snake_cased hash from data' do
      data = 'amount=123|orderId=456'
      response = Spree::OmnikassaPaymentResponse.new(@seal, data)
      response.attributes.keys.should =~ [:amount, :order_id]
    end
    it 'should reject none-whitelisted variables' do
      data = 'foo=bar'
      response = Spree::OmnikassaPaymentResponse.new(@seal, data)
      response.attributes.should_not include(:foo => "bar")
    end
  end

  describe '#valid?' do
    it 'should be valid with correct seal for request' do
      seal = ::Digest::SHA2.hexdigest(@data + @payment_method.preferred_secret_key)
      response = Spree::OmnikassaPaymentResponse.new(seal, @data)
      response.should be_valid
    end

    [ :amount,
      :transaction_reference,
      :order_id,
      :response_code ].each do |requirement|
        it "should be invalid with missing param #{requirement}" do
          @data.gsub!(/#{requirement.to_s.camelize(:lower)}=[^|]*\|?/,"")
          seal = ::Digest::SHA2.hexdigest(@data + @payment_method.preferred_secret_key)
          response = Spree::OmnikassaPaymentResponse.new(seal, @data)
          response.should_not be_valid
        end
    end

    it 'should be invalid with incorrect seal for request' do
      seal = ::Digest::SHA2.hexdigest(@data + "abc")
      response = Spree::OmnikassaPaymentResponse.new(seal, @data)
      response.should_not be_valid
    end
  end

  describe 'attributes' do
    it 'should convert price from cents to BigDeclimal fraction' do
      response = Spree::OmnikassaPaymentResponse.new("123", "amount=2400")
      response.attributes[:amount].should == BigDecimal.new("24.00")
    end
  end

  describe "#payment" do
    before :each do
      @attrs = { :amount => BigDecimal.new("24900")/100,
          :order_id => 123,
          :payment_method_id => 1,
          :state => "processing" }
      @payment = mock_model( Spree::Payment, @attrs)
    end
    it 'should try to find a Spree::Payment' do
      Spree::Payment.stub(:find).and_return(@payment)
      Spree::Payment.should_receive(:find)
      Spree::OmnikassaPaymentResponse.new(@seal, @data).payment
    end
    it 'should find Spree::Payment by order_id' do
      stored_payment = Spree::Payment.new(@attrs)
      stored_payment.stub(:update_order).and_return true
      stored_payment.save

      data = "orderId=#{stored_payment.order_id}"
      res = Spree::OmnikassaPaymentResponse.new(@seal, data)
      res.payment.should == stored_payment
    end
    it 'should raise RecordNotFound if no payment is found' do
      Spree::Payment.stub(:find).and_return(nil)
      expect { Spree::OmnikassaPaymentResponse.new(@seal, @data).payment }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "#order" do
    it 'should try to find a Spree::Order by order_id' do
      Spree::Order.should_receive(:find).with(123)
      Spree::OmnikassaPaymentResponse.new(@seal, @data).order
    end
    it 'should raise a RecordNotFound of no order is found' do
      expect {
        Spree::OmnikassaPaymentResponse.new(@seal, @data).order
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "#response_level" do
    response_codes =
      {
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
    response_codes.each do |state, codes|
      codes.each do |code|
        it "should return #{state} for #{code}" do
          @data.gsub!(/(responseCode=)([^|]*)(\|?)/, '\1'+code.to_s+'\3')
          @payment_response = Spree::OmnikassaPaymentResponse.new(@seal, @data)
          @payment_response.response_level.should == state
        end
      end
    end
  end
end
