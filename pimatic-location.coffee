module.exports = (env) ->
  # Require the  bluebird promise library
  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'

  gmaputil = env.require 'googlemapsutil'
  
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
  
    _this = this
  
    constructor: (@config) ->
      @name = config.name
      @id = config.id
      @pimaticLat = config.lat
      @pimaticLong = config.long
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
        unit: "s"
      }
      
      @attributes.Address = {
        description: "Current Address."
        type: "string"
      }
      
      @actions = {}
      
      @actions.updateLocation = {
        discriptions: "Updates the location of the Device."
        params:
          long:
            type: "number"
          lat:
            type: "number"
      }
      
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
      
      _this = this
      
      super()

    getLinearDistance: -> Promise.resolve(@_LinearDistance)
    getRouteDistance: -> Promise.resolve(@_RouteDistance)
    getETA: -> Promise.resolve(@_ETA)
    getAddress: -> Promise.resolve(@_Address)
    
    updateLocationCB: (err, result) ->
      if err
        env.logger.error(err)
      else
        data = JSON.parse result
        route_distance = data['routes'][0]['legs'][0]['distance']['value']
        eta = data['routes'][0]['legs'][0]['duration']['value']
        address = data['routes'][0]['legs'][0]['start_address']

        @_LinearDistance = 0
        @_RouteDistance = route_distance
        @_ETA = eta
        @_Address = address
      
        _this.emit 'LinearDistance', 0
        _this.emit 'RouteDistance', route_distance
        _this.emit 'ETA', eta
        _this.emit 'Address', address

      return Promise.resolve();
    
    updateLocation: (long, lat, updateAddress) ->
      start_loc = {
        lat: lat
        lng: long
      }
      end_loc = {
        lat: @pimaticLat
        lng: @pimaticLong
      }
      gmaputil.directions(start_loc, end_loc, null, @updateLocationCB, true)
      return Promise.resolve()
    
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