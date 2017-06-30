//
//  ViewController.swift
//  CrashsReport
//
//  Created by 田子瑶 on 2017/6/30.
//  Copyright © 2017年 田子瑶. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let arr: NSArray = [1, 2, 3]
        print(arr[5])
    }
}

