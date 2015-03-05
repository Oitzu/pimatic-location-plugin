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
  
    attributes:
      linearDistance:
        label: "Linear Distance"
        description: "Linear distance between the devices."
        type: "number"
        unit: "m"
        acronym: 'DIST'
      routeDistance:
        label: "Route Distance"
        description: "Distance between the devices by road."
        type: "number"
        unit: "m"
        acronym: 'ROAD'
      eta:
        label: "ETA"
        description: "Estimated time of arrival."
        type: "number"
        unit: "s"
        acronym: 'ETA'
      address:
        label: "Address"
        description: "Current Address."
        type: "string"
        acronym: 'ADRS'
        
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
      @apiKey = config.googleMapsApiKey
      super()

    getLinearDistance: -> Promise.resolve(@_linearDistance)
    getRouteDistance: -> Promise.resolve(@_routeDistance)
    getEta: -> Promise.resolve(@_eta)
    getAddress: -> Promise.resolve(@_address)

    updateLocation: (long, lat, updateAddress) ->
      start_loc = {
        lat: lat
        lng: long
      }
      end_loc = {
        lat: @pimaticLat
        lng: @pimaticLong
      }
      
      env.logger.debug(
        "Received: long=#{long} lat=#{lat} updateAddress=#{updateAddress} from #{@name}"
      )
      
      linearDistance = geolib.getDistance(start_loc, end_loc)
     
      @_linearDistance = linearDistance
      @emit 'linearDistance', @_linearDistance

      if @useMaps is true
        options = {}
        use_ssl = false
        if @apiKey isnt "0"
          use_ssl = true
          options = {
            key: @apiKey
          }

        updateLocationCB = (err, result) =>
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
          
              @emit 'routeDistance', route_distance
              @emit 'eta', eta
              if updateAddress is 1
                @_address = address
                @emit 'address', @_address
              else
                @_address = '-'
                @emit 'address', @_address
            catch error
              env.logger.error("Didn't received correct Gmaps-Api response!")
              env.logger.debug("Gmaps-Api response: "+result)
          return  
        
        gmaputil.directions(start_loc, end_loc, options, updateLocationCB, true, use_ssl)

      return Promise.resolve()
    
  # ###Finally
  # Create a instance of my plugin
  pimaticLocation = new PimaticLocation
  # and return it to the framework.
  return pimaticLocation
