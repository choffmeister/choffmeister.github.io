requirejs.config
  baseUrl: "/src"
  paths:
    jquery: "../bower_components/jquery/jquery"
    bootstrap: "../bower_components/bootstrap/dist/js/bootstrap"

  shim:
    bootstrap:
      deps: ["jquery"]

requirejs [
  "jquery"
  "bootstrap"
], ($, bs) ->
  # bootstrap application
  $(document).ready () ->
    # do nothing
