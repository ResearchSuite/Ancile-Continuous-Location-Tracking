//
//  MCManager.swift
//  MCSDK
//
//  Created by James Kizer on 1/17/2018.
//

import UIKit
import SecureQueue
import Alamofire
//import OMHClient

public protocol MCCredentialStore {
    func set(value: NSSecureCoding?, key: String)
    func get(key: String) -> NSSecureCoding?
}

public protocol MCLogger {
    func log(_ debugString: String)
}

open class MCManager: NSObject {
    
    static let kAccessToken = "AccessToken"
    static let kRefreshToken = "RefreshToken"
    
    var client: MCClient!
    var secureQueue: SecureQueue!
    
    var credentialsQueue: DispatchQueue!
    var credentialStore: MCCredentialStore!
    var credentialStoreQueue: DispatchQueue!
    var accessToken: String?
    var refreshToken: String?
    
    var uploadQueue: DispatchQueue!
    var isUploading: Bool = false
    
    let reachabilityManager: NetworkReachabilityManager
    
    var protectedDataAvaialbleObserver: NSObjectProtocol!
    
    var logger: MCLogger?
    
//    static private var _sharedManager: OhmageOMHManager?
    private var redirectCompletion: ((Error?) -> ())?
    
    public init?(
        baseURL: String,
        redirectURL: String,
        clientID: String,
        clientSecret: String,
        queueStorageDirectory: String,
        sampleClasses: [AnyClass],
        store: MCCredentialStore,
        logger: MCLogger? = nil
        ) {
        
        self.uploadQueue = DispatchQueue(label: "UploadQueue")
        
        self.client = MCClient(baseURL: baseURL, redirectURL: redirectURL, clientID: clientID, clientSecret: clientSecret, dispatchQueue: self.uploadQueue)
        self.secureQueue = SecureQueue(directoryName: queueStorageDirectory, allowedClasses: [NSDictionary.self, NSArray.self] + sampleClasses)
        
        self.credentialsQueue = DispatchQueue(label: "CredentialsQueue")
        
        self.credentialStore = store
        self.credentialStoreQueue = DispatchQueue(label: "CredentialStoreQueue")
        
        if let accessToken = self.credentialStore.get(key: MCManager.kAccessToken) as? String {
            self.accessToken = accessToken
        }
        if let refreshToken = self.credentialStore.get(key: MCManager.kRefreshToken) as? String {
            self.refreshToken = refreshToken
        }
        
        guard let url = URL(string: baseURL),
            let host = url.host,
            let reachabilityManager = NetworkReachabilityManager(host: host) else {
                return nil
        }
        
        self.reachabilityManager = reachabilityManager
        
        self.logger = logger
        
        super.init()
        
        //set up listeners for the following events:
        // 1) we have access to the internet
        // 2) we have access to protected data
        
        let startUploading = self.startUploading
        
        reachabilityManager.listener = { status in
            if reachabilityManager.isReachable {
                do {
                    try startUploading()
                } catch let error {
                    debugPrint(error)
                }
            }
        }
        
        if self.isSignedIn {
            reachabilityManager.startListening()
        }


        self.protectedDataAvaialbleObserver = NotificationCenter.default.addObserver(forName: .UIApplicationProtectedDataDidBecomeAvailable, object: nil, queue: nil) { [weak self](notification) in
            do {
                try startUploading()
            } catch let error as NSError {
                self?.logger?.log("error occurred when starting upload after device unlock: \(error.localizedDescription)")
                debugPrint(error)
            }

        }
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self.protectedDataAvaialbleObserver)
    }
    
    public func beginRedirectSignIn(forceSignIn: Bool, completion: @escaping ((Error?) -> ())) {
        
        if self.isSignedIn && !forceSignIn {
            completion(MCManagerErrors.alreadySignedIn)
            return
        }
        
        if let url = self.client.OAuthURL() {
            self.redirectCompletion = completion
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                // Fallback on earlier versions
                UIApplication.shared.openURL(url)
            }
        }
    }
    
    func getQueryStringParameter(url: String, param: String) -> String? {
        guard let url = URLComponents(string: url) else { return nil }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }
    
    public func handleURL(url: URL) -> Bool {
        
        if let code = self.getQueryStringParameter(url: url.absoluteString, param: "code") {
            self.client.signIn(code: code) { (signInResponse, error) in
                
                if let err = error {
                    
                    self.redirectCompletion?(err)
                    return
                    
                }
                
                if let response = signInResponse {
                    self.setCredentials(accessToken: response.accessToken, refreshToken: response.refreshToken)
                }
                
                self.reachabilityManager.startListening()
                self.redirectCompletion?(nil)
                
            }
        }
        
        return true
    }
    
    public func signOut(completion: @escaping ((Error?) -> ())) {
        
//        self.client
        
        let onFinishClosure = {
            do {
                
                self.reachabilityManager.stopListening()
                
                try self.secureQueue.clear()
                self.clearCredentials()
                
                completion(nil)
                
            } catch let error {
                completion(error)
            }
        }
        
        onFinishClosure()
        
//        guard let authToken = self.getAuthToken() else {
//            onFinishClosure()
//            return
//        }
//
//        self.client.signOut(token: authToken, completion: { (success, error) in
//            onFinishClosure()
//        })
    }
    
    public var isSignedIn: Bool {
        return self.getRefreshToken() != nil
    }
    
    public var queueIsEmpty: Bool {
        return self.secureQueue.isEmpty
    }
    
    public var queueItemCount: Int {
        return self.secureQueue.count
    }
    
    private func clearCredentials() {
        self.credentialsQueue.sync {
            self.credentialStoreQueue.async {
                self.credentialStore.set(value: nil, key: MCManager.kAccessToken)
                self.credentialStore.set(value: nil, key: MCManager.kRefreshToken)
            }
            self.accessToken = nil
            self.refreshToken = nil
            return
        }
    }
    
    private func setCredentials(accessToken: String, refreshToken: String) {
        self.credentialsQueue.sync {
            self.credentialStoreQueue.async {
                self.credentialStore.set(value: accessToken as NSString, key: MCManager.kAccessToken)
                self.credentialStore.set(value: refreshToken as NSString, key: MCManager.kRefreshToken)
            }
            self.accessToken = accessToken
            self.refreshToken = refreshToken
            return
        }
    }
    
    private func getAccessToken() -> String? {
        return self.credentialsQueue.sync {
            return self.accessToken
        }
    }
    
    private func getRefreshToken() -> String? {
        return self.credentialsQueue.sync {
            return self.refreshToken
        }
    }
    
    public func addSample(sample: MCSample, completion: @escaping ((Error?) -> ())) {
        if !self.isSignedIn {
            completion(MCManagerErrors.notSignedIn)
            return
        }
        
        if !self.client.validateSample(sample: sample) {
            completion(MCManagerErrors.invalidDatapoint)
            return
        }
        
        do {
            
            try self.secureQueue.addElement(element: sample)
            self.upload(fromMemory: false)
            completion(nil)
            
        } catch let error {
            completion(error)
            return
        }

    }

