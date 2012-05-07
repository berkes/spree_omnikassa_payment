require 'spec_helper'

describe Spree::CheckoutController do
  before(:each) do
    @routes = Spree::Core::Engine.routes  # render_views
  end
  let(:order) { mock_model(Spree::Order, :checkout_allowed? => true, :completed? => false, :update_attributes => true, :payment? => false, :insufficient_stock_lines => [], :coupon_code => nil).as_null_object }
  before { controller.stub :current_order => order, :current_user => Spree::User.anonymous! }
  #FUCK FUCKERDEFUCK. KUTSPREE. met zijn kut-dependencies faalt op een migratie die ik GODVERDOMME niet kan draaien. KUT.

  # it 'should remove the "payment"-step from the Order statemachine' do 
  #   Spree::Order.state_machine.states.map{|s| s.name}.should_not include 'payment'
  # end
  it 'should show omnikassa form on payment' do
    # order.state = 'payment'
    get :edit, {:state => 'payment'}
    view.should render_template('spree/checkout/omnikassa_edit')
  end
  it 'should successfully click the payment button' do
    pending "@TODO:Implement"
  end
end
