//
//  BiometricsTypeManager.swift
//  CSLockerUI
//
//  Created by Michal Sverak on 10/11/17.
//  Copyright © 2017 Applifting. All rights reserved.
//

import Foundation
import LocalAuthentication

enum biometricType {
    case touchID
    case faceID
}

class BiometricsTypeManager {
    
    static let shared = BiometricsTypeManager()
    let context = LAContext()
    
    func deviceUsedBiometricType() -> biometricType {
        
        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: nil),
            #available(iOS 11.0, *),
            context.biometryType == LABiometryType.faceID {

                return .faceID
            }
        return .touchID
    }
}
