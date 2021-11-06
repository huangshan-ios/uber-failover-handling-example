//
//  NetworkCanaryRequest.swift
//  uber-failover-handling
//
//  Created by Son Hoang on 06/11/2021.
//

import Foundation

protocol NetworkHealthCheck {
    
    func isEndpoinHealthy(_ endpoint: String, completion: (Bool) -> Void)
    
}

class NetworkHealthCheckImpl: NetworkHealthCheck {
    
    func isEndpoinHealthy(_ endpoint: String, completion: (Bool) -> Void) {
        
    }
    
}
