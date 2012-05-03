require "spec_helper"

describe Spree::OmnikassaPaymentRequest do
  before :each do
    @amount = BigDecimal.new("12.99")
    @order_id = "123"

    @merchant_id = "123abc"
    @key_version = "1"
    @secret_key = "002020000000001_KEY1"

    @pm = Spree::PaymentMethod::Omnikassa.new(:name => "Omnikassa")
    @pm.save
    @pm.preferred_merchant_id = @merchant_id
    @pm.preferred_key_version = @key_version
    @pm.preferred_secret_key = @secret_key

    @transaction_reference = @merchant_id + @order_id.to_s

    @request = Spree::OmnikassaPaymentRequest.new(@amount, @transaction_reference)
  end
  describe '#initialize' do
    it 'should require amount and transaction_reference' do
      Spree::OmnikassaPaymentRequest.should_receive(:new).with(@amount, @transaction_reference).and_return(Spree::OmnikassaPaymentRequest)
      Spree::OmnikassaPaymentRequest.new(@amount, @transaction_reference)
    end
    it 'should raise an error if the merchant-id is not part of the transaction_reference' do
      expect {
        Spree::OmnikassaPaymentRequest.new(@amount, "123")
      }.to raise_error(RuntimeError, "transactionReference cannot be parsed")
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
    it 'should include a normalReturnUrl' do
      @request.data.should =~ name_value_pair_re('normalReturnUrl', 'http:\/\/*')
    end
    it 'should include a order_id' do
      @request.data.should =~ name_value_pair_re('orderId', '123')
    end
    it 'should have the full url to "OmnikassaPaymentsController#homecoming", with "preferred_site_url" as base, as normalReturnUrl' do
      # @TODO find out how to include url_helpers here.
      # url_for(:controller => 'omnikassa_payments', :action => 'homecoming', :host => Spree::Config.preferred_site_url))
      @request.data.should =~ name_value_pair_re('normalReturnUrl', "http://#{Spree::Config.preferred_site_url}/omnikassa_payments/homecoming")
    end
    it 'should have the full url to "OmnikassaPaymentsController#reply", with "preferred_site_url" as base, as normalReturnUrl' do
      # @TODO find out how to include url_helpers here.
      # url_for(:controller => 'omnikassa_payments', :action => 'homecoming', :host => Spree::Config.preferred_site_url))
      @request.data.should =~ name_value_pair_re('automaticResponseUrl', "http://#{Spree::Config.preferred_site_url}/omnikassa_payments/reply")
    end
    it 'should return amount as price in cents' do
      @request.data.should =~ name_value_pair_re('amount', '1299')
    end
    it 'should include a transactionReference' do
      @request.data.should =~ name_value_pair_re('transactionReference', @merchant_id + '\d+')
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

  describe "#build_transaction_reference" do
    it 'should take order_id and append the preferred_merchant_id to it.' do
      Spree::OmnikassaPaymentRequest.build_transaction_reference(@order_id).should eq @transaction_reference
    end
  end
end

def name_value_pair_re(name, value)
  Regexp.new("#{name}=#{value}")
end
