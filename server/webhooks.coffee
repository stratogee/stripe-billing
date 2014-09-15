RESTstop.add 'stripe', ->
  console.log 'Recieving Webhook --- ', @params.type

  switch @params.type
    when 'invoice.payment_failed'
      RESTstop.call @, 'invoicePaymentFailed', @params
    # when 'charge.succeeded'
    #   RESTstop.call @, 'chargeSucceeded', @params
    when 'customer.subscription.updated'
      RESTstop.call @, 'customerSubscriptionUpdated', @params
    else
    	console.log @params.type, 'was ignored'