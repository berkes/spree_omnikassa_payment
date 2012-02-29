require "spec_helper"

describe Spree::PaymentMethod::Omnikassa do
  before :each do
    @payment = mock_model(Spree::Payment, :amount => 100)
    @omnikassa = Spree::PaymentMethod::Omnikassa.new
  end

  describe "preferences" do
    [
      :merchant_id,
      :key_version
    ].each do |pref|
      it "should have the preference: #{pref}" do
        @omnikassa.should have_preference pref
      end
    end #each
  end

  describe "#actions" do
    it 'should have "capture" action' do
      @omnikassa.actions.include?("capture").should be_true
    end
  end
  describe "#can_" do
    ["checkout", "pending"].each do |state|
      it "a payment with state '#{state}' can_capture?" do
        @payment.stub("state").and_return(state)
        @omnikassa.can_capture?(@payment).should be_true
      end
    end
  end
  describe "#capture" do
    it 'should set payment state to complete' do
      @payment.stub("state").and_return("pending")
      @payment.stub("complete")
      @payment.should_receive("complete")
      @omnikassa.capture(@payment)
    end
  end
  describe "#process" do
    it 'should be registered by setting source_required? to true' do
      @omnikassa.source_required?.should be_true
    end
  end

  describe "#url" do
    it 'should return the staging url for payment gateways not in production' do
      @omnikassa.environment = "development"
      @omnikassa.url.should == "https://payment-webinit.simu.omnikassa.rabobank.nl/paymentServlet"
    end
    it 'should return the production url for payment gateways in production' do
      @omnikassa.environment = "production"
      @omnikassa.url.should == "https://payment-webinit.omnikassa.rabobank.nl"
    end
  end
  
  describe "self#fetch_payment_method" do
    it 'should find a payment_method' do
      pending "Find out how to mock and stub a call to Spree::PaymentMethod.select"
      @omnikassa_anon.fetch_payment_method.should be_a_kind_of(Spree::PaymentMethod)
    end
    it 'should only return a payment_method with "omni" in the name' do
      pending "Find out how to mock and stub a call to Spree::PaymentMethod.select"
      @omnikassa_anon.fetch_payment_method.name.should =~ /omni/
    end
  end
end
