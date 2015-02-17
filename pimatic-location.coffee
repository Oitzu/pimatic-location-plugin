module.exports = (env) ->
  # Require the  bluebird promise library
  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'

  # Include you own depencies with nodes global require function:
  #  
  #     someThing = require 'someThing'
  #  

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

      @attributes.linear_distance = {
        description: "Linear distance between the devices."
        type: "number"
        unit: "m"
      }
  
      @attributes.route_distance = {
        description: "Distance between the devices by road."
        type: "number"
        unit: "m"
      }
    
      @attributes.eta = {
        description: "Estimated time of arrival."
        type: "number"
        unit: "min."
      }
      super()
    
  # ###Finally
  # Create a instance of my plugin
  pimaticLocation = new PimaticLocation
  # and return it to the framework.
  return pimaticLocation