//
//  ViewController.swift
//  iCalendarKitDemo
//
//  Created by tramp on 2021/3/3.
//

import UIKit
import iCalendarKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        /**
         1*(eventc / todoc / journalc / freebusyc /
                             timezonec / iana-comp / x-comp)
         
         ;
                        ; The following are OPTIONAL,
                        ; but MUST NOT occur more than once.
                        ;
                        (";" cutypeparam) / (";" memberparam) /
                        (";" roleparam) / (";" partstatparam) /
                        (";" rsvpparam) / (";" deltoparam) /
                        (";" delfromparam) / (";" sentbyparam) /
                        (";" cnparam) / (";" dirparam) /
                        (";" languageparam) /
         
         
         ATTENDEE;ROLE=NON-PARTICIPANT;PARTSTAT=DELEGATED;DELEGATED-TO="mailto:hcabot@example.com";CN=The Big Cheese:mailto:iamboss@example.com
         
         
         
         */
        
        guard let url = Bundle.main.url(forResource: "ATT00002", withExtension: "ics") else { return }
        do {
            let serialization = try CKSerialization.init(with: url)
            let calendars = try serialization.calendars()
            calendars.forEach { (cal) in
                print(cal.text)
            }
        } catch {
            print(error)
        }
        
    }


}

