//
//  Cid.swift
//  TestesSwift
//
//  Created by Radix Engenharia e Software on 14/04/16.
//  Copyright © 2016 Radix Engenharia e Software. All rights reserved.
//

import Foundation
import RealmSwift

class Cid: Object {
    dynamic var id = ""
    dynamic var name: String? = nil
    dynamic var normalized_name: String? = nil
    dynamic var is_group = false
    
    override static func primaryKey() -> String? {
        return "id"
    }
}