SpreeOmnikassa
==============

A [Spree payment method](http://guides.spreecommerce.com/payment_gateways.html) for the [Dutch Rabobank Omnikassa](http://www.rabobank.nl/bedrijven/producten/betalen_en_ontvangen/geld_ontvangen/rabo_omnikassa/). 

It was developed for [Anna Treurniet](http://annatreurniet.nl) and
mentioned in the [whitepaper on my blog](http://berk.es/2012/10/22/spree-on-budgethoster-site5/).

It was developed to "just work" and not more. It is unmaintained and
might not work. 

The reason for that is Spree's lack of any kind of support for offsite
payments. Omnikassa is offsite. And as such it needs to be hacked into
Spree; with many ugly overrides. 
On said site, it _works_, but this plugin breaks many things, due to the
hackish way it needs to override the checkout workflow.

* Coupons break; you cannot have coupons.
* You cannot run it togeter with other payment methods.
* Somehow the user-registration breaks, you can only run with anon users
  and even then in the backend some sub-sub-menu throws a 500-error.
* It is tightly coupled to Spree 1.0. And upgrading requires quit
  extensive hacks or re-doing parts of the decorators.

I am severely dissapointed in the stubborn nature of Spree in this. As
such, I have no plans to upgrade this to a recent version. I have no
plans to maintain it, untill maybe Spree becomes more of a DSL for
e-commerce rather then a complete, turnkey solution with all sorts of
assumptions. Assumptions such as "payments are always done through gateways".

Testing
-------

I had plans to maintain and continue this extension; Hence I started off the extension with Rspec-coverage. Feel free to fork and continue this extension and when doing so, consider updating or removing the RSpec specs.

Copyright (c) 2012 Bèr Kessels, released under the New BSD License
