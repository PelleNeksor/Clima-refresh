//
//  ViewController.swift
//  WeatherApp
//
//  Created by Angela Yu on 23/08/2015.
//  Copyright (c) 2015 London App Brewery. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire
import AlamofireImage
import SwiftyJSON

class WeatherViewController: UIViewController, CLLocationManagerDelegate, ChangeCityDelegate {
    
    //Constants
    let WEATHER_URL = "http://api.openweathermap.org/data/2.5/weather"
    
    let GOOGLE_MAPS_URL = "https://maps.googleapis.com/maps/api/place/textsearch/json"
    let GOOGLE_IMAGE_URL = "https://maps.googleapis.com/maps/api/place/photo"

    
   
    //DONE: Verplaats keys naar plist file
    let APP_ID = valueForAPIKey(named:"APP_ID")
    let GOOGLE_API_KEY = valueForAPIKey(named: "GOOGLE_API_KEY")
    
    // global variable
    public var cityGoogleMaps : String = ""
    public var photoReference : String = ""
    
    //DONE: Declare instance variables here
    let locationManager = CLLocationManager()
    let weatherDataModel = WeatherDataModel()
    let googleDataModel = GoogleDataModel()

    
    //Pre-linked IBOutlets
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!

    @IBOutlet weak var cityPicture: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
    }
    
    //MARK: - Networking
    /***************************************************************/
    
    //Write the getWeatherData method here:
    func getWeatherData(url: String, parameters: [String : String] ) {
        
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON {
            response in
            if response.result.isSuccess {
                print("Succes! Got the data")
                
                let weatherJSON : JSON = JSON(response.result.value!)
                self.updateWeatherdata(json: weatherJSON)
                
            } else {
                print("Error \(response.result.error!)")
                self.cityLabel.text = ("Problem with internet")
            }
    
        }
        
    }
    
    func getCityPictureID(url: String, parameters: [String : String] ) {
        
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON {
            response in
            if response.result.isSuccess {
                print("Succes! Got the Google data")
                
                
                
                let googleJSON : JSON = JSON(response.result.value!)
        //        print(googleJSON)
                self.updateGoogleData(json: googleJSON)
                
                // nu de volgende Google call voor het plaatje
                
                let googleParamsImage : [String : String] = ["photoreference" : self.googleDataModel.googlePhotoReference, "key" : self.GOOGLE_API_KEY, "maxwidth" : "1200"]
                
                print("Image URL is:\(googleParamsImage)")
                
                self.getCityPictureURL(url: self.GOOGLE_IMAGE_URL, parameters: googleParamsImage)
                
            } else {
                print("Error \(response.result.error!)")
                self.cityLabel.text = ("Problem with reaching to Google")
            }
            
        }
    }


    func getCityPictureURL(url: String, parameters: [String : String] ) {
        
        Alamofire.request(url, method: .get, parameters: parameters).responseImage {
            response in
            if response.result.isSuccess {
                print("Succes! Got the picture")
                
                if let image = response.result.value {
                    self.cityPicture.image = image
                }
                
                
             //   let googleJSON : JSON = JSON(response.result.value!)
             //   print(googleJSON)
                
                
            } else {
                print("Error getCityPictureURL \(response.result.error!)")
                self.cityLabel.text = ("Problem with internet")
            }
            
        }
    }
    

    
    //MARK: - JSON Parsing
    /***************************************************************/
   
    
    //Write the updateWeatherData method here:
    func updateWeatherdata(json: JSON) {
        
        if let tempResult = json["main"]["temp"].double {

        weatherDataModel.temperature = Int(tempResult - 273.15)
        
        weatherDataModel.city = json["name"].stringValue
            
        print(weatherDataModel.city)
            
        cityGoogleMaps = weatherDataModel.city
            
       // city = "Amsterdam"
        print(cityGoogleMaps)
        
        weatherDataModel.condition = json["weather"][0]["id"].intValue
        
        weatherDataModel.weatherIconName = weatherDataModel.updateWeatherIcon(condition: weatherDataModel.condition)
            
        updateWeatherUIWithWeatherData()
            
        // hier nu ook de Google call ivm asynchroon stad verkrijgen
            
        let googleParams : [String : String] = ["query" : cityGoogleMaps, "key" : GOOGLE_API_KEY]
            
        print(googleParams)
            
        getCityPictureID(url: GOOGLE_MAPS_URL, parameters: googleParams)
            
            
        } else {
            cityLabel.text = "Weather unavailable"
        }
    }

    func updateGoogleData(json: JSON) {
        
        if let tempResult = json["results"][0]["photos"][0]["photo_reference"].string {
            
            googleDataModel.googlePhotoReference = tempResult
            
            photoReference = tempResult
            
            print("foto ref: \(tempResult)")
            
            updateWeatherUIWithWeatherData()
            
        } else {
            
            cityLabel.text = "F*CK"
        }
    }
    
    
    
    
    //MARK: - UI Updates
    /***************************************************************/
    
    
    //Write the updateUIWithWeatherData method here:
    func updateWeatherUIWithWeatherData() {
        
        cityLabel.text = weatherDataModel.city
        temperatureLabel.text = "\(weatherDataModel.temperature)°"
        weatherIcon.image = UIImage(named: weatherDataModel.weatherIconName)
        
        
    }
    
    
    
    
    
    //MARK: - Location Manager Delegate Methods
    /***************************************************************/
    
    
    //Write the didUpdateLocations method here:
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[locations.count - 1]
        if location.horizontalAccuracy > 0 {
            locationManager.stopUpdatingLocation()
            print("longitude = \(location.coordinate.longitude), latitude = \(location.coordinate.latitude)")
            
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            
            let params : [String : String] = ["lat" : String(latitude), "lon" : String(longitude), "appid" : APP_ID]
            
            getWeatherData(url: WEATHER_URL, parameters: params)
           
        }
    }
    
    
    //Write the didFailWithError method here:
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
        cityLabel.text = "Location unavailable"
    }
    
    

    
    //MARK: - Change City Delegate methods
    /***************************************************************/
    
    
    //Write the userEnteredANewCityName Delegate method here:
    func userEnteredANewCityName(city: String) {
        print(city)
        
        let params : [String : String] = ["q" : city, "appid" : APP_ID]
        
        getWeatherData(url: WEATHER_URL, parameters: params)
    }

    
    //Write the PrepareForSegue Method here
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "changeCityName" {
            
            let destinationVC = segue.destination as! ChangeCityViewController
            
            destinationVC.delegate = self
        }
    }
    

    

    
    
    
}


