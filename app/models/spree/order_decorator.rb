Spree::Order.class_eval do
  # StateMachine::Machine.ignore_method_conflicts = true
  # Spree::Order.state_machines[:state] = StateMachine::Machine.new(Spree::Order, :initial => 'cart', :use_transactions => false)  do
  #   event :next do
  #     transition :from => 'cart',     :to => 'address'
  #     transition :from => 'address',  :to => 'delivery'
  #     transition :from => 'delivery', :to => 'complete'
  #     transition :from => 'confirm',  :to => 'complete'
  #   end

  #   event :cancel do
  #     transition :to => 'canceled', :if => :allow_cancel?
  #   end
  #   event :return do
  #     transition :to => 'returned', :from => 'awaiting_return'
  #   end
  #   event :resume do
  #     transition :to => 'resumed', :from => 'canceled', :if => :allow_resume?
  #   end
  #   event :authorize_return do
  #     transition :to => 'awaiting_return'
  #   end

  #   before_transition :to => ['delivery'] do |order|
  #     order.shipments.each { |s| s.destroy unless s.shipping_method.available_to_order?(order) }
  #   end

  #   after_transition :to => 'complete', :do => :finalize!
  #   after_transition :to => 'delivery', :do => :create_tax_charge!
  #   after_transition :to => 'resumed',  :do => :after_resume
  #   after_transition :to => 'canceled', :do => :after_cancel
  # end
end
