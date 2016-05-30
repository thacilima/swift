//
//  ViewController.swift
//  TestesSwift
//
//  Created by Radix Engenharia e Software on 13/04/16.
//  Copyright © 2016 Radix Engenharia e Software. All rights reserved.
//

import UIKit
import RealmSwift

class ViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, SearchSelectionHandler {

    
    @IBOutlet weak var cidAutoComplete: AutoCompleteTextField!
    
    @IBOutlet weak var cidTextField: UITextField!
    @IBOutlet weak var cidAutoCompleteTableView: UITableView!
    
    @IBOutlet weak var cidFieldButton: UIButton!
    @IBOutlet weak var cidLabel: UILabel!
    
    var cids: [String?] = []
    var autoCompleteTimer = NSTimer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        estudandoParte1()
        
        //Realm tests
        print(Realm.Configuration.defaultConfiguration.path!)
        let config = Realm.Configuration(
            path: NSBundle.mainBundle().pathForResource("cid", ofType:"realm"),
            readOnly: true)
        
        let realm = try! Realm(configuration: config)
        
        let results = realm.objects(Cid).filter("name CONTAINS[c] %@", "cólon")
        print(results)
        
        //Autocomplete tests
        configureCidAutoCompleteTextField()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "searchSegue" {
            let nextViewController: SearchViewController = segue.destinationViewController as! SearchViewController
            nextViewController.searchSelectionHandler = self
        }
    }
    
    @IBAction func unwindToContainerViewController(segue: UIStoryboardSegue) {
        
    }
    
    func selectObject(object: Object) {
        let cidSelected: Cid = object as! Cid
        addCidToRecentSearchHistory(cidSelected)
        cidLabel.text = "\(cidSelected.id) - \(cidSelected.name!)"
    }
    
    func addAndSelectObject(objectDetail: String) {
        //TODO Adicionar
        cidLabel.text = objectDetail
    }
    
    func filterObjectsForEmptySearch() -> [Object] {
        let defaults = NSUserDefaults.standardUserDefaults()
        let cidRecentSearchHistoryArray = defaults.objectForKey("CidRecentSearchHistory") as? [String] ?? [String]()
        
        let config = Realm.Configuration(
            path: NSBundle.mainBundle().pathForResource("cid", ofType:"realm"),
            readOnly: true)
        let realm = try! Realm(configuration: config)
        let predicate = NSPredicate(format:"id IN %@", cidRecentSearchHistoryArray)
        let results = realm.objects(Cid).filter(predicate).sorted("name")
        
        var searchResult: [Object] = []
        if results.count > 0 {
            for result in results {
                searchResult.append(result)
            }
        }
        
        return searchResult
    }
    
    func filterObjectsForSearch(text: String) -> [Object] {
        let textDiacriticInsensitive = text.stringByFoldingWithOptions(.DiacriticInsensitiveSearch, locale: NSLocale.currentLocale())
        let wordsInTextSearch = textDiacriticInsensitive.componentsSeparatedByString(" ")
        
        let config = Realm.Configuration(
            path: NSBundle.mainBundle().pathForResource("cid", ofType:"realm"),
            readOnly: true)
        let realm = try! Realm(configuration: config)
        
        var subpredicates: [NSPredicate] = []
        for word in wordsInTextSearch {
            if word.characters.count > 0 {
                let predicate = NSPredicate(format: "normalized_name CONTAINS[c] %@", word)
                subpredicates.append(predicate)
            }
        }
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
        let results = realm.objects(Cid).filter(predicate).sorted("name")
        
        var searchResult: [Object] = []
        if results.count > 0 {
            for result in results {
                searchResult.append(result)
            }
        }
       
        return searchResult
    }
    
    func getObjectDetail(object: Object) -> String {
        let cid = object as! Cid
        return cid.name!
    }
    
    func addCidToRecentSearchHistory(cid: Cid) {
        let defaults = NSUserDefaults.standardUserDefaults()
        var cidRecentSearchHistoryArray = defaults.objectForKey("CidRecentSearchHistory") as? [String] ?? [String]()
        if (cidRecentSearchHistoryArray.count == 15) {
            cidRecentSearchHistoryArray.removeFirst()
        }
        cidRecentSearchHistoryArray.append(cid.id)
        defaults.setObject(cidRecentSearchHistoryArray, forKey: "CidRecentSearchHistory")
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        autoCompleteTimer.invalidate()
        autoCompleteTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector:#selector(ViewController.autoCompleteTimerAction), userInfo: nil, repeats: false)
        
        return true
    }
    
    func autoCompleteTimerAction() {
        let config = Realm.Configuration(
            path: NSBundle.mainBundle().pathForResource("cid", ofType:"realm"),
            readOnly: true)
        let realm = try! Realm(configuration: config)
        let results = realm.objects(Cid).filter("name CONTAINS[c] %@", cidTextField.text!).sorted("name")
        
        if results.count > 0 {
            cids = []
            for cid in results {
                cids.append(cid.name)
            }
        }
        else {
            cids = []
        }
        
        cidAutoCompleteTableView.reloadData()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        autoCompleteTimer.invalidate()
        cidTextField.resignFirstResponder()
        return true
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if cids.count == 0 {
            tableView.hidden = true
        }
        else {
            tableView.hidden = false
        }
        
        return cids.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:UITableViewCell = cidAutoCompleteTableView.dequeueReusableCellWithIdentifier("cidCell")! as UITableViewCell
        
        cell.textLabel?.text = cids[indexPath.row]
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        autoCompleteTimer.invalidate()
        
        cidTextField.text = tableView.cellForRowAtIndexPath(indexPath)?.textLabel?.text
        
        tableView.hidden = true
    }
    
    private func configureCidAutoCompleteTextField() {
        cidAutoComplete.autoCompleteTextColor = UIColor(red: 128.0/255.0, green: 128.0/255.0, blue: 128.0/255.0, alpha: 1.0)
        cidAutoComplete.autoCompleteTextFont = UIFont(name: "HelveticaNeue-Light", size: 12.0)!
        cidAutoComplete.autoCompleteCellHeight = 35.0
        cidAutoComplete.maximumAutoCompleteCount = 20
        cidAutoComplete.hidesWhenSelected = true
        cidAutoComplete.hidesWhenEmpty = true
        cidAutoComplete.enableAttributedText = true
        var attributes = [String:AnyObject]()
        attributes[NSForegroundColorAttributeName] = UIColor.blackColor()
        attributes[NSFontAttributeName] = UIFont(name: "HelveticaNeue-Bold", size: 12.0)
        cidAutoComplete.autoCompleteAttributes = attributes
        
        cidAutoComplete.onTextChange = {[weak self] text in
            if !text.isEmpty {
                let config = Realm.Configuration(
                    path: NSBundle.mainBundle().pathForResource("cid", ofType:"realm"),
                    readOnly: true)
                let realm = try! Realm(configuration: config)
                let results = realm.objects(Cid).filter("name CONTAINS[c] %@", text).sorted("name")
                
                let nomesCid = results.dictionaryWithValuesForKeys(["name"])["name"]
                self?.cidAutoComplete.autoCompleteStrings = nomesCid as? [String]
            }
        }
        
        cidAutoComplete.onSelect = {[weak self] text, indexpath in
            
        }
    }
    
    func estudandoParte1() {
        print("OK")
        
        let floatVar: Float = 4
        print(floatVar)
        
        var emptyArray = [String]()
        var emptyDic = [String: Float]()
        
        emptyArray.append("Hey")
        emptyDic.updateValue(4.0, forKey: "first")
        
        print(emptyArray)
        print(emptyDic)
        
        var shoppingList = ["catfish", "water", "tulips", "blue paint"]
        shoppingList[1] = "bottle of water"
        
        var ocupations = [
            "Thaci": "Intern",
            "Igor": "Analist"
        ]
        ocupations["Amanda"] = "Analist"
        
        //Empty array
        shoppingList = []
        print(shoppingList)
        //Empty dic
        ocupations = [:]
        print(ocupations)
        
        let individualScores = [75, 80, 103, 200, 12]
        var teamScore = 0
        for score in individualScores {
            if score > 50 {
                teamScore += 3
            }
            else {
                teamScore += 1
            }
        }
        print(teamScore)
        
        var optionalString: String? = "Hello"
        print(optionalString == nil)
        
        var optionalName: String? = nil
        var greeting = "Hello!"
        if let name = optionalName {
            greeting = "Hello, \(name)"
        }
        print(greeting)
        
        let nickName: String? = "thacilima"
        let fullName = "Thaciana Lima"
        let informalGreenting = "Hi \(nickName ?? fullName)"
        print(informalGreenting)
        
        let vegetable = "red pepper"
        switch vegetable {
        case "celery":
            print("Add some raisins.")
        case "cucumber", "watercress":
            print("Make a tea sanduich.")
        case let x where x.hasSuffix("pepper"):
            print("Is it a spicy \(x)?")
        default:
            print("Everything tastes good in soup.")
        }
        
        let interestingNumbers = [
            "Prime": [2, 3, 5, 7, 11, 13],
            "Fibonacci": [1, 1, 2, 3, 5, 8],
            "Square": [1, 4, 9, 16, 25],
            ]
        var largest = 0
        var largestKind: String? = nil
        var largestHistory = [largest]
        for (kind, numbers) in interestingNumbers {
            for number in numbers {
                if number > largest {
                    largest = number
                    largestHistory.append(largest)
                    largestKind = kind
                }
            }
        }
        print("\(largestKind!): \(largest)")
        
        var n = 2
        while n < 100 {
            n = n * 2
        }
        print(n)
        
        var m = 2
        repeat {
            m = m * 2
        } while m < 100
        print(m)
        
        var total = 0
        for i in 0..<4 {
            total += i
        }
        print(total)
        
        print(greet("Thaci", day: "Wednesday"))
        
        let statistics1 = calculateStatistics([20, 25, 87, 91, 21, 90])
        print(statistics1.sum)
        print(statistics1.2)
        
        print("\(sumOf(3, 4, 5, 6, 7))")
        print("\(sumOf())")
        print("\(returnFifteen())")
        
        let numbers = [20, 12, 11, 45, 2, 11]
        let anyLessThanTen = hasAnyMatches(numbers, condition: lessThanTen)
        print(anyLessThanTen)
        
        let mappedNumbers = numbers.map({
            (number: Int) -> Int in
            let result = number * 3
            return result
        })
        print(mappedNumbers)
        
        let sortedNumbers = numbers.sort { $0 > $1 }
        print(sortedNumbers)
        
        let shape = Shape()
        shape.numberOfSides = 4
        let shapeDescription = shape.simpleDescription()
        print(shapeDescription)
        
        let namedShape = NamedShape(name: "Triangle")
        namedShape.numberOfSides = 3
        print(namedShape.simpleDescription())
        
        let test = Square(name: "my test square", sideLength: 3.4)
        test.area()
        test.simpleDescription()
        
        let triangle = EquilateralTriangle(name: "my new triangle", sideLength: 3.0)
        print(triangle.perimeter)
        triangle.perimeter = 12.3
        print(triangle.sideLength)
        
        var triangleAndSquare = TriangleAndSquare(name: "one more test", size: 3.0)
        print(triangleAndSquare.square.sideLength)
        print(triangleAndSquare.triangle.sideLength)
        triangleAndSquare.square = Square(name: "one another more test", sideLength: 50)
        print(triangleAndSquare.triangle.sideLength)
        
        //Range in array
        let array = Array(0...3)
    }
    
    func greet(name: String, day: String) -> String {
        return "Hello \(name), today is \(day)."
    }
    
    func calculateStatistics(scores: [Int]) -> (min: Int, max: Int, sum: Int) {
        var min = scores[0]
        var max = scores[0]
        var sum = 0
        
        for score in scores {
            if score > max {
                max = score
            } else if score < min {
                min = score
            }
            sum += score
        }
        
        return (min, max, sum)
    }
    
    func sumOf(numbers: Int...) -> Int {
        var sum = 0
        
        for number in numbers {
            sum += number
        }
        
        return sum
    }
    
    func returnFifteen() -> Int {
        var y = 10
        func add() {
            y += 5
        }
        add()
        return y
    }
    
    func hasAnyMatches(list: [Int], condition: (Int) -> Bool) -> Bool {
        for item in list {
            if (condition(item)) {
                return true
            }
        }
        
        return false
    }
    
    func lessThanTen(number: Int) -> Bool {
        if number < 10 {
            return true
        }
        
        return false
    }
}

