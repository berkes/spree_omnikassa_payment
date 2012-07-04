require 'spec_helper'

describe Spree::CheckoutController do
  before(:each) do
    @pm = Spree::PaymentMethod::Omnikassa.new(:name => "Omnikassa", :environment => "test")
    @pm.save
    @pm.preferred_merchant_id = @merchant_id
    @pm.preferred_key_version = @key_version
    @pm.preferred_secret_key = @secret_key
    @routes = Spree::Core::Engine.routes  # render_views
  end
  let(:order) { mock_model(Spree::Order,
                           :checkout_allowed? => true,
                           :completed? => false,
                           :update_attributes => true,
                           :payment? => false,
                           :insufficient_stock_lines => [],
                           :coupon_code => nil,
                           :state => "payment",
                           :total => BigDecimal("123.45"),
                           :payments => []).as_null_object }
  before { controller.stub :current_order => order, :current_user => Spree::User.anonymous! }

  it 'should show omnikassa form on payment' do
    get :edit, {:state => 'payment'}
    response.should render_template('spree/checkout/omnikassa_edit')
  end
end
