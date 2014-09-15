wrap = (resource, method, params) ->
  Stripe = StripeAPI(Billing.settings.secretKey)
  call = Async.wrap Stripe[resource], method
  try
    call params
  catch e
    console.error e
    throw new Meteor.Error 500, e.message


Meteor.methods

  #
  # Creates stripe customer then updates the user document with the stripe customerId and cardId
  #
  createCustomer: (userId, card) ->
    unless meOrAdmin(userId) then throw new Meteor.Error 404, "Not authorized"
    user = Meteor.users.findOne(userId)
    unless user then throw new Meteor.Error 404, "User not found.  Customer cannot be created."
    console.log 'Creating customer for', user._id

    Stripe = StripeAPI(Billing.settings.secretKey)
    create = Async.wrap Stripe.customers, 'create'
    try
      email = if user.registered_emails then user.registered_emails[0].address else ''
      customer = create
        email: email
        card: card.id
        metadata: _.pick (user.profile or {}), "firstName", "lastName"
      Meteor.users.update _id: user._id,
        $set: 'billing.customerId': customer.id, 'billing.cardId': customer.default_card
    catch e
      console.error e
      throw new Meteor.Error 500, e.message

  #
  # Create a card on a customer and set cardId
  #
  createCard: (userId, card) ->
    unless meOrAdmin(userId) then throw new Meteor.Error 404, "Not authorized"
    user = Meteor.users.findOne(userId)
    unless user then throw new Meteor.Error 404, "User not found.  Card cannot be created."
    console.log 'Creating card for', user._id

    Stripe = StripeAPI(Billing.settings.secretKey)
    createCard = Async.wrap Stripe.customers, 'createCard'
    try
      card = createCard user.billing.customerId, card: card.id
      Meteor.users.update user._id, 
        $set:
          'billing.cardId': card.id
    catch e
      console.error e
      throw new Meteor.Error 500, e.message

  #
  #  Get details about a customers credit card
  #
  retrieveCard: (userId) ->
    unless meOrAdmin(userId) then throw new Meteor.Error 404, "Not authorized"
    user = Meteor.users.findOne(userId)
    unless user then throw new Meteor.Error 404, "User not found.  Cannot retrieve card info."
    unless user.billing?.cardId then throw new Meteor.Error 404, "No payment method on file."
    console.log "Retrieving card for #{user.billing.customerId}"

    Stripe = StripeAPI(Billing.settings.secretKey)
    retrieveCard = Async.wrap Stripe.customers, 'retrieveCard'
    try
      retrieveCard user.billing.customerId, user.billing.cardId
    catch e
      console.log e
      throw new Meteor.Error 500, e.message

  #
  # Delete a card on customer and unset cardId
  #
  # deleteCard: (userId) ->
  #   unless meOrAdmin(userId) then throw new Meteor.Error 404, "Not authorized"
  #   user = Meteor.users.findOne(userId)
  #   unless user then throw new Meteor.Error 404, "User not found.  Card cannot be deleted."
  #   console.log 'Deleting card for', user._id

  #   Stripe = StripeAPI(Billing.settings.secretKey)
  #   deleteCard = Async.wrap Stripe.customers, 'deleteCard'
  #   try
  #     card = deleteCard user.billing.customerId, user.billing.cardId
  #     Meteor.users.update _id: user._id,
  #       $set:
  #         'billing.cardId': null
  #   catch e
  #     console.error e
  #     throw new Meteor.Error 500, e.message

  #
  # Create a single one-time charge
  #
  # createCharge: (params) ->
  #   console.log "Creating charge"
  #   wrap 'charges', 'create', params

  #
  # List charges with any filters applied
  #
  # listCharges: (params) ->
  #   console.log "Getting past charges"
  #   wrap 'charges', 'list', params


  #
  # Update stripe subscription for user with provided plan and quantitiy
  #
  # updateSubscription: (userId, params) ->
  #   unless meOrAdmin(userId) then throw new Meteor.Error 404, "Not authorized"
  #   user = Meteor.users.findOne(userId)
  #   if user then customerId = user.billing?.customerId
  #   unless user and customerId then new Meteor.Error 404, "User not found.  Subscription cannot be updated."
  #   console.log 'Updating subscription for', user._id
  #   if user.billing.waiveFees or user.billing.admin then return

  #   Stripe = StripeAPI(Billing.settings.secretKey)
  #   updateSubscription = Async.wrap Stripe.customers, 'updateSubscription'
  #   try
  #     subscription = updateSubscription customerId, params
  #     Meteor.users.update _id: user._id,
  #       $set: 
  #         'billing.subscriptionId': subscription.id
  #         'billing.planId' : params.plan
  #   catch e
  #     console.error e
  #     throw new Meteor.Error 500, e.message

  #
  # Manually cancels the stripe subscription for the provided customerId
  #
  # cancelSubscription: (userId) ->
  #   unless meOrAdmin(userId) then throw new Meteor.Error 404, "Not authorized"
  #   user = Meteor.users.findOne(userId)
  #   unless user then new Meteor.Error 404, "User not found.  Subscription cannot be canceled."
  #   console.log 'Canceling subscription for', user._id

  #   Stripe = StripeAPI(Billing.settings.secretKey)
  #   cancelSubscription = Async.wrap Stripe.customers, 'cancelSubscription'
  #   try
  #     cancelSubscription user.billing.customerId
  #   catch e
  #     console.error e
  #     throw new Meteor.Error 500, e.message


  #
  # A subscription was deleted from Stripe, remove subscriptionId and card from user.
  #
  # subscriptionDeleted: (customerId) ->
  #   console.log 'Subscription deleted for', customerId
  #   user = Meteor.users.first('billing.customerId': customerId)
  #   unless user then new Meteor.Error 404, "User not found.  Subscription cannot be deleted."
  #   Meteor.users.update _id: user._id,
  #     $set:
  #       'billing.subscriptionId': null
  #       'billing.planId': null


  #
  # Get past invoices
  #
  getInvoices: (userId) ->
    unless meOrAdmin(userId) then throw new Meteor.Error 404, "Not authorized"
    user = Meteor.users.findOne(userId)
    unless user then new Meteor.Error 404, "User not found.  Cannot fetch invoices."    
    console.log 'Getting past invoices for', user._id

    Stripe = StripeAPI(Billing.settings.secretKey)
    if user.billing
      customerId = user.billing.customerId
      try
        invoices = Async.wrap(Stripe.invoices, 'list')(customer: customerId)
      catch e
        console.error e
        throw new Meteor.Error 500, e.message
      invoices
    else
      throw new Meteor.Error 404, "No subscription"


  #
  # Get next invoice
  #
  getUpcomingInvoice: (userId) ->
    unless meOrAdmin(userId) then throw new Meteor.Error 404, "Not authorized"
    user = Meteor.users.findOne(userId)
    unless user then new Meteor.Error 404, "User not found.  Cannot fetch  upcoming invoice."    

    console.log 'Getting upcoming invoice for', user._id
    Stripe = StripeAPI(Billing.settings.secretKey)

    if user.billing
      customerId = user.billing.customerId
      try
        invoice = Async.wrap(Stripe.invoices, 'retrieveUpcoming')(customerId)
      catch e
        console.error e
        throw new Meteor.Error 500, e.message
      invoice
    else
      throw new Meteor.Error 404, "No subscription"
