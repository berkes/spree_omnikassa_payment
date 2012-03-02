Spree::Core::Engine.routes.prepend do
# SpreeOmnikassa::Engine.routes.draw do
  post 'omnikassa_payments/return', :to => 'omnikassa_payments#return'
end
