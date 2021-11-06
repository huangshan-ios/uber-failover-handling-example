//
//  NetworkClient.swift
//  uber-failover-handling
//
//  Created by Son Hoang on 06/11/2021.
//

import Foundation

protocol NetworkClient {
    
    var networkProvider: NetworkProvider { get }
    
    func callToTheNetwork(completion: (_ response: String?, _ error: NetworkError?) -> Void)
    
}

class NetworkClientImpl: NetworkClient {
    
    var networkProvider: NetworkProvider
    
    var networkEndpoint: String = NetworkEndpoint.primary.rawValue
    
    var maxErrorCount: Int = 3
    
    private var timerRequestNewEndpoint = Timer()
    
    init(networkProvider: NetworkProvider) {
        self.networkProvider = networkProvider
        self.networkProvider.delegate = self
    }
    
    func callToTheNetwork(completion: (_ response: String?, _ error: NetworkError?) -> Void) {
        
        callToTheNetworkWithRetries(retries: maxErrorCount) { response, error in
            
            timerRequestNewEndpoint.invalidate()
            
            networkProvider.usingPrimaryEndpoint()
            
            completion(response, error)
            
        }
        
    }
    
    private func callToTheNetworkWithRetries(retries: Int, completion: (_ response: String?, _ error: NetworkError?) -> Void) {
        
        if retries == 0 {
            
            networkProvider.requestNewEndPoint()
            
        }
        
        switch hasError() {
        
        case .networkError:
            
            completion(nil, .networkError)
            
        case .serverError:
            
            callToTheNetworkWithRetries(retries: maxErrorCount - 1, completion: completion)
            
            startTimerForRequestNewEndPoint()
            
        }
        
    }
    
    private func hasError() -> NetworkError {
        return .networkError
    }
    
    private func startTimerForRequestNewEndPoint() {
        
        timerRequestNewEndpoint = Timer(timeInterval: TimeInterval(5000), repeats: false, block: { [weak self] _ in
            
            guard let self = self else { return }
            
            self.networkProvider.requestNewEndPoint()
        })
        
    }
    
}

extension NetworkClientImpl: NetworkProviderDelegate {
    
    func switchToNewNetwork(endpoint: String) {
        
        networkEndpoint = endpoint
        
    }
    
}
