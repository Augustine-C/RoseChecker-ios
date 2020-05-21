//
//  MasterViewController.swift
//  RoseChecker
//
//  Created by Augustine's MacBook on 5/10/20.
//  Copyright © 2020 Augustine. All rights reserved.
//

import UIKit
import SwiftUI
import Firebase
import Floaty
import GoogleUtilities

class MasterViewController: UITableViewController {
    var temp = 0
    var detailViewController: DetailViewController? = nil
    var objects = [Any]()
    var isShowingAll = true
    var events = [Event]()
    var datePickerStart = UIDatePicker.init()
    var datePickerEnd = UIDatePicker.init()
    var floaty = Floaty()
    var tempStartDate = Date()
    var tempEndDate = Date()
    var alertController = UIAlertController(title: "Create a new Meeting event", message: "", preferredStyle: .alert)


    
    @IBOutlet weak var prevButton: UIBarButtonItem!
    @IBOutlet weak var nextButton: UIBarButtonItem!
    var UpcomingEvent:Event?
    var currentDate:Date = NSDate() as Date
    
    var eventsRef: CollectionReference!
    var eventsListener:ListenerRegistration!
    var authStateListenerHandle:AuthStateDidChangeListenerHandle!
    
    func showUserMessage() -> String{
        let text = isShowingAll ? "Show day by day" : "Show all events"
        return text
    }
    
