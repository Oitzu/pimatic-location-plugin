module.exports = (env) ->
  # Require the  bluebird promise library
  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'

  # ###PimaticLocation class
  class PimaticLocation extends env.plugins.Plugin

    # #####params:
    #  * `app` is the [express] instance the framework is using.
    #  * `framework` the framework itself
    #  * `config` the properties the user specified as config for your plugin in the `plugins` 
    #     section of the config.json file 
    #     
    # 
    init: (app, @framework, @config) =>
      deviceConfigDef = require("./device-config-schema")
      
      @framework.deviceManager.registerDeviceClass("LocationDevice", {
        configDef: deviceConfigDef.LocationDevice,
        createCallback: (config) =>
          device = new LocationDevice(config)
          return device
        })

    
  class LocationDevice extends env.devices.Device
    constructor: (@config) ->
      @name = config.name
      @id = config.id
      @attributes = {}

      @attributes.LinearDistance = {
        description: "Linear distance between the devices."
        type: "number"
        unit: "m"
      }
  
      @attributes.RouteDistance = {
        description: "Distance between the devices by road."
        type: "number"
        unit: "m"
      }
    
      @attributes.ETA = {
        description: "Estimated time of arrival."
        type: "number"
        unit: "min."
      }
      
      @actions = {}
      
      @actions.updateLinearDistance = {
        descriptions: "Updates the linear distance, called from the Android pimatic-location app"
        params:
          distance:
            type: "number"
      }
      
      @actions.updateRouteDistance = {
        descriptions: "Updates the route distance, called from the Android pimatic-location app"
        params:
          distance:
            type: "number"
      }
      
      @actions.updateETA = {
        descriptions: "Updates the ETA, called from the Android pimatic-location app"
        params:
          distance:
            type: "number"
      }
      
      super()

    getLinearDistance: -> Promise.resolve(@_LinearDistance)
    getRouteDistance: -> Promise.resolve(@_RouteDistance)
    getETA: -> Promise.resolve(@_ETA)
    
    updateLinearDistance: (distance) ->
      @_LinearDistance = distance
      env.logger.debug("New linear distance " + distance + " from device.")
      @emit 'LinearDistance', distance
      return Promise.resolve()
      
    updateRouteDistance: (distance) ->
      @_RouteDistance = distance
      env.logger.debug("New route distance " + distance + " from device.")
      @emit 'RouteDistance', distance
      return Promise.resolve()
      
    updateETA: (eta) ->
      @_ETA = eta
      env.logger.debug("New eta " + eta + " from device.")
      @emit 'ETA', eta
      return Promise.resolve()
    
  # ###Finally
  # Create a instance of my plugin
  pimaticLocation = new PimaticLocation
  # and return it to the framework.
  return pimaticLocation