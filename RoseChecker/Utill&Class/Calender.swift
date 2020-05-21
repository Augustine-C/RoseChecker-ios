//
//  Calender.swift
//  RoseChecker
//
//  Created by Augustine's MacBook on 5/10/20.
//  Copyright © 2020 Augustine. All rights reserved.
//

import UIKit
import Firebase
class Event:CustomStringConvertible{

    
    var description: String{
        var des = ""
        let selfMirror = Mirror(reflecting: self)
        for child in selfMirror.children{
            if let propertyName = child.label{
                des += "\(propertyName): \(child.value)\n"
            }
        }
        return des
    }
    var id:String = ""
    var courseInfo:Dictionary<String, String> = [:]
    var meetingInfo:Dictionary<String, String> = [:]
    var startTime:Timestamp
    var timeStamp:String
    var endTime:Timestamp
    var eventType:EventType
    var isfinished: Bool
    var importance:Int
    var location:String
    var name:String
    init(name:String,startTime:Timestamp, endTime:Timestamp, eventType:EventType,
         isfinished: Bool = false, importance:Int = 0, location:String) {
        self.startTime = startTime
        self.endTime = endTime
        self.isfinished = isfinished
        self.importance = importance
        self.location = location
        self.eventType = eventType
        self.timeStamp = CalParser.dateToString(date: startTime.dateValue())
        self.name = name
    }

    init(documentSnapshot: DocumentSnapshot){
        self.startTime = documentSnapshot.data()?["startTime"] as! Timestamp
        self.endTime = documentSnapshot.data()?["endTime"] as! Timestamp
        self.isfinished = documentSnapshot.data()?["finished"] as! Bool
        self.importance = documentSnapshot.data()?["importance"] as! Int
        self.location = documentSnapshot.data()?["location"] as! String
        self.eventType = EventType(rawValue: documentSnapshot.data()?["eventType"] as! String)!
        self.timeStamp = documentSnapshot.data()?["timestamp"] as! String
        self.name = documentSnapshot.data()?["name"] as! String
        self.courseInfo = documentSnapshot.data()?["courseInfo"] as! Dictionary
        self.meetingInfo = documentSnapshot.data()?["meetingInfo"] as! Dictionary
        self.id = documentSnapshot.documentID
    }
    
    func getData() -> Dictionary<String, Any>{
        var data:Dictionary<String, Any> = [:]
        data["startTime"] = self.startTime
        data["endTime"] = self.endTime
        data["finished"] = self.isfinished
        data["importance"] = self.importance
        data["location"] = self.location
        data["timestamp"] = self.timeStamp
        data["name"] = self.name
        data["courseInfo"] = self.courseInfo
        data["meetingInfo"] = self.meetingInfo
        data["eventType"] = self.eventType.rawValue
        return data
    }
    

}
