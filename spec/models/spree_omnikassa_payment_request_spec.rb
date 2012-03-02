require "spec_helper"

describe Spree::OmnikassaPaymentRequest do
  before :each do
    @amount = BigDecimal.new("12.99")
    @order_id = 123

    @merchant_id = "123abc"
    @key_version = "1"
    @secret_key = "002020000000001_KEY1"

    @pm = Spree::PaymentMethod::Omnikassa.new(:name => "Omnikassa")
    @pm.save
    @pm.preferred_merchant_id = @merchant_id
    @pm.preferred_key_version = @key_version
    @pm.preferred_secret_key = @secret_key

    @request = Spree::OmnikassaPaymentRequest.new(@amount, @order_id)
  end
  describe '#initialize' do
    it 'should require amount and order_id' do
      Spree::OmnikassaPaymentRequest.should_receive(:new).with(@amount, @order_id).and_return(Spree::OmnikassaPaymentRequest)
      Spree::OmnikassaPaymentRequest.new(@amount, @order_id)
    end
  end

  describe "#data" do
    it 'should be delimited with a pipe' do
      @request.data.should =~ /(\w*=[^|]*\|){2,}/
    end

    it 'should include a numeric currencyCode' do
      @request.data.should =~ name_value_pair_re('currencyCode', '[0-9]+')
    end
    it 'should include a numeric merchantId' do
      @request.data.should =~ name_value_pair_re('merchantId', @merchant_id)
    end
    it 'should include a numeric normalReturnUrl' do
      @request.data.should =~ name_value_pair_re('normalReturnUrl', 'http:\/\/*')
    end
    it 'should return amount as price in cents' do
      @request.data.should =~ name_value_pair_re('amount', '1299')
    end
    it 'should include a numeric transactionReference' do
      @request.data.should =~ name_value_pair_re('transactionReference', '*')
    end
    it 'should include a numeric keyVersion' do
      @request.data.should =~ name_value_pair_re('keyVersion', @key_version)
    end
  end

  describe '#interface_version' do
    it 'should return HP_1.0' do
      @request.interface_version.should == "HP_1.0"
    end
  end

  describe '#seal' do
    it 'should return the sha256 of data + secretkey' do
      @request.seal.should eq Digest::SHA2.hexdigest(@request.data + @secret_key)
    end
  end
end

def name_value_pair_re(name, value)
  Regexp.new("#{name}=#{value}")
end
