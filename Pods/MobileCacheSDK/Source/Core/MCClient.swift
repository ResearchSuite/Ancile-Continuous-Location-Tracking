//
//  MCClient.swift
//  MCSDK
//
//  Created by James Kizer on 1/17/2018.
//

import UIKit
import Alamofire
//import OMHClient

open class MCClient: NSObject {

    public struct SignInResponse {
        public let accessToken: String
        public let refreshToken: String
    }

    let baseURL: String
    let redirectURL: String
    let clientID: String
    let clientSecret: String
    let dispatchQueue: DispatchQueue?

    public init(baseURL: String, redirectURL: String, clientID: String, clientSecret: String, dispatchQueue: DispatchQueue? = nil) {
        self.baseURL = baseURL
        self.redirectURL = redirectURL
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.dispatchQueue = dispatchQueue
        super.init()
    }
    
    open func OAuthURL() -> URL? {
        return URL(string: "\(self.baseURL)/?client_id=\(self.clientID)&redirect_uri=\(self.redirectURL)")
    }
    
    open func signIn(code: String, completion: @escaping ((SignInResponse?, Error?) -> ())) {
        
        let urlString = "\(self.baseURL)/token/"
        let parameters = [
            "grant_type": "authorization_code",
            "code": code,
            "client_id": self.clientID,
            "client_secret": self.clientSecret,
            "redirect_uri": self.redirectURL
        ]
        
//        let headers = ["Authorization": "Basic \(self.basicAuthString)"]
//        let headers: [String: String] = [:]
        
        let request = Alamofire.request(
            urlString,
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default)
        
        debugPrint(request)
        request.responseJSON(queue: self.dispatchQueue, completionHandler: self.processAuthResponse(isRefresh: false, completion: completion))
        
    }
    
    open func refreshAccessToken(refreshToken: String, completion: @escaping ((SignInResponse?, Error?) -> ()))  {
        
        assertionFailure("refresh not yet implemented")
//        let urlString = "\(self.baseURL)/oauth/token"
//        let parameters = [
//            "grant_type": "refresh_token",
//            "refresh_token": refreshToken]
//        
//        let headers = ["Authorization": "Basic \(self.basicAuthString)"]
//        
//        let request = Alamofire.request(
//            urlString,
//            method: .post,
//            parameters: parameters,
//            encoding: URLEncoding.default,
//            headers: headers)
//        
//        request.responseJSON(queue: self.dispatchQueue, completionHandler: self.processAuthResponse(isRefresh: true, completion: completion))
        
    }

    open func processAuthResponse(isRefresh: Bool, completion: @escaping ((SignInResponse?, Error?) -> ())) -> ((DataResponse<Any>) -> ()) {
        
        return { jsonResponse in
            
            debugPrint(jsonResponse)
            //check for lower level errors
            if let error = jsonResponse.result.error as? NSError {
                if error.code == NSURLErrorNotConnectedToInternet {
                    completion(nil, MCClientError.unreachableError(underlyingError: error))
                    return
                }
                else {
                    completion(nil, MCClientError.otherError(underlyingError: error))
                    return
                }
            }
            
            //check for our errors
            //credentialsFailure
            guard let response = jsonResponse.response else {
                completion(nil, MCClientError.malformedResponse(responseBody: jsonResponse))
                return
            }
            
            if response.statusCode == 502 {
                debugPrint(jsonResponse)
                completion(nil, MCClientError.badGatewayError)
                return
            }
            
            if response.statusCode != 200 {
                
                guard jsonResponse.result.isSuccess,
                    let json = jsonResponse.result.value as? [String: Any],
                    let error = json["error"] as? String,
                    let errorDescription = json["error_description"] as? String else {
                        completion(nil, MCClientError.malformedResponse(responseBody: jsonResponse.result.value))
                        return
                }
                
                if error == "invalid_grant" {
                    if isRefresh {
                        completion(nil, MCClientError.invalidRefreshToken)
                    }
                    else {
                        completion(nil, MCClientError.credentialsFailure(descrition: errorDescription))
                    }
                    return
                }
                else {
                    completion(nil, MCClientError.serverError)
                    return
                }
                
            }
            
            //malformed body
            guard jsonResponse.result.isSuccess,
                let json = jsonResponse.result.value as? [String: Any],
                let accessToken = json["access_token"] as? String,
                let refreshToken = json["refresh_token"] as? String else {
                    completion(nil, MCClientError.malformedResponse(responseBody: jsonResponse.result.value))
                    return
            }
            
            let signInResponse = SignInResponse(accessToken: accessToken, refreshToken: refreshToken)
            
            completion(signInResponse, nil)
            
        }
        
    }


//    open func signIn(username: String, password: String, completion: @escaping ((SignInResponse?, Error?) -> ())) {
//
//        let urlString = "\(self.baseURL)/auth/token"
//        let parameters = [
//            "username": username,
//            "password": password
//        ]
//
//        let request = Alamofire.request(
//            urlString,
//            method: .post,
//            parameters: parameters,
//            encoding: JSONEncoding.default)
//
//        request.responseJSON(queue: self.dispatchQueue, completionHandler: self.processAuthResponse(isRefresh: false, completion: completion))
//
//    }

