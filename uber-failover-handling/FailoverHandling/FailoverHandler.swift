//
//  FailoverHandler.swift
//  uber-failover-handling
//
//  Created by Son Hoang on 16/11/2021.
//

import Foundation

protocol FailoverHandler {
    
    var onSwitchDomain: ((String) -> Void)? { get set }
    
}

class FailoverHandlerImpl: FailoverHandler {
    
    var onSwitchDomain: ((String) -> Void)?
    
}
