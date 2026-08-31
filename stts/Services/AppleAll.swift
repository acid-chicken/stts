//
//  AppleAll.swift
//  stts
//

import Foundation

class AppleAll: Apple, ServiceCategory {
    let categoryName = "Apple"
    let subServiceSuperclass: AnyObject.Type = BaseApple.self

    let name = "Apple (All)"
    let url = AppleServiceDefinition.commonURL
    let serviceName = "*"
}
