module.exports = (env) ->
  # Require the  bluebird promise library
  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'

  gmaputil = require 'googlemapsutil-https'
  geolib = require 'geolib'
  iPhoneFinder = require 'iphone-finder'
  
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
      @name = @config.name
      @id = @config.id
      @pimaticLat = @config.lat
      @pimaticLong = @config.long
      @useMaps = @config.useGoogleMaps
      @apiKey = @config.googleMapsApiKey
      @iCloudUser = @config.iCloudUser
      @iCloudPass = @config.iCloudPass
      @iCloudDevice = @config.iCloudDevice
      @iCloudInterval = @config.iCloudInterval

      @_lastError = "Success"

      @attributes = {
        updateTimeStamp:
          label: "Update timestamp"
          description: "UTC Timestamp (seconds) of the last location update."
          type: "number"
          unit: "s"
          acronym: 'UTC'
          displaySparkline: false
          hidden: true
        updateTimeSpec:
          label: "Update time spec"
          description: "Date and time of the last location update."
          type: "string"
          unit: ""
          acronym: 'DT'
          displaySparkline: false
          hidden: false
        currentLat:
          label: "Current latitude"
          description: "Current latitude of the devices."
          type: "number"
          unit: "°"
          acronym: 'LAT'
          displaySparkline: false
          hidden: true
        currentLong:
          label: "Current longitude"
          description: "Current longitude of the devices."
          type: "number"
          unit: "°"
          acronym: 'LONG'
          displaySparkline: false
          hidden: true
        linearDistance:
          label: "Linear Distance"
          description: "Linear distance between the devices."
          type: "number"
          unit: "m"
          acronym: 'DIST'
      }

      if @useMaps
        @attributes.routeDistance = {
          label: "Route Distance"
          description: "Distance between the devices by road."
          type: "number"
          unit: "m"
          acronym: 'ROAD'
        }
        @attributes.eta = {
          label: "ETA"
          description: "Estimated time of arrival."
          type: "number"
          unit: "s"
          acronym: 'ETA'
        }
        @attributes.address = {
          label: "Address"
          description: "Current Address."
          type: "string"
          acronym: 'ADRS'
        }

      @attributes.lastError = {
        label: "Last error"
        description: "Description of last error."
        type: "string"
        acronym: 'ERR'
        displaySparkline: false
        hidden: true
      }

      if @iCloudUser isnt "0" and @iCloudPass isnt "0" and @iCloudDevice isnt "0"
        @findIPhone()
        @intervalId = setInterval( ( =>
          @findIPhone()
        ), @iCloudInterval)

      super()

    destroy: () ->
      clearInterval @intervalId if @intervalId?
      super()

    processIDevice: (device) =>
      env.logger.debug("Enumerate Device with name:"+ device.name + ". Searching for " + @iCloudDevice)
      if device.name is @iCloudDevice
        env.logger.debug("Matched Device with name:"+ device.name)
        if device.location?
          @updateLocation(device.location.longitude, device.location.latitude, 1)
        else
          env.logger.debug("Didn't get a valid location for Device "+device.name)

    findIPhone: () ->
      @_lastError = "Success"
      try
        iPhoneFinder.findAllDevices(@iCloudUser, @iCloudPass, (err, devices) =>
          if err
            @_lastError = err.toString()
            @emit 'lastError', @_lastError
            env.logger.error(err)
          else
            env.logger.debug("Got iCloud response. Enumerating Devices.")
            @processIDevice device for device in devices
        )
      catch error
        env.logger.error(@iCloudUser + ": couldn't connect to iCloud!")
    
    getLinearDistance: -> Promise.resolve(@_linearDistance)
    getRouteDistance: -> Promise.resolve(@_routeDistance)
    getEta: -> Promise.resolve(@_eta)
    getAddress: -> Promise.resolve(@_address)

    getUpdateTimeStamp: -> Promise.resolve(@_updateTimeStamp)
    getUpdateTimeSpec: -> Promise.resolve(@_updateTimeSpec)
    getCurrentLat: -> Promise.resolve(@_currentLat)
    getCurrentLong: -> Promise.resolve(@_currentLong)

    getLastError: -> Promise.resolve(@_lastError)

    updateLocation: (long, lat, updateAddress) ->
      @_lastError = "Success"
      timestamp = new Date()
      start_loc = {
        lat: lat
        lng: long
      }
      end_loc = {
        lat: @pimaticLat
        lng: @pimaticLong
      }
      
      env.logger.debug(
        "Received: long=#{long} lat=#{lat} updateAddress=#{updateAddress} from #{@name} at #{timestamp}"
      )

      @_updateTimeSpec = timestamp.format 'YYYY-MM-DD hh:mm:ss'
      @emit 'updateTimeSpec', @_updateTimeSpec

      @_updateTimeStamp = parseInt(timestamp.getTime()/1000, 10)
      @emit 'updateTimeStamp', @_updateTimeStamp

      @_currentLat = lat
      @emit 'currentLat', @_currentLat

      @_currentLong = long
      @emit 'currentLong', @_currentLong
      
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
            @_lastError = err.toString()
            @emit 'lastError', @_lastError
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
              @_lastError = result
              @emit 'lastError', @_lastError
              env.logger.error("Didn't received correct Gmaps-Api response!")
              env.logger.debug("Gmaps-Api response: "+result)
          return  
        
        gmaputil.directions(start_loc, end_loc, options, updateLocationCB, true, use_ssl)

        # clear error message on success
        @emit 'lastError', @_lastError

      return Promise.resolve()
    
  # ###Finally
  # Create a instance of my plugin
  pimaticLocation = new PimaticLocation
  # and return it to the framework.
  return pimaticLocation
