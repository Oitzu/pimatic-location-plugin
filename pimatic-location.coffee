module.exports = (env) ->
  # Require the  bluebird promise library
  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'

  gmaputil = env.require 'googlemapsutil'
  geolib = env.require 'geolib'
  
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
        createCallback: (config) => new LocationDevice(config)
      })

    
  class LocationDevice extends env.devices.Device
  
    _this = this
    addressUpdate = 0;
    
    attributes:
      LinearDistance:
        description: "Linear distance between the devices."
        type: "number"
        unit: "m"
      RouteDistance:
        description: "Distance between the devices by road."
        type: "number"
        unit: "m"
      ETA:
        description: "Estimated time of arrival."
        type: "number"
        unit: "s"
      Address:
        description: "Current Address."
        type: "string"
        
    actions:
      updateLocation:
        description: "Updates the location of the Device."
        params:
          long:
            type: "number"
          lat:
            type: "number"
          updateAddress:
            type: "number"
        
    constructor: (@config) ->
      @name = config.name
      @id = config.id
      @pimaticLat = config.lat
      @pimaticLong = config.long
      @useMaps = config.useGoogleMaps
      super()
      
      _this = this
      
      

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
        
        @_RouteDistance = route_distance
        @_ETA = eta
      
        _this.emit 'RouteDistance', route_distance
        _this.emit 'ETA', eta
        if addressUpdate is 1
          @_Address = address
          _this.emit 'Address', @_Address
        else
          @_Address = '-'
          _this.emit 'Address', @_Address

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
      addressUpdate = updateAddress
      
      env.logger.debug("Received: long="+long+" lat="+lat+" updateAddress="+updateAddress+" from "+@name)
      
      linearDistance = geolib.getDistance(start_loc, end_loc)
     
      @_LinearDistance = linearDistance
      @emit 'LinearDistance', @_LinearDistance
      
      _this = this

      if @useMaps is true
        gmaputil.directions(start_loc, end_loc, null, @updateLocationCB, true)
        
      return Promise.resolve()
    
  # ###Finally
  # Create a instance of my plugin
  pimaticLocation = new PimaticLocation
  # and return it to the framework.
  return pimaticLocation