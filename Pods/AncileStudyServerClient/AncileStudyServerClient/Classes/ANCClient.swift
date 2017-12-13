//
//  ANCClient.swift
//  AncilePhoneSpecStudy
//
//  Created by James Kizer on 6/22/17.
//  Copyright © 2017 smalldatalab. All rights reserved.
//

//import UIKit
import Alamofire

public protocol ANCClientProvider {
    func getAncileClient() -> ANCClient?
}

public protocol ANCClientCredentialStore {
    func set(value: NSSecureCoding?, key: String)
    func get(key: String) -> NSSecureCoding?
}

open class ANCClient: NSObject {
    
    static public let kAncileAuthToken = "ancile_study_server_auth_token"
    
    public struct SignInResponse {
        public let authToken: String
    }
    
    let baseURL: String
    let ancileClientID: String
    let store: ANCClientCredentialStore 
    let dispatchQueue: DispatchQueue?
    public var ancileAuthDelegate: ANCAncileAuthDelegate!
    public var coreAuthDelegate: ANCCoreAuthDelegate!
    
    private var _authToken: String?
    
    public var authToken: String? {
        get {
            return _authToken
        }
        set(newToken) {
            self._authToken = newToken
            if let token = newToken {
                self.store.set(value: token as NSSecureCoding, key: ANCClient.kAncileAuthToken)
            }
            else {
                self.store.set(value: nil, key: ANCClient.kAncileAuthToken)
            }
            
        }
    }
    
    public init(baseURL: String, ancileClientID: String, mobileURLScheme: String, store: ANCClientCredentialStore, dispatchQueue: DispatchQueue? = nil) {
        self.baseURL = baseURL
        self.ancileClientID = ancileClientID
        self.store = store
        self._authToken = store.get(key: ANCClient.kAncileAuthToken) as? String
        self.dispatchQueue = dispatchQueue
        super.init()
        
        self.ancileAuthDelegate = ANCAncileAuthDelegate(client: self, urlScheme: mobileURLScheme)
        self.coreAuthDelegate = ANCCoreAuthDelegate(client: self, urlScheme: mobileURLScheme)
    }

    public var authURL: URL? {
        return URL(string: "\(self.baseURL)/login/\(self.ancileClientID)")
    }
    
    open func processAuthResponse(isRefresh: Bool, completion: @escaping ((SignInResponse?, Error?) -> ())) -> ((DataResponse<Any>) -> ()) {
        
        return { jsonResponse in
            
            debugPrint(jsonResponse)
            //check for lower level errors
            if let error = jsonResponse.result.error as? NSError {
                if error.code == NSURLErrorNotConnectedToInternet {
                    completion(nil, ANCClientError.unreachableError(underlyingError: error))
                    return
                }
                else {
                    completion(nil, ANCClientError.otherError(underlyingError: error))
                    return
                }
            }
            
            //check for our errors
            //credentialsFailure
            guard let response = jsonResponse.response else {
                completion(nil, ANCClientError.malformedResponse(responseBody: jsonResponse))
                return
            }
            
            if let response = jsonResponse.response,
                response.statusCode == 502 {
                debugPrint(jsonResponse)
                completion(nil, ANCClientError.badGatewayError)
                return
            }
            
//            if response.statusCode != 200 {
//                
//                guard jsonResponse.result.isSuccess,
//                    let json = jsonResponse.result.value as? [String: Any],
//                    let error = json["error"] as? String,
//                    let errorDescription = json["error_description"] as? String else {
//                        completion(nil, OMHClientError.malformedResponse(responseBody: jsonResponse.result.value))
//                        return
//                }
//                
//                if error == "invalid_grant" {
//                    if isRefresh {
//                        completion(nil, OMHClientError.invalidRefreshToken)
//                    }
//                    else {
//                        completion(nil, OMHClientError.credentialsFailure(descrition: errorDescription))
//                    }
//                    return
//                }
//                else {
//                    completion(nil, OMHClientError.serverError(error: error, errorDescription: errorDescription))
//                    return
//                }
//                
//            }
//            
            //check for malformed body
            guard jsonResponse.result.isSuccess,
                let json = jsonResponse.result.value as? [String: Any],
                let authToken = json["auth_token"] as? String else {
                    completion(nil, ANCClientError.malformedResponse(responseBody: jsonResponse.result.value))
                    return
            }

            //fill in with actual server errors
            let signInResponse = SignInResponse(authToken: authToken)
            
            self.authToken = authToken
            
            completion(signInResponse, nil)
            
        }
        
    }
    
