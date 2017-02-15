# pimatic-location

To use this app you need to install the Plugin "pimatic-location".
You need to add a device to your Pimatic config for each smartphone that should report it's location.

Plugin:

Simply add 
```
    {
      "plugin": "location"
    },
```
to your plugin configuration.

For each Device (Smartphone) you want to 'track', you need to create a corresponding device in your config.
Example:
```
    {
      "id": "your-phone",
      "name": "your-phone",
      "class": "LocationDevice",
      "lat": 52.5200066,
      "long": 13.404954
    },
```

If you want to use the Apple iCloud to locate your Devices your Device-Configuration should look like this:
```
    {
      "id": "your-phone",
      "name": "your-phone",
      "class": "LocationDevice",
      "lat": 52.5200066,
      "long": 13.404954,
      "iCloudUser": "Username",
      "iCloudPass": "Password",
      "iCloudDevice": "DeviceName",
      "iCloudInterval": 60000
    },
```

Optional parameters for each Device:
```
      "useGoogleMaps": true,
      "googleMapsApiKey": "your-api-key-here"      
```
With the optional parameter "useGoogleMaps" you can optionaly disable the usage of GoogleMaps. (You no longer get a route-distance, eta or address)
With the parameter "googleMapsApiKey" you can define your own ApiKey, if you got to many googleMapsApi-requests running.
You can obtain a ApiKey in the Google developers console https://console.developers.google.com . You need also to activate the "Directions API" in your account.

The lat and long values correspond to the location you want the distance to be calculated.
You can use this website to get your longitude and latitude.
http://www.mapcoordinates.net/en

Use "xAttributeOptions" to manage which attributes of the tracked device will be visible in the web frontend.
```
      "xAttributeOptions": [
        {
          "name": "updateTimeSpec",
          "displaySparkline": false,
          "hidden": true
        },
        {
          "name": "updateTimeStamp",
          "displaySparkline": false,
          "hidden": true
        },
        {
          "name": "currentLat",
          "displaySparkline": false,
          "hidden": true
        },
        {
          "name": "currentLong",
          "displaySparkline": false,
          "hidden": true
        },
        {
          "name": "linearDistance",
          "displaySparkline": true,
          "hidden": false
        },
        {
          "name": "routeDistance",
          "displaySparkline": true,
          "hidden": false
        },
        {
          "name": "eta",
          "displaySparkline": false,
          "hidden": false
        },
        {
          "name": "address",
          "displaySparkline": false,
          "hidden": false
        },
        {
          "name": "lastError",
          "displaySparkline": false,
          "hidden": true
        }
      ]

```

Additional information on how to track Android devices and at https://github.com/Oitzu/pimatic-location.  
