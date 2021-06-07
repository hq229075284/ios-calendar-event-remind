//
//  ViewController.swift
//  autoSetWork
//
//  Created by hanqing on 2021/3/16.
//  Copyright © 2021 hanqing. All rights reserved.
//

import UIKit
import EventKit

class ViewController: UIViewController,UITextViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
//        textareaValue.delegate=self
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
//    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
//        print(text)
//        if(text == "\n") {
//            textareaValue.resignFirstResponder()
//            return false
//        }
//        return true
//    }
    
    func trim(_ s:Substring.SubSequence)->String{
        return s.trimmingCharacters(in: .whitespaces)
    }
    
    func permissionComplete(_ allow:Bool, _err:Error?) -> Void {
        if allow {
            print("允许")
        } else {
            print("deny")
        }
    }
    
    func transformDate(_ s:String)->Date{
        let now=selectedDate.date
        let df=DateFormatter()
//        df.timeZone=TimeZone.current
//        df.locale = Locale(identifier: "zh_Hans_CN")
        df.dateFormat="yyyy/MM/dd HH:mm:ss"
        var dateStr=df.string(from: now)
        dateStr=String(dateStr[..<dateStr.index(dateStr.startIndex, offsetBy: 10)])
        return df.date(from: dateStr+" "+s+":00")!
        
    }
    
    @IBOutlet weak var selectedDate: UIDatePicker!
    @IBOutlet weak var textareaValue: UITextView!
    @IBAction func clickButton(_ sender: UIButton) {
        var rows=textareaValue.text.split(separator: "\n")
        rows=rows.filter{ (row)->Bool in
            return row.count>0
        }
        let tasks=rows.map{$0.split(separator: "\t")}
        struct Task{
            var startTime:String
            var endTime:String
            var content:String
            init(_ s:String,_ e:String,_ c:String) {
                startTime=s
                endTime=e
                content=c
            }
        }
        var result=[Task]()
        
        for task in tasks {
            var _time:[String]=task[0].split(separator: "~").map(trim)
            result.append(Task(_time[0],_time[1],String(task[1])))
        }
        
        let store=EKEventStore()
        store.requestAccess(to: .event, completion: permissionComplete)
        let matchfn=store.predicateForEvents(withStart:transformDate("00:00"),end:transformDate("23:59"),calendars:nil)
        let existEvents=store.events(matching: matchfn)
        
        for event in existEvents{
            do{
                try  store.remove(event, span: .thisEvent)
                print(event.title+"->删除成功")
            }catch{}
        }
        
        print("------split line------")

        for item in result {
            let newEvent = EKEvent(eventStore: store)
            let alarm = EKAlarm(absoluteDate: transformDate(item.startTime))
            newEvent.title=item.content
            newEvent.notes=item.content
            newEvent.addAlarm(alarm)
            newEvent.startDate = transformDate(item.startTime)
            newEvent.endDate = transformDate(item.endTime)
            newEvent.calendar = store.defaultCalendarForNewEvents
            do{
                try store.save(newEvent, span: .thisEvent)
                print("\(item.content)->添加成功")
            }catch{}
        }
       
        let alert = UIAlertController(title: "提示", message: "行程添加成功", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "朕已阅", style: .default, handler: nil)
        alert.addAction(cancelAction)
        self.present(alert,animated:true,completion: nil)
    }
    
}

