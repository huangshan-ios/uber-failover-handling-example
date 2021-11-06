//
//  NetworkProvider.swift
//  uber-failover-handling
//
//  Created by Son Hoang on 06/11/2021.
//

import Foundation

protocol NetworkProviderDelegate: AnyObject {
    func switchToNewNetwork(endpoint: String)
}

protocol NetworkProvider {
    
    var networkHealthCheck: NetworkHealthCheck { get }
    
    var delegate: NetworkProviderDelegate? { get set }
    
    var networkState: NetworkState { get }
    
    func requestNewEndPoint()
    
    func usingPrimaryEndpoint()
    
}

class NetworkProviderImpl: NetworkProvider {
    
    let networkHealthCheck: NetworkHealthCheck
    
    var delegate: NetworkProviderDelegate?
    
    var networkState: NetworkState = .primary
    
    private var primaryEndpointTimeoutHealthCheck: TimeInterval = TimeInterval(5000)
    
    private var timerForPrimaryHealthCheck = Timer()
    
    init(networkHealthCheck: NetworkHealthCheck) {
        self.networkHealthCheck = networkHealthCheck
    }
    
    func requestNewEndPoint() {
        
        guard networkState == .primary else { return }
        
        networkState = .failover
        
        healthCheck(for: networkState)
        
    }
    
    func usingPrimaryEndpoint() {
        
        networkState = .primary
        
        timerForPrimaryHealthCheck.invalidate()
        
    }
    
    private func healthCheck(for state: NetworkState) {
        
        guard state == .failover || state == .recovery else { return }
        
        let endpoint: NetworkEndpoint = state == .failover ? NetworkEndpoint.backup : NetworkEndpoint.primary
        
        networkHealthCheck.isEndpoinHealthy(endpoint.rawValue) { isHealthy in
            
            guard isHealthy else { return }
            
            networkState = state == .failover ? .backup : .primary
            
            delegate?.switchToNewNetwork(endpoint: endpoint.rawValue)
            
            if networkState == .backup {
                
                startTimerForPrimaryEndpointHealthCheck()
                
            }
            
        }
        
    }
    
    private func startTimerForPrimaryEndpointHealthCheck() {
        
        timerForPrimaryHealthCheck = Timer(timeInterval: primaryEndpointTimeoutHealthCheck, repeats: false) { [weak self] _ in
            
            guard let self = self else { return }
            
            self.networkState = .recovery
            
            self.healthCheck(for: self.networkState)
            
        }

    }
    
}