    func showDeleteMessage() -> (String, UIImage) {
        return !isEditing ? ("Select event to delete", UIImage(systemName: "pencil.circle.fill")!) : ("Done editing", UIImage(systemName: "checkmark.circle.fill")!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        navigationItem.leftBarButtonItem =  prevButton
        
        floaty.friendlyTap = true
        navigationItem.rightBarButtonItem = nextButton
        floaty.isDraggable = true
        floaty.sticky = false
        floaty.hasShadow = true
        floaty.paddingX = 30
        floaty.animationSpeed = 0.05
        let removeItem = FloatyItem()
        removeItem.title = "remove all events"
        removeItem.icon = .remove
        removeItem.titleColor = .systemRed
        removeItem.handler = { item in
            item.titleLabel.textColor = .systemRed
            var count = 0;
            for event in self.events{
                if event.eventType == .CourseEvent{
                    count += 1
                }
            }
            let deleteController = UIAlertController(title: "You are about to delete \(count) events",
            message: "",
            preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            deleteController.addAction(cancelAction)
            
            let confirmAction = UIAlertAction(title: "Confirm", style: .default) { (action) in
                for event in self.events{
                    if event.eventType == .CourseEvent{
                        self.eventsRef.document(event.id).delete()
                    }
                }
            }
            deleteController.addAction(confirmAction)
            self.present(deleteController, animated: true, completion: nil)
            self.floaty.close()
        }
        floaty.addItem(item: removeItem)
        
        
        floaty.addItem("import events", icon: .add, handler: {item in
            
            self.importFile()
            self.floaty.close()
        })
        
        floaty.addItem(showUserMessage(), icon: UIImage(systemName: "calendar.circle.fill"), handler: {item in
            self.isShowingAll.toggle()
            // update the list
            
            self.startListening()
            item.title = self.showUserMessage()
            self.floaty.close()
        })
        
        let(deleteMessage, deleteIcon) = showDeleteMessage()
        floaty.addItem(deleteMessage, icon: deleteIcon) { (item) in
            self.isEditing.toggle()
            self.floaty.close()
            (item.title, item.icon) = self.showDeleteMessage()
        }
        
        floaty.addItem("Add Meeting Event", icon: UIImage(systemName: "calendar.badge.plus")){ (item) in
            self.showAddDialog()
            self.floaty.close()
        }
        
        floaty.addItem("Logout", icon: UIImage(systemName: "arrowshape.turn.up.left.circle.fill")) { (FloatyItem) in
            do{
                try Auth.auth().signOut()
            } catch{
                print("there is something wrong")
            }
            self.floaty.close()
        }
        
        floaty.buttonColor = UIColor.init(red: 0.5, green: 0, blue: 0, alpha: 1)
        floaty.buttonImage = resizeImage(image: UIImage(systemName: "plus")!.withTintColor(.white), targetSize: 2)
        self.parent?.view.addSubview(floaty)
    }
    
     func resizeImage(image: UIImage, targetSize: CGFloat) -> UIImage {
        let size = image.size

        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        newSize = CGSize(width: size.width * targetSize, height: size.height * targetSize)


        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
    
    @objc func showMenu(){
        let menuController = UIAlertController(title: "Menu",
        message: "",
        preferredStyle: .actionSheet)
        let submitAction = UIAlertAction(title: "Import Events", style: .default) {(action) in
            self.importFile()
            
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let logoutAction = UIAlertAction(title: "Logout", style: .destructive) { (action) in
            do{
                try Auth.auth().signOut()
            } catch{
                print("there is something wrong")
            }
        }
        let showDeleteMessage = !isEditing ? "Select event to delete" : "Done editing"
        let delete = UIAlertAction(title: showDeleteMessage, style: .default){ (action) in
            self.setEditing(!self.isEditing, animated: true)
        }
        
        
        
        let showUserMessage = isShowingAll ? "Show day by day" : "Show all events"
        let showToday = UIAlertAction(title: showUserMessage, style: .default) { (action) in
            // toggle the show all vs show mine mode
            self.isShowingAll.toggle()
            // update the list
            
            self.startListening()
        }
        
        menuController.addAction(submitAction)
        menuController.addAction(delete)
        menuController.addAction(showToday)
        menuController.addAction(logoutAction)
        menuController.addAction(cancelAction)

        
        present(menuController, animated: true, completion: nil)
    }
    
    
    @objc func importFile(){
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.calendar-event"], in: .open)
        
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true, completion: nil)
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        eventsRef = Firestore.firestore()
            .collection(Constants.USERS_COLLECTION)
            .document(Auth.auth().currentUser!.uid)
            .collection(Constants.EVENTS_COLLECTION)
        
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if Auth.auth().currentUser == nil{
                self.navigationController?.popViewController(animated: true)
            } else {
                print("Still stayed in")
            }
        }
        tableView.reloadData()
        startListening()
        self.parent?.view.addSubview(floaty)
    }
    
    func startListening(){
        if (eventsListener != nil){
            eventsListener.remove()
        }
        var query = eventsRef.order(by: "startTime", descending: true)
        if !isShowingAll {
            query = query.whereField("timestamp", isEqualTo: CalParser.dateToString(date: currentDate as Date))
        }
        prevButton.isEnabled = !isShowingAll
        nextButton.isEnabled = !isShowingAll
        eventsListener = query.addSnapshotListener({ (querySnapshot, error) in
            if let querySnapshot = querySnapshot {
                self.events.removeAll()
                querySnapshot.documents.forEach { (documentSnapshot) in
                    self.events.append(Event(documentSnapshot: documentSnapshot))
                }
                self.tableView.reloadData()
            } else {
                print("Error getting movie quotes \(error!)")
            }
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        eventsListener.remove()
        Auth.auth().removeStateDidChangeListener(authStateListenerHandle)
        floaty.removeFromSuperview()
    }
    

    @objc
    func insertNewObject(_ sender: Any) {
        objects.insert(NSDate(), at: 0)
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.insertRows(at: [indexPath], with: .automatic)
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                (segue.destination as! DetailViewController).eventRef = eventsRef.document(events[indexPath.row].id)
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 116.0
    }
    
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CalenderCell
        let event = events[indexPath.row]
        let (day, month, _, startT, endT) = CalParser.getDateInfo(event.startTime, event.endTime)
        cell.Date.text = day
        cell.Month.text = month
        cell.Title.text = event.name
        cell.Time.text = "\(startT) - \(endT)"
        cell.Location.text = event.location
//        let object = objects[indexPath.row] as! NSDate
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let eventToDelete = events[indexPath.row]
            eventsRef.document(eventToDelete.id).delete()
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    @objc func dateChanged(){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/HH:mm"
        alertController.textFields![2].text = dateFormatter.string(from: datePickerStart.date)
        tempStartDate = datePickerStart.date
    }
    
    @objc func dateChangedEnd(){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/HH:mm"
        alertController.textFields![3].text = dateFormatter.string(from: datePickerEnd.date)
        tempEndDate = datePickerEnd.date
    }
    
    @objc
    func showAddDialog(){
        alertController = UIAlertController(title: "Create a new Meeting event",
        message: "",
        preferredStyle: .alert)
        //Configure
        
        alertController.addTextField{ (textFiled) in
            textFiled.placeholder = "Meeting name"
            textFiled.font = .systemFont(ofSize: 20)
        }
        
        alertController.addTextField{ (textFiled) in
            textFiled.placeholder = "Meeting Location"
            textFiled.font = .systemFont(ofSize: 20)
        }
        
        datePickerStart = UIDatePicker.init()
        datePickerEnd = UIDatePicker.init()
        self.datePickerStart.datePickerMode = .dateAndTime
        alertController.addTextField{ (textFiled) in
            textFiled.inputView = self.datePickerStart
            textFiled.placeholder = "Meeting Start time"
            textFiled.font = .systemFont(ofSize: 20)
        }
        
        datePickerStart.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        datePickerEnd.addTarget(self, action: #selector(dateChangedEnd), for: .valueChanged)

        alertController.addTextField{ (textFiled) in
            textFiled.inputView = self.datePickerEnd
            textFiled.placeholder = "Meeting End time"
            textFiled.font = .systemFont(ofSize: 20)
        }
        
        alertController.addTextField{ (textFiled) in
            textFiled.placeholder = "Meeting agenda"
            textFiled.font = .systemFont(ofSize: 20)
        }
        
        alertController.addTextField{ (textFiled) in
            textFiled.placeholder = "Members"
            textFiled.font = .systemFont(ofSize: 20)
            
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let submitAction = UIAlertAction(title: "Create", style: .default) {(action) in
        let name = self.alertController.textFields![0].text
        let location = self.alertController.textFields![1].text
        let agenda = self.alertController.textFields![4].text
        let members = self.alertController.textFields![5].text
            // add to database
            
            let event = Event(name: name!, startTime: Timestamp(date: self.tempStartDate), endTime: Timestamp(date: self.tempEndDate), eventType: .MeetingEvent, location: location!)
            event.meetingInfo["meetingAgenda"] = agenda
            event.meetingInfo["meetingMember"] = members

            self.eventsRef.addDocument(data: event.getData())

        }
        alertController.addAction(submitAction)
        let height = NSLayoutConstraint(item: alertController.view!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: self.view.frame.height * 0.9)
        let width = NSLayoutConstraint(item: alertController.view!, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: self.view.frame.width)
        alertController.view.addConstraint(height)
        alertController.view.addConstraint(width)
        present(alertController, animated: true, completion: nil)
        return
    }
    
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: true)
    }
    
    
    @IBAction func nextDay(_ sender: Any) {
        let calendar = Calendar.current
        var dateComponent = DateComponents()
        dateComponent.day = 1;
        let nextDate = calendar.date(byAdding: dateComponent, to: currentDate)
        currentDate = nextDate!
        startListening()
    }
    
    @IBAction func prevDay(_ sender: Any) {
        let calendar = Calendar.current
        var dateComponent = DateComponents()
        dateComponent.day = -1;
        let nextDate = calendar.date(byAdding: dateComponent, to: currentDate)
        currentDate = nextDate!
        startListening()
    }
    
    struct ContentView : View{
        @State var wakeUp = Date()
        
        var body: some View{
            Form{
                DatePicker("test", selection: $wakeUp)
            }
        }
    }

}

class CalenderCell: UITableViewCell {
    @IBOutlet weak var calenderView: UIView!
    @IBOutlet weak var Month: UILabel!
    @IBOutlet weak var Date: UILabel!
    @IBOutlet weak var Title: UILabel!
    @IBOutlet weak var Time: UILabel!
    @IBOutlet weak var Location: UILabel!
    @IBOutlet weak var CAL: UIStackView!
    

        override func awakeFromNib() {
            super.awakeFromNib()
            // Initialization code
        }

        override func setSelected(_ selected: Bool, animated: Bool) {
            super.setSelected(selected, animated: animated)

            // Configure the view for the selected state
        }


    
}

extension MasterViewController: UIDocumentPickerDelegate{
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else{
            return
        }
//        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//        let sandboxFileURL = dir.appendingPathComponent(selectedFileURL.lastPathComponent)
//        if FileManager.default.fileExists(atPath: sandboxFileURL.path){
//            print("File Exist")
//        } else {
//            do{
//                try FileManager.default.copyItem(at: selectedFileURL, to: sandboxFileURL)
//            } catch{
//                print("Error \(error)")
//            }
//        }
        
        do {
//            let fileUrl = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(selectedFileURL.lastPathComponent)
            let needTo = selectedFileURL.startAccessingSecurityScopedResource()
            print(needTo)
            let (eventsImported, count) = try CalParser.parse(selectedFileURL)
            if needTo {
              selectedFileURL.stopAccessingSecurityScopedResource()
            }
            let importController = UIAlertController(title: "You are about to import \(count) events",
            message: "",
            preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            importController.addAction(cancelAction)
            
            let confirmAction = UIAlertAction(title: "Confirm", style: .default) { (action) in
                for event in eventsImported{
                    self.eventsRef.addDocument(data: event.getData())
                }
            }
            importController.addAction(confirmAction)
            present(importController, animated: true, completion: nil)
        } catch let error{
            print(error)
        }
    }
    
    
}