    open func signIn(code: String, completion: @escaping ((SignInResponse?, Error?) -> ())) {
        
        let urlString = "\(self.baseURL)/verify"
        let parameters = [
            "code": code
        ]
        
//        let headers = ["Authorization": "Basic \(self.basicAuthString)"]
        let headers: [String: String] = [:]
        
        let request = Alamofire.request(
            urlString,
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default,
            headers: headers)
        
        request.responseJSON(queue: self.dispatchQueue, completionHandler: self.processAuthResponse(isRefresh: false, completion: completion))
        
    }

    open func getCoreLink(authToken: String, completion: @escaping ((String?, Error?) -> ())) {
        
        let urlString = "\(self.baseURL)/temporary_core_link/\(self.ancileClientID)"
        let headers = ["Authorization": "Token \(authToken)"]
        
        let request = Alamofire.request(
            urlString,
            method: .get,
            encoding: JSONEncoding.default,
            headers: headers)
        
        request.responseJSON(queue: self.dispatchQueue, completionHandler: { jsonResponse in
            
            
            debugPrint(jsonResponse)
            //check for lower level errors
            if let error = jsonResponse.result.error as? NSError {
                if error.code == NSURLErrorNotConnectedToInternet {
                    completion(nil, ANCClientError.unreachableError(underlyingError: error))
                    return
                }
                else {
                    completion(nil, ANCClientError.otherError(underlyingError: error))
                    return
                }
            }
            
            //check for our errors
            //credentialsFailure
            guard let response = jsonResponse.response else {
                completion(nil, ANCClientError.malformedResponse(responseBody: jsonResponse))
                return
            }
            
            if let response = jsonResponse.response,
                response.statusCode == 502 {
                debugPrint(jsonResponse)
                completion(nil, ANCClientError.badGatewayError)
                return
            }
            
            //check for malformed body
            guard jsonResponse.result.isSuccess,
                let json = jsonResponse.result.value as? [String: Any],
                let url = json["core_auth_url"] as? String else {
                    completion(nil, ANCClientError.malformedResponse(responseBody: jsonResponse.result.value))
                    return
            }
            
            //fill in with actual server errors
            
            completion(url, nil)
            
            
        })
        
    }
    
//    open func refreshAccessToken(refreshToken: String, completion: @escaping ((SignInResponse?, Error?) -> ()))  {
//        let urlString = "\(self.baseURL)/oauth/token"
//        let parameters = [
//            "grant_type": "refresh_token",
//            "refresh_token": refreshToken]
//        
////        let headers = ["Authorization": "Basic \(self.basicAuthString)"]
//        let headers: [String: String] = [:]
//        
//        let request = Alamofire.request(
//            urlString,
//            method: .post,
//            parameters: parameters,
//            headers: headers)
//        
//        request.responseJSON(queue: self.dispatchQueue, completionHandler: self.processAuthResponse(isRefresh: true, completion: completion))
//        
//    }
    
    open var isSignedIn: Bool {
        return self.authToken != nil
    }
    
    open func signOut() {
        self.authToken = nil
    }
    
    open func postConsent(token: String, fileName: String, fileURL: URL, completion: @escaping ((Bool, Error?) -> ())) {
        
        let urlString = "\(self.baseURL)/consent/\(self.ancileClientID)"
        
        let headers = ["Authorization": "Token \(token)"]
        
        let request = Alamofire.upload(multipartFormData: { (multipartFormData) in
            
            multipartFormData.append(fileURL, withName: "signed_document", fileName: fileName, mimeType: "application/pdf")
            
        }, to: urlString, headers: headers) { (encodingResult) in
            switch encodingResult {
            case .success(let upload, _, _):
                
                debugPrint(upload)
                debugPrint(upload.request)
                upload.responseJSON(queue: self.dispatchQueue) { (jsonResponse) in
                    
                    debugPrint(jsonResponse)
                    //check for lower level errors
                    if let error = jsonResponse.result.error as? NSError {
                        if error.code == NSURLErrorNotConnectedToInternet {
                            completion(false, ANCClientError.unreachableError(underlyingError: error))
                            return
                        }
                        else {
                            completion(false, ANCClientError.otherError(underlyingError: error))
                            return
                        }
                    }
                    
                    completion(true, nil)            
                }
                
            case .failure(let encodingError):
                completion(false, encodingError)
            }
        }
        
    }
    
//    open func withdrawConsent(token: String, completion: @escaping ((Bool, Error?) -> ())) {
//        
//    }
    
}
