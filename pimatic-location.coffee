module.exports = (env) ->
  # Require the  bluebird promise library
  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'

  gmaputil = require 'googlemapsutil'
  geolib = require 'geolib'
  
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
      linearDistance:
        description: "Linear distance between the devices."
        type: "number"
        unit: "m"
      routeDistance:
        description: "Distance between the devices by road."
        type: "number"
        unit: "m"
      eta:
        description: "Estimated time of arrival."
        type: "number"
        unit: "s"
      address:
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
      
      

    getLinearDistance: -> Promise.resolve(@_linearDistance)
    getRouteDistance: -> Promise.resolve(@_routeDistance)
    getEta: -> Promise.resolve(@_eta)
    getAddress: -> Promise.resolve(@_address)
    
    updateLocationCB: (err, result) ->
      if err
        env.logger.error(err)
      else
        try
          data = JSON.parse result
          route_distance = data['routes'][0]['legs'][0]['distance']['value']
          eta = data['routes'][0]['legs'][0]['duration']['value']
          address = data['routes'][0]['legs'][0]['start_address']
        
          @_routeDistance = route_distance
          @_eta = eta
      
          _this.emit 'routeDistance', route_distance
          _this.emit 'eta', eta
          if addressUpdate is 1
            @_address = address
            _this.emit 'address', @_address
          else
            @_address = '-'
            _this.emit 'address', @_address
        catch error
          env.logger.error("Didn't received correct Gmaps-Api response!")
          env.logger.debug("Gmaps-Api response: "+result)
          
          
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
     
      @_linearDistance = linearDistance
      @emit 'linearDistance', @_linearDistance
      
      _this = this

      if @useMaps is true
        gmaputil.directions(start_loc, end_loc, null, @updateLocationCB, true)
        
      return Promise.resolve()
    
  # ###Finally
  # Create a instance of my plugin
  pimaticLocation = new PimaticLocation
  # and return it to the framework.
  return pimaticLocation
