//
//  AWSRegions.swift
//  stts
//

import Foundation

final class AWSRegions: AWSAllService, ServiceCategory {
    let categoryName = "Amazon Web Services (by region)"
    let subServiceSuperclass: AnyObject.Type = BaseAWSRegionService.self

    let name = "AWS Regions (All)"
    let url = commonAWSURL
}
