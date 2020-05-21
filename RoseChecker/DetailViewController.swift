//
//  DetailViewController.swift
//  RoseChecker
//
//  Created by Augustine's MacBook on 5/10/20.
//  Copyright © 2020 Augustine. All rights reserved.
//

import UIKit
import Firebase
class DetailViewController: UIViewController {
    
    var detailItem: Event?
    
    var tempStartDate = Date()
    var tempEndDate = Date()
    var eventRef: DocumentReference!
    var eventListener:ListenerRegistration!

    @IBOutlet weak var locationText: UITextField!
    var datePickerStart = UIDatePicker.init()
    var datePickerEnd = UIDatePicker.init()
    
    let dateFormatter : DateFormatter = {
       let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/HH:mm"
        return dateFormatter
    }()
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var NameLabel: UILabel!
    
    @IBOutlet weak var detailOneLabel: UILabel!
    @IBOutlet weak var detailTwoLabel: UILabel!
    
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var startTime: UITextField!
    @IBOutlet weak var endTime: UITextField!
    
    @IBOutlet weak var detailOneText: UITextField!
    @IBOutlet weak var detailTwoText: UITextView!
    
    func configureView() {
        // Update the user interface for the detail item.
       
        nameText.isEnabled = isEditing
        startTime.isEnabled = isEditing
        endTime.isEnabled = isEditing
        locationText.isEnabled = isEditing
        detailOneText.isEnabled = isEditing
        detailTwoText.isEditable = isEditing
        
        if let detail = detailItem {
            tempStartDate = detail.startTime.dateValue()
            tempEndDate = detail.endTime.dateValue()
            datePickerStart.date = tempStartDate
            datePickerEnd.date = tempEndDate
            switch detail.eventType {
            case .CourseEvent:
                titleLabel.text = Constants.COURSE
                NameLabel.text = Constants.courseName
                
                detailOneLabel.text = Constants.instructorName
                detailTwoLabel.text = Constants.homework
                
                detailOneText.text = detail.courseInfo["keyContent"]
                detailTwoText.text = detail.courseInfo["homeWork"]
                
            case .MeetingEvent:
                titleLabel.text = Constants.MEETING
                NameLabel.text = Constants.meetingName
                
                detailOneLabel.text = Constants.member
                detailTwoLabel.text = Constants.agenda
                
                detailOneText.text = detail.meetingInfo["meetingMember"]
                detailTwoText.text = detail.meetingInfo["meetingAgenda"]
            case .NormalEvent:
                print("did not implement")
            }
            nameText.text = detail.name
            let startDate = detail.startTime.dateValue()
            let endDate = detail.endTime.dateValue()
            startTime.text = dateFormatter.string(from: startDate)
            endTime.text = dateFormatter.string(from: endDate)
            
            startTime.inputView = datePickerStart
            endTime.inputView = datePickerEnd
            locationText.text = detail.location
            
        }
        

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let tapGesture = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
               tapGesture.cancelsTouchesInView = false
               self.view.addGestureRecognizer(tapGesture)
        
        datePickerStart.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        datePickerEnd.addTarget(self, action: #selector(dateChangedEnd), for: .valueChanged)
        
        configureView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        eventListener = eventRef.addSnapshotListener { (documentSnapshot, error) in
            if let error = error{
                print("Error getting event \(error)")
                return
            }
            if !documentSnapshot!.exists{ // could be deleted
                //might go back to the list since someone else deleted this document.
                print("might go back to the list since someone else deleted this document.")
                return
            }
            self.detailItem = Event(documentSnapshot: documentSnapshot!)
            self.navigationItem.rightBarButtonItem = self.editButtonItem
            self.configureView()
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        if let detail = detailItem{
        if !isEditing {

            switch detail.eventType {
               case .CourseEvent:
                detail.courseInfo.updateValue(detailOneText.text!, forKey: "keyContent")
                detail.courseInfo.updateValue(detailTwoText.text!, forKey: "homeWork")
               case .MeetingEvent:
                detail.meetingInfo.updateValue(detailOneText.text!, forKey: "meetingMember")
                detail.meetingInfo.updateValue(detailTwoText.text!, forKey: "meetingAgenda")
               case .NormalEvent:
                   print("did not implement")
               }
            detail.name = nameText.text!
            detail.startTime = Timestamp(date: self.tempStartDate)
            detail.endTime = Timestamp(date: self.tempEndDate)
            detail.location = locationText.text!
            eventRef.updateData(detailItem!.getData())
            }
        }
        configureView()
    }
    

    
    @objc func dateChanged(){

        startTime.text = dateFormatter.string(from: datePickerStart.date)
        tempStartDate = datePickerStart.date
    }
    
    @objc func dateChangedEnd(){

        endTime.text = dateFormatter.string(from: datePickerEnd.date)
        tempEndDate = datePickerEnd.date
    }


}

