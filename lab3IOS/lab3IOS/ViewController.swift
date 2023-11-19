//
//  ViewController.swift
//  lab3IOS
//
//  Created by Sooraj Suresh Krishnan on 2023-11-15.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var searchTextField: UITextField!
    
    @IBOutlet weak var temperatureLabel: UILabel!
    
    @IBOutlet weak var locationLabel: UILabel!
    
    @IBOutlet weak var tempToggleSwitch: UISwitch!
    @IBOutlet weak var tempMetricLabel: UILabel!
    @IBOutlet weak var weatherConditionImage: UIImageView!
    @IBOutlet weak var weatherConditionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        searchTextField.delegate = self
        tempToggleSwitch.isOn = false
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        
        weatherConditionCustomize()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        loadWeather(search: searchTextField.text)
        print(textField.text ?? "")
        return true
    }
    
    let locationManager = CLLocationManager()
    
    private func weatherConditionCustomize(){
        let config = UIImage.SymbolConfiguration(paletteColors: [.systemBlue, .systemYellow])
        
        
        weatherConditionImage.preferredSymbolConfiguration = config
        weatherConditionImage.image = UIImage(systemName: "cloud.sun")
    }
   

    @IBAction func onLocationTapped(_ sender: UIButton) {
        locationManager.requestLocation()
//        locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
                guard let location = locations.last else { return }
                
                let geocoder = CLGeocoder()
                geocoder.reverseGeocodeLocation(location) { placemarks, error in
                    guard let placemark = placemarks?.first else { return }
                    
                    let locality = placemark.locality ?? ""
                    let country = placemark.country ?? ""
                    
                    DispatchQueue.main.async {
                        self.searchTextField.text = "\(locality), \(country)"
                    }
                    
                    self.loadWeather(search: self.searchTextField.text)
                    self.tempMetricLabel.text = "C"
                }
        }
            
        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            print(error.localizedDescription)
        }
    
    @IBAction func onSearchTapped(_ sender: UIButton) {
        loadWeather(search: searchTextField.text)
        tempMetricLabel.text = "\u{00B0}C"
    }
    
    private var weatherResponse: WeatherResponse?
    
    
    private func loadWeather(search: String?){
        guard let search = search else {
            return
        }
        guard  let Url = getUrl(query: search) else {
            print("could not get url")
            return
        }
        
        let session = URLSession.shared
        
        let dataTask = session.dataTask(with: Url) { data, response, error in
            print("network call is complete")
            
            guard error == nil else{
                print("recieve error")
                return
            }
            guard let data = data else{
                print("no data found")
                return
            }
            
            if let WeatherResponse =  self.parseJSON(data: data){
                print(WeatherResponse.location.name)
                print(WeatherResponse.current.temp_c)
                print(WeatherResponse.current.condition.text)
                
                self.weatherResponse = WeatherResponse
                
                DispatchQueue.main.async {
                    self.locationLabel.text = WeatherResponse.location.name
                    self.temperatureLabel.text = "\(WeatherResponse.current.temp_c)"
                    self.weatherConditionLabel.text = WeatherResponse.current.condition.text
                    self.updateWeatherConditionImage(code: WeatherResponse.current.condition.code)
                }
                
              
            }
            
        }
        
        dataTask.resume()
        
    }
    
    private func getUrl(query: String) -> URL? {
        let baseUrl = "https://api.weatherapi.com/v1/"
        let currentEndpoint = "current.json"
        let apiKey = "16b91d03db974920ba9202418232003"
        guard let url = "\(baseUrl)\(currentEndpoint)?key=\(apiKey)&q=\(query)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        
        return URL(string: url)
        

    }
    private func parseJSON(data: Data)->WeatherResponse?{
        let decoder = JSONDecoder()
        var weather: WeatherResponse?
        do {
            weather = try decoder.decode(WeatherResponse.self, from: data)
        } catch{
            print("error decording")
        }
        return weather
    }
    
    var isFahrenhiet = false
    
    @IBAction func onSwitchTapped(_ sender: UISwitch) {
        isFahrenhiet = sender.isOn
        tempMetricLabel.text = isFahrenhiet ? "\u{00B0}F" : "\u{00B0}C"
        
        if let temp = isFahrenhiet ? weatherResponse?.current.temp_f : weatherResponse?.current.temp_c {
            self.temperatureLabel.text = "\(temp)"
        }
    }
    
    
    func updateWeatherConditionImage(code: Int) {
        var symbolName = ""
        switch code {
        case 1000:
            symbolName = "sun.max.fill"
        case 1003:
            symbolName = "cloud.sun.fill"
        case 1006:
            symbolName = "cloud.fill"
        case 1009, 1063, 1072, 1150, 1153,1168, 1180, 1186, 1192, 1240:
            symbolName = "cloud.drizzle.fill"
        case 1030,1135,1147:
            symbolName = "cloud.fog.fill"
        case 1066, 1114, 1210, 1213, 1216, 1219, 1222, 1225, 1255, 1258:
            symbolName = "cloud.snow.fill"
        case 1069, 1204, 1207, 1249, 1252:
            symbolName = "cloud.sleet.fill"
        case 1087:
            symbolName = "cloud.bolt.rain.fill"
        case 1117:
            symbolName = "wind.snow"
        case 1171, 1198, 1201, 1237, 1261, 1264:
            symbolName = "cloud.hail.fill"
        case 1183, 1189, 1195, 1243:
            symbolName = "cloud.rain.fill"
        case 1246:
            symbolName = "cloud.heavyrain.fill"
        case 1273:
            symbolName = "cloud.bolt.rain"
        default:
            symbolName = "sparkles"
        }
        weatherConditionImage.image = UIImage(systemName: symbolName)
    }
    
}



struct WeatherResponse:Decodable{
    let location:Location
    let current:Weather
}
struct Location:Decodable {
    let name: String
}

struct Weather:Decodable{
    let temp_c:Float
    let temp_f: Float
    let condition: WeatherCondition
    
    struct WeatherCondition:Decodable{
        let text: String
        let code:Int
    }


}
