Spree::Core::Engine.routes.prepend do
# SpreeOmnikassa::Engine.routes.draw do
  post 'omnikassa_payments/homecoming', :to => 'omnikassa_payments#homecoming'
  post 'omnikassa_payments/reply', :to => 'omnikassa_payments#reply'
end
