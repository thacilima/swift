//
//  SearchViewController.swift
//  TestesSwift
//
//  Created by Radix Engenharia e Software on 20/04/16.
//  Copyright © 2016 Radix Engenharia e Software. All rights reserved.
//

import UIKit
import RealmSwift

protocol SearchSelectionHandler {
    func selectObject(object: Object)
    func addAndSelectObject(objectDetail: String)
    func filterObjectsForEmptySearch() -> [Object]
    func filterObjectsForSearch(text: String) -> [Object]
    func getObjectDetail(object: Object) -> String
}

class SearchViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UIBarPositioningDelegate {
    
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchAutoCompleteTableView: UITableView!

    var searchSelectionHandler: SearchSelectionHandler? = nil
    let addObjectOption = false
    
    private var searchResult: [Object] = []
    private var autoCompleteTimer = NSTimer()
    
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.TopAttached
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        searchResult = searchSelectionHandler!.filterObjectsForEmptySearch()
    }
    
    @IBAction func cancelSearch() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func autoCompleteTimerAction() {
        if searchTextField.text!.characters.count > 0 {
             searchResult = searchSelectionHandler!.filterObjectsForSearch(searchTextField.text!)
        }
        else {
            searchResult = searchSelectionHandler!.filterObjectsForEmptySearch()
        }
        
        
        searchAutoCompleteTableView.reloadData()
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        autoCompleteTimer.invalidate()
        autoCompleteTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector:#selector(autoCompleteTimerAction), userInfo: nil, repeats: false)
        
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        autoCompleteTimer.invalidate()
        searchTextField.resignFirstResponder()
        return true
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searchResult.count == 0 {
            tableView.hidden = true
        }
        else {
            tableView.hidden = false
        }
        
        return getTotalObjects()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell:UITableViewCell = searchAutoCompleteTableView.dequeueReusableCellWithIdentifier("SearchResultCell")! as UITableViewCell
        
        if (indexPath.row == 0 && addObjectOption) {
            cell.textLabel?.text = "[ + ]"
        }
        else {
            let objectDetail = searchSelectionHandler?.getObjectDetail(searchResult[getObjectIndexForIndexPath(indexPath)])
            
            let attributedString = NSMutableAttributedString(string:objectDetail!)
            let attrs = [NSFontAttributeName : UIFont.boldSystemFontOfSize(18)]
            
            let wordsInTextSearch = searchTextField.text!.componentsSeparatedByString(" ")
            for word in wordsInTextSearch {
                let range = (objectDetail! as NSString).rangeOfString(word)
                attributedString.addAttributes(attrs, range: range)
            }
            
            cell.textLabel?.attributedText = attributedString
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        autoCompleteTimer.invalidate()
        
        if (indexPath.row == 0 && addObjectOption) {
            searchSelectionHandler!.addAndSelectObject(searchTextField.text!)
        }
        else {
            searchSelectionHandler!.selectObject(searchResult[getObjectIndexForIndexPath(indexPath)])
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    private func getTotalObjects() -> Int {
        var totalObjects = searchResult.count
        if addObjectOption {
            totalObjects += 1
        }
        
        return totalObjects
    }
    
    private func getObjectIndexForIndexPath(indexPath: NSIndexPath) -> Int {
        var objectIndex = indexPath.row
        if addObjectOption {
            objectIndex -= 1
        }
        
        return objectIndex
    }
}
