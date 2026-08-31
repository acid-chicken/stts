//
//  AWSServices.swift
//  stts
//

import Foundation

final class AWSServices: AWSAllService, ServiceCategory {
    let categoryName = "Amazon Web Services"
    let subServiceSuperclass: AnyObject.Type = BaseAWSNamedService.self

    let name = "AWS (All)"
    let url = commonAWSURL
}