    open func validateSample(sample: MCSample) -> Bool {

        guard let sampleJSON = sample.toJSON() else {
            return false
        }
        
        return JSONSerialization.isValidJSONObject(sampleJSON)

    }
    
    public func postSample(sample: MCSample, token: String, completion: @escaping ((Bool, Error?) -> ())) {
        
        let urlString = sample.generateURL(baseURL: self.baseURL)
        let headers = ["Authorization": "Bearer \(token)", "Accept": "application/json"]

        guard let sampleJSON = sample.toJSON(),
            JSONSerialization.isValidJSONObject(sampleJSON) else {
            completion(false, MCClientError.invalidDatapoint)
            return
        }
        
        let request = Alamofire.request(
            urlString,
            method: .post,
            parameters: sampleJSON,
            encoding: JSONEncoding.default,
            headers: headers)
        
        let reponseProcessor: (DataResponse<Any>) -> () = self.processDatapointUploadResponse(completion: completion)
        debugPrint(request)
        request.responseJSON(queue: self.dispatchQueue, completionHandler: reponseProcessor)
        
    }

//    public func signOut(token: String, completion: @escaping ((Bool, Error?) -> ())) {
//        let urlString = "\(self.baseURL)/auth/logout"
//        let headers = ["Authorization": "Token \(token)", "Accept": "application/json"]
//
//        let request = Alamofire.request(
//            urlString,
//            method: .post,
//            encoding: JSONEncoding.default,
//            headers: headers)
//
//        let reponseProcessor: (DataResponse<Any>) -> () = self.processLogoutResponse(completion: completion)
//
//        request.responseJSON(queue: self.dispatchQueue, completionHandler: reponseProcessor)
//
//    }
//
//    private func processLogoutResponse(completion: @escaping ((Bool, Error?) -> ())) -> (DataResponse<Any>) -> () {
//
//        return { jsonResponse in
//            //check for actually success
//
//            debugPrint(jsonResponse)
//            //check for lower level errors
//            if let error = jsonResponse.result.error as NSError? {
//                if error.code == NSURLErrorNotConnectedToInternet {
//                    completion(false, MCClientError.unreachableError(underlyingError: error))
//                    return
//                }
//                else {
//                    completion(false, MCClientError.otherError(underlyingError: error))
//                    return
//                }
//            }
//
//            //check for our errors
//            //credentialsFailure
//            guard let _ = jsonResponse.response else {
//                completion(false, MCClientError.malformedResponse(responseBody: jsonResponse))
//                return
//            }
//
//            if let response = jsonResponse.response,
//                response.statusCode == 502 {
//                debugPrint(jsonResponse)
//                completion(false, MCClientError.badGatewayError)
//                return
//            }
//
//            //check for malformed body
//            guard jsonResponse.result.isSuccess,
//                let response = jsonResponse.response,
//                response.statusCode == 200 else {
//                    completion(false, MCClientError.malformedResponse(responseBody: jsonResponse.result.value))
//                    return
//            }
//
//            completion(true, nil)
//        }
//
//
//    }
//

    private func processDatapointUploadResponse(completion: @escaping ((Bool, Error?) -> ())) -> (DataResponse<Any>) -> () {

        return { jsonResponse in
            //check for actually success

            debugPrint(jsonResponse)

            switch jsonResponse.result {
            case .success:
                print("Validation Successful")
                guard let response = jsonResponse.response else {
                    completion(false, MCClientError.unknownError)
                    return
                }

                switch (response.statusCode) {
                case 200:
                    fallthrough
                case 201:
                    completion(true, nil)
                    return

                case 400:
                    completion(false, MCClientError.invalidDatapoint)
                    return

                case 401:
                    completion(false, MCClientError.invalidAuthToken)
                    return

                case 409:
                    completion(false, MCClientError.dataPointConflict)
                    return

                case 500:
                    completion(false, MCClientError.serverError)
                    return

                case 502:
                    completion(false, MCClientError.badGatewayError)
                    return

                default:

                    if let error = jsonResponse.result.error {
                        completion(false, error)
                        return
                    }
                    else {
                        completion(false, MCClientError.malformedResponse(responseBody: jsonResponse))
                        return
                    }

                }


            case .failure(let error):
                let nsError = error as NSError
                if nsError.code == NSURLErrorNotConnectedToInternet {
                    completion(false, MCClientError.unreachableError(underlyingError: nsError))
                    return
                }
                else {
                    completion(false, MCClientError.otherError(underlyingError: nsError))
                    return
                }
            }
        }

    }



}
