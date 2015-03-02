module.exports = {
  title: "pimatic-location device config schemas"
  LocationDevice: {
    title: "LocationDevice config options"
    type: "object"
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
  }
}