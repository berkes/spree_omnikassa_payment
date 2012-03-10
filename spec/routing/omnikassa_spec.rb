require "spec_helper"

describe "routes to the omnikassa payments controller" do

  before(:each) { @routes = Spree::Core::Engine.routes }

  it "routes to :homecoming" do
    { :post => "omnikassa_payments/homecoming" }.should route_to("spree/omnikassa_payments#homecoming")
  end
  it "routes to :response" do
    { :post => "omnikassa_payments/reply" }.should route_to("spree/omnikassa_payments#reply")
  end
end
