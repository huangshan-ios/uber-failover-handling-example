//
//  NetworkClient.swift
//  uber-failover-handling
//
//  Created by Son Hoang on 06/11/2021.
//

import Foundation
import Combine

protocol NetworkClient {
    
    var networkProvider: NetworkProvider { get }
    
    var failoverHandler: FailoverHandler { get }
    
    func callToTheNetwork() -> AnyPublisher<String, NetworkError>
    
    
}

class NetworkClientImpl: NetworkClient {
    
    var networkProvider: NetworkProvider = NetworkProviderImpl(networkHealthCheck: NetworkHealthCheckImpl())
    
    var failoverHandler: FailoverHandler
    
    var networkDomain: String = NetworkEndpoint.primary.rawValue
    
    var maxErrorCount: Int = 3
    
    private var timerRequestNewEndpoint = Timer()
    
    init(failoverHandler: FailoverHandler) {
        self.failoverHandler = failoverHandler
        self.failoverHandler.onSwitchDomain = { [weak self] domain in
            guard let self = self else { return }
            self.networkDomain = domain
        }
    }
    
    func callToTheNetwork(completion: (_ response: String?, _ error: NetworkError?) -> Void) {
        
        callToTheNetworkWithRetries(retries: maxErrorCount) { response, error in
            
            timerRequestNewEndpoint.invalidate()
            
            networkProvider.usingPrimaryEndpoint()
            
            completion(response, error)
            
        }
        
    }
    
    func callToTheNetwork() -> AnyPublisher<String, NetworkError> {
        print("Call to the network")
        
        return callTheNetworkWithRetries(retries: maxErrorCount)
            .handleEvents(receiveOutput: { [unowned self] _ in
                self.timerRequestNewEndpoint.invalidate()
            }, receiveCompletion: { [unowned self] _ in
                self.timerRequestNewEndpoint.invalidate()
            }).eraseToAnyPublisher()
        
    }
    
    private func callTheNetworkWithRetries(retries: Int) -> AnyPublisher<String, NetworkError> {
        return Empty(completeImmediately: true).eraseToAnyPublisher()
    }
    
    private func callToTheNetworkWithRetries(retries: Int, completion: (_ response: String?, _ error: NetworkError?) -> Void) {
        
        print("Current endpoint is using \(networkDomain)")
        
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
        
        networkDomain = endpoint
        
    }
    
}
