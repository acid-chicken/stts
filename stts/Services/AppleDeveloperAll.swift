//
//  AppleDeveloperAll.swift
//  stts
//

import Foundation

class AppleDeveloperAll: AppleDeveloper, ServiceCategory {
    let categoryName = "Apple Developer"
    let subServiceSuperclass: AnyObject.Type = BaseAppleDeveloper.self

    let name = "Apple Developer (All)"
    let url = AppleDeveloperServiceDefinition.commonURL
    let serviceName = "*"
}
