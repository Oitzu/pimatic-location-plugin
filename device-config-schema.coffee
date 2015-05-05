module.exports = {
  title: "pimatic-location device config schemas"
  LocationDevice: {
    title: "LocationDevice config options"
    type: "object"
    extensions: ["xAttributeOptions"]
    properties:
      lat:
        description: "Latitude of your home location"
        type: "number"
        default: 0
      long:
        description: "Longitude of your home location"
        type: "number"
        default: 0
      useGoogleMaps:
        description: "Use the Google Maps API to get Route Informations?"
        type: "boolean"
        default: true
      googleMapsApiKey:
        description: "Google Maps Api Key"
        type: "string"
        default: "0"
      iCloudUser:
        description: "iCloud User"
        type: "string"
        default: "0"
      iCloudPass:
        description: "iCloud Password"
        type: "string"
        default: "0"
      iCloudDevice:
        description: "iCloud Device"
        type: "string"
        default: "0"
      iCloudInterval:
        description: "iCloud Interval"
        type: "integer"
        default: 60000
  }
}
