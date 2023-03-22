//
//  ViewController.swift
//  Jonglamofire
//
//  Created by whdvy95 on 03/14/2023.
//  Copyright (c) 2023 whdvy95. All rights reserved.
//

import UIKit
import Jonglamofire

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        JF.request("https://jsonplaceholder.typicode.com/posts")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