//    public func addDatapoint(datapoint: OMHDataPoint, completion: @escaping ((Error?) -> ())) {
//
//        if !self.isSignedIn {
//            completion(MCManagerErrors.notSignedIn)
//            return
//        }
//
//        if !self.client.validateSample(sample: datapoint) {
//            completion(MCManagerErrors.invalidDatapoint)
//            return
//        }
//
//        do {
//
//            var elementDictionary: [String: Any] = [
//                "datapoint": datapoint.toDict()
//            ]
//
//            if let mediaDatapoint = datapoint as? OMHMediaDataPoint {
//                assertionFailure("media not yet supported!!")
//                elementDictionary["mediaAttachments"] = mediaDatapoint.attachments as NSArray
//            }
//
//            try self.secureQueue.addElement(element: elementDictionary as NSDictionary)
//        } catch let error {
//            completion(error)
//            return
//        }
//
//        self.upload(fromMemory: false)
//        completion(nil)
//
//    }
//
    public func startUploading() throws {

        if !self.isSignedIn {
            throw MCManagerErrors.notSignedIn
        }

        self.upload(fromMemory: false)
    }

    private func upload(fromMemory: Bool) {

        self.uploadQueue.async {

            guard let queue = self.secureQueue,
                !queue.isEmpty,
                !self.isUploading else {
                    return
            }

            let wappedGetFunction: () throws -> (String, NSSecureCoding)? = {

                if fromMemory {
                    return self.secureQueue.getFirstInMemoryElement()
                }
                else {
                    return try self.secureQueue.getFirstElement()
                }

            }

            do {

                if let (elementId, value) = try wappedGetFunction(),
                    let sample = value as? MCSample,
                    let accessToken = self.getAccessToken() {

                    self.isUploading = true
                    
                    self.client.postSample(sample: sample, token: accessToken, completion: { (success, error) in
                        
                        self.isUploading = false
                        self.processUploadResponse(elementId: elementId, fromMemory: fromMemory, success: success, error: error)
                        
                    })

                }

                else {
                    self.logger?.log("either we couldnt load a valid datapoint or there is no token")
                }


            } catch let error {
                //assume file system encryption error when tryong to read
                self.logger?.log("secure queue threw when trying to get first element: \(error)")
                debugPrint(error)

                //try uploading datapoint from memory
                self.upload(fromMemory: true)

            }

        }

    }

    private func processUploadResponse(elementId: String, fromMemory: Bool, success: Bool, error: Error?) {

        if let err = error {
            debugPrint(err)
            self.logger?.log("Got error while posting datapoint: \(error.debugDescription)")
            //should we retry here?
            // and if so, under what conditions

            //may need to refresh
            switch error {
            case .some(MCClientError.invalidAuthToken):

                self.logger?.log("invalid access token: refresh")
                if let refreshToken = self.refreshToken {
                    self.client.refreshAccessToken(refreshToken: refreshToken, completion: { (signInResponse, error) in
                        
                        //only clear credentials in case of invalid refresh token
                        //otherwise, ignore for now
                        //may need to revisit this
                        switch error {
                        case .some(MCClientError.invalidRefreshToken):
                            self.clearCredentials()
                            return
                        default:
                            if let response = signInResponse {
                                self.setCredentials(accessToken: response.accessToken, refreshToken: response.refreshToken)
                                self.upload(fromMemory: fromMemory)
                            }
                        }
                        
                    })
                }

                return
            //we've already tried to upload this data point
            //we can remove it from the queue
            case .some(MCClientError.dataPointConflict):

                self.logger?.log("datapoint conflict: removing")

                do {
                    try self.secureQueue.removeElement(elementId: elementId)

                } catch let error {
                    //we tried to delete,
                    debugPrint(error)
                }

                self.upload(fromMemory: fromMemory)
                return

            //this datapoint is invalid and won't ever be accepted
            //we can remove it from the queue
            case .some(MCClientError.invalidDatapoint):

                self.logger?.log("datapoint invalid: removing")

                do {
                    try self.secureQueue.removeElement(elementId: elementId)

                } catch let error {
                    //we tried to delete,
                    debugPrint(error)
                }

                self.upload(fromMemory: fromMemory)
                return

            case .some(MCClientError.badGatewayError):
                self.logger?.log("bad gateway")
                return

            default:

                let nsError = err as NSError
                switch (nsError.code) {
                case NSURLErrorNetworkConnectionLost:
                    self.logger?.log("We have an internet connecction, but cannot connect to the server. Is it down?")
                    return

                default:
                    self.logger?.log("other error: \(nsError)")
                    break
                }
            }

        } else if success {
            //remove from queue
            self.logger?.log("success: removing data point")
            do {
                try self.secureQueue.removeElement(elementId: elementId)

            } catch let error {
                //we tried to delete,
                debugPrint(error)
            }

            self.upload(fromMemory: fromMemory)

        }

    }
    
    

}
