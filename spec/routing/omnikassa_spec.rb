require "spec_helper"

describe "routes to the omnikassa payments controller" do

  before(:each) { @routes = Spree::Core::Engine.routes }

  it "routes to :return" do
    # pending "Somehow cannot get the routes included in the tests"
    { :post => "omnikassa_payments/return" }.should route_to("spree/omnikassa_payments#return")
  end
end
