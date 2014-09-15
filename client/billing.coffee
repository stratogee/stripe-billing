Result = ->
  _dep: new Deps.Dependency
  _val: null
  _hasRun: false

  _get: ->
    @_dep.depend()
    @_val
  
  _set: (val) ->
    unless EJSON.equals @_val, val
      @_val = val
      @_dep.changed()


@Billing =
  settings:
    publishableKey: ''
    requireAddress: false
    requireName: false
    showInvoicePeriod: true
    showPricingPlan: true
    invoiceExplaination: ''
    currency: '$'
    language: 'en'
    ddBeforeMm: false #for countries with date format dd/mm/yyyy

  config: (opts) ->
    @settings = _.extend @settings, opts
    T9n.language = @settings.language

  isValid: ->
    $('form#billing-creditcard').parsley().validate()
    
  createToken: (form, callback) ->
    Stripe.setPublishableKey(@settings.publishableKey);
    $form = $(form)
    Stripe.card.createToken(
      name: $(form).find('[name=cc-name]').val()
      number: $form.find('[name=cc-num]').val()
      exp_month: $form.find('[name=cc-exp-month]').val()
      exp_year: $form.find('[name=cc-exp-year]').val()
      cvc: $form.find('[name=cc-cvc]').val()
      address_line1: $form.find('[name=cc-address-line-1]').val()
      address_line2: $form.find('[name=cc-address-line-2]').val()
      address_city: $form.find('[name=cc-address-city]').val()
      address_state: $form.find('[name=cc-address-state]').val()
      address_zip: $form.find('[name=cc-address-zip]').val()      
    , callback) # callback(status, response)

  _results: {}

  getResults: (methodName) ->
    unless @_results[methodName]
      @_results[methodName] = new Result

    # Get the result
    res = @_results[methodName]._get()

    # If its an error object - return falsy value
    if res.error then res = null else res

    # Null out to ensure fresh data subsequent calls
    if res then @_results[methodName] = null

    # Return it!
    res

  call: (methodName, params) ->
    results = @_results
    
    unless results[methodName]
      results[methodName] = new Result
    
    unless results[methodName]._hasRun
      results[methodName]._hasRun = true
      args = Array.prototype.splice.call arguments, 1
      Meteor.apply methodName, args, (err, res) ->
        results[methodName]._set if err then err else res

    ready: ->
      res = results[methodName]._get()
      if res then true else false