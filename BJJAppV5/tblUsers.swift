//
//  tblUsers.swift
//  BJJAppV5
//
//  Created by Ryan Schulte on 10/4/19.
//  Copyright © 2019 meyita. All rights reserved.
//

import Foundation
import UIKit
import AWSDynamoDB

class tbl_Users: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    @objc var _username: String?
    @objc var _email: String?
    @objc var _phonenumber: NSObject?
    @objc var _usergivenname: String?
    @objc var _beltrank: String?
    
    class func dynamoDBTableName() -> String {
        return "bjjapp_users"
    }
    
    class func hashKeyAttribute() -> String {
        
        return "_username"
    }
    
    override class func jsonKeyPathsByPropertyKey() -> [AnyHashable: Any] {
        return [
            "_username" : "username",
            "_email" : "email",
            "_phonenumber" : "phonenumber",
            "_usergivenname" : "usergivenname",
            "_beltrank" : "beltrank"
        ]
    }
}
