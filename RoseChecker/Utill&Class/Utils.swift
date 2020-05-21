//
//  Utils.swift
//  RoseChecker
//
//  Created by Augustine's MacBook on 5/10/20.
//  Copyright © 2020 Augustine. All rights reserved.
//

import UIKit
import Firebase

enum EventType : String{
    case NormalEvent = "NormalEvent"
    case CourseEvent = "CourseEvent"
    case MeetingEvent = "MeetingEvent"
}


class CalParser{

    static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        return dateFormatter
    }()
    
    static func dateToString(date: Date)->String{
        let calendar = Calendar.current.dateComponents(in: .current, from: date)
        let day = calendar.day ?? 0
        let year = calendar.year ?? 0
        let month = calendar.month ?? 0
        print(day)
        print(month)
        print(year)
        let s = "1" + String(year - 2000) + String(month - 1) + String(day)
        return s
    }
    
    static func getDateInfo(_ timestamp: Timestamp,_ timeEnd: Timestamp)->(String, String, String, String, String){
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        
        let calendar = Calendar.current.dateComponents(in: .current, from: timestamp.dateValue())
        let calendarEnd = Calendar.current.dateComponents(in: .current, from: timeEnd.dateValue())
        let day = calendar.day ?? 0
        let year = calendar.year ?? 0
        let month = calendar.month ?? 0
        let monthName = DateFormatter.init().monthSymbols!
        let monthString = monthName[month-1]
        let range = monthString.index(monthString.startIndex, offsetBy: 0)..<monthString.index(monthString.startIndex, offsetBy: 3)
        return (String(day), String(monthString[range]).uppercased(), String(year), dateFormatter.string(from: timestamp.dateValue()),
            dateFormatter.string(from: timeEnd.dateValue()))
    }
    
    public static func parse(_ url:URL)throws -> ([Event], Int){
//        var data : Data!
//        do {
//            data = try Data(contentsOf: url)
//        } catch {
//            print("!!!!!!!!!!")
//            print(error)
//            return []
//        }
        
        print(url)
        print(url.absoluteURL)
        
        var dataString = ""
        do{
            let data = try Data(contentsOf: url)
            
            dataString = String(
              data: data,
              encoding: String.Encoding.utf8
                ) ?? ""
            
            let dataString2 = String(
            data: data.base64EncodedData(),
            encoding: String.Encoding.utf8
              ) ?? ""
            print(dataString2)
        }catch{
            print(error)
        }

        print(dataString)
        var events = [Event]()
        let characterSet = CharacterSet(charactersIn: "\n\r")
        
        
        let icsContent = dataString.components(separatedBy: characterSet)
        var iter = icsContent.makeIterator()
        var count = 0
        while let line = iter.next(){
            print(line)
            if(line.elementsEqual("BEGIN:VEVENT")){
                count+=1
                print(count)
                let name = sbStr(iter.next()!, 8)
                let profname = sbStr(iter.next()!, 37)
                let location = sbStr(iter.next()!, 9)
                var startTime = sbStr(iter.next()!, 8)
                print("size count \(startTime.count) \(startTime)")
                if startTime.count < 14 {
                    print("!!!")
                    startTime = startTime + iter.next()!
                    print(startTime)
                }
                let startDate = dateFormatter.date(from: startTime)
                
//                let timeStamp = dateToString(date: startDate!)
                var endTime = sbStr(iter.next()!, 6)
                if (endTime.count < 14) {
                    endTime = endTime + iter.next()!
                }
                let endDate = dateFormatter.date(from: endTime)

                let event = Event(name: name, startTime: Timestamp(date: startDate!), endTime: Timestamp(date: endDate!), eventType: .CourseEvent, location: location)
                event.courseInfo["keyContent"] = profname
                event.courseInfo["homeWork"] = "Homework: "
                event.courseInfo["source"] = "online"
                events.append(event)
            }
        }
        return (events, count)
    }
    
    public static func sbStr(_ str: String, _ offset: Int) -> String{
        let range = str.index(str.startIndex, offsetBy: offset)..<str.endIndex
        return String(str[range])
    }
    
    
}

class Constants {
    static let EVENTS_COLLECTION = "events"
    static let TAG = "!!!"
    static let USERS_COLLECTION = "users"
    static let INTENT_ACTION = "upcomingEvent"
    static let CHANNEL = "channel"
    static let courseName = "Course"
    static let meetingName = "Subject"
    static let instructorName = "Instructor Name"
    static let homework = "Additional Info"
    static let agenda = "Agenda"
    static let member = "Member"
    static let COURSE = "Course Event"
    static let MEETING = "meeting"
}
