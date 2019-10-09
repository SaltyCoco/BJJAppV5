//
//  TblClassLogTest.swift
//  BJJAppV5
//
//  Created by Ryan Schulte on 10/3/19.
//  Copyright © 2019 meyita. All rights reserved.
//

import Foundation
import UIKit
import AWSDynamoDB

class TblClassLogTest: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    @objc var _userId: String?
    @objc var _date: String?
    @objc var _class: String?
    @objc var _username: String?
    @objc var _uldate: String?
    
    class func dynamoDBTableName() -> String {
        return "bjjapp-mobilehub-664403763-tblClassLog"
    }
    
    class func hashKeyAttribute() -> String {
        
        return "_userId"
    }
}