class Shape {
    var numberOfSides = 0
    
    func simpleDescription() -> String {
        return "A shape with \(numberOfSides) sides."
    }
}

class NamedShape {
    var numberOfSides = 0
    var name: String
    
    init(name: String) {
        self.name = name
    }
    
    func simpleDescription() -> String {
        return "A shape with \(numberOfSides) sides."
    }
}

class Square: NamedShape {
    var sideLength: Double
    
    init(name: String, sideLength: Double) {
        self.sideLength = sideLength
        super.init(name: name)
        numberOfSides = 4
    }
    
    func area() -> Double {
        return sideLength * sideLength
    }
    
    override func simpleDescription() -> String {
        return "A square with sides of length \(sideLength)."
    }
}

class EquilateralTriangle: NamedShape {
    var sideLength: Double
    
    init(name: String, sideLength: Double) {
        self.sideLength = sideLength
        super.init(name: name)
        numberOfSides = 3
    }
    
    var perimeter: Double {
        get {
            return 3 * sideLength
        }
        set {
            sideLength = newValue / 3.0
        }
    }
    
    override func simpleDescription() -> String {
        return "An equilateral triangle with sides of length \(sideLength)."
    }
}

class TriangleAndSquare {
    var triangle: EquilateralTriangle {
        willSet {
            square.sideLength = newValue.sideLength
        }
    }
    
    var square : Square {
        willSet {
            triangle.sideLength = newValue.sideLength
        }
    }
    
    init(name: String, size: Double) {
        square = Square(name: name, sideLength: size)
        triangle = EquilateralTriangle(name: name, sideLength: size)
    }
}