Package.describe({
  summary: "Various stripe billing functionality packaged up.",
  version: "1.0.0",
  git: " \* Fill me in! *\ "
});

Package.onUse(function(api) {
  api.versionsFrom('METEOR@0.9.1.1');

  api.use([
    'templating',
    'jquery',
    'deps',
    'accounts-t9n'
  ], 'client');

  api.use([
    'accounts-password',
    'meteorhacks:npm',
    'hellogerard:reststop2'
  ], 'server');

  api.use([
    'coffeescript',
  ], ['client', 'server']);

  api.addFiles([
    'client/views/creditCard/creditCard.html',
    'client/views/creditCard/creditCard.styl',
    'client/views/creditCard/creditCard.coffee',
    'client/views/invoices/invoices.html',
    'client/views/invoices/invoices.coffee',
    'client/views/invoices/invoices.styl',
    'client/views/currentCreditCard/currentCreditCard.html',
    'client/views/currentCreditCard/currentCreditCard.coffee',
    'client/startup.coffee',
    'client/billing.coffee',
    'public/img/credit-cards.png',
    'public/img/cvc.png',
    'client/i18n/english.coffee'
  ], 'client');

  api.addFiles([
    'server/startup.coffee',
    'server/billing.coffee',
    'server/methods.coffee',
    'server/webhooks.coffee'
  ], 'server');
});

Package.onTest(function(api) {
  api.use('tinytest');
  api.use('stratogee:stripe-billing');
  api.addFiles('stratogee:stripe-billing-tests.js');
});
