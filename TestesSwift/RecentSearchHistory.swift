//
//  HistoricoBuscaRecente.swift
//  TestesSwift
//
//  Created by Radix Engenharia e Software on 27/04/16.
//  Copyright © 2016 Radix Engenharia e Software. All rights reserved.
//

import Foundation
import RealmSwift

class RecentSearchHistory: Object {
    let cids = List<Cid>()
    
    func pushCid(cid: Cid) {
        if !cids.contains({$0.id == cid.id}) {
            if cids.count == 15 {
                cids.removeAtIndex(0)
            }
            cids.append(cid)
        }
    }
}