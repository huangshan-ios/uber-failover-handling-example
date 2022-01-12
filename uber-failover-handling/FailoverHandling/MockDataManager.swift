//
//  ExampleState.swift
//  uber-failover-handling
//
//  Created by Son Hoang on 06/11/2021.
//

import Foundation

class MockDataManager {
    
    static let shared = MockDataManager()
    
    
    
}

extension MockDataManager {
    
    enum MockNetworkState {
        case failover
        case failoverAndBackToPrimary
        case backup
        case backupAndRecoveryFailed
        case backupAndRecoverySuccess
    }
    
}
