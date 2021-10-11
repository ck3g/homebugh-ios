//
//  API.swift
//  HomeBugh
//
//  Created by Nataly Tatarintseva on 30.03.2021.
//

import Foundation

class API {
    
    class Endpoints {
        static let Authentication: ApiEndpoint = ApiEndpoint(Method: .Post, Url: "https://api.homebugh.info:8080/token")
    }
    
    @discardableResult
    static func sendRequestAsync(url:String, method:HttpMethod, autoAuth:Bool = false, authByAppId:Bool = false, parameters:NSDictionary? = nil, headers:NSDictionary? = nil, noCache:Bool = false, rawData:NSData? = nil, trackProgress:Bool? = false, completionHandler:((_ error:NSError?, _ data:Data?, _ dateLastModified:String?, _ statusCode:Int?)->Void)?=nil) -> URLSessionDataTask? {
        
        // swift4: to do -> track progress !!
        //let configuration = URLSessionConfiguration.default
        //let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        let session = URLSession.shared
        var request:URLRequest!
        var parametersDic:NSMutableDictionary? = parameters?.mutableCopy() as? NSMutableDictionary // make copy to make it mutable for noCaching
        
        // extract already existing parameters from url:
        if let givenUrlWithParams = URLComponents(string: url) {
            if let items = givenUrlWithParams.queryItems {
                parametersDic = NSMutableDictionary()
                for item in items {
                    //parametersDic!.setValue(item.value, forKey: item.name)
                    let key = item.name
                    let value = item.value
                    parametersDic!.setValue(value, forKey: key)
                }
            }
        }
        
        // add / append randomizing parameter:
        if noCache == true {
            if parametersDic == nil {
                parametersDic = NSMutableDictionary()
            }
            let random = String((0..<20).map{ _ in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()! })
            parametersDic!.setValue(String(random), forKey: "rnd")
        }
        
        if method == .Post || method == .Put || method == .Delete || method == .Head {
            // Create and assign the url:
            guard let requestUrl = URL(string: url) else {
                completionHandler?(self.createRequestError(status: -100), nil, nil, nil)
                return nil
            }
            request = URLRequest(url: requestUrl)
            if parametersDic != nil && rawData == nil {
                // Add parameters to request body as json:
                let json = try? JSONSerialization.data(withJSONObject: parametersDic!, options: JSONSerialization.WritingOptions.prettyPrinted)
                request.httpBody = json
                request.addValue("application/json", forHTTPHeaderField: "Content-type")
            }
            else if rawData != nil {
                // Add raw data to request body :
                request.httpBodyStream = InputStream(data: rawData! as Data)
                let bytes = rawData!.length
//                request.addValue(String(bytes), forHTTPHeaderField: "Content-Length")
                request.addValue("application/json", forHTTPHeaderField: "Content-type")
            }
        }
        else if method == .Get {
            // Create url:
            var requestUrl = URLComponents(string: url)!
            if parametersDic != nil {
                // Create parameters:
                var queryItems:[URLQueryItem] = [URLQueryItem]()
                for item in parametersDic! {
                    let queryItem = URLQueryItem(name: item.key as! String, value: (item.value as! String))
                    queryItems.append(queryItem)
                }
                // Assign parameters
                requestUrl.queryItems = queryItems
            }
            // Assign url:
            request = URLRequest(url: requestUrl.url!)
        }
        
        request.httpMethod = method.rawValue
        
        if headers != nil {
            for header in headers! {
                request.addValue(header.value as! String, forHTTPHeaderField: header.key as! String)
            }
        }
        if autoAuth == true {
            let authHeader = self.buildAuthHeader(username: AppState.CurrentUser.email, password: AppState.CurrentUser.password )
            request.addValue(authHeader["Authorization"]!, forHTTPHeaderField: "Authorization")
        }
//        else if authByAppId == true {
//            let authHeader = self.buildAuthHeader(username: AppState.CurrentUser.appId, password: AppState.CurrentUser.deviceId)
//            request.addValue(authHeader["Authorization"]!, forHTTPHeaderField: "Authorization")
//        }
        
        print ("\nAPI-Request: \(url)\nMethod     : \(method)\nParameters : \(String(describing: parameters))")
        let task = session.dataTask(with: request, completionHandler: {
            (data, response, err) -> Void in
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completionHandler?(self.createRequestError(status: -200), nil, nil, nil)
                return
            }
            let statusCode:Int = httpResponse.statusCode
            let dateLastModified:String = httpResponse.allHeaderFields["Last-Modified"] as? String ?? ""
print ("Statuscode : \(statusCode)")
if statusCode != 200 && data != nil { print ("Error      : \(String(decoding: data!, as: UTF8.self))") }
            if statusCode != 200 && statusCode != 201  {
                // http request failed:
                completionHandler?(self.createRequestError(status: statusCode), data, nil, statusCode)
                return
            }
            completionHandler?(nil, data, dateLastModified, statusCode)
        })
        task.resume()
        return task
    }
    
    private static func buildAuthHeader(username:String, password:String) -> [String:String] {
        let plainString:NSString = "\(username):\(password)" as NSString
        let plainData = plainString.data(using: String.Encoding.utf8.rawValue)
        let base64String = plainData!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        let headers = [
            "Authorization": "Basic " + base64String,
        ]
        return headers
    }
    
    private static func createRequestError(status:Int) -> NSError {
        let domain:String = "AFWNetwork"
        var description:String = ""
        if status == -100 {
            description = "Bad Url"
        }
        else if status == -200 {
            description = "No HTTP Response"
        }
        else if status > 0 {
            description = "HTTP Response Status is not 200 (is \(status))."
        }
        return NSError(domain: domain, code: status, userInfo: [NSLocalizedDescriptionKey: description])
    }
    
}

