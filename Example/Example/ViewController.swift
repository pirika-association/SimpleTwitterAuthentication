//
//  ViewController.swift
//  Example
//
//  Created by Nobuhiro Ito on 7/10/19.
//  Copyright © 2019 Nobuhiro Ito. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func action(_ sender: Any) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let auth = appDelegate.auth
            else { return }
        auth.authenticate { [weak self] result in
            switch result {
            case .success(let token, let secret, let screenName):
                print("token: \(token), secret: \(secret)")
                let alert = UIAlertController(title: "Hello", message: "Hello, \(screenName)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            case .failed(_):
                print("failed")
            case .cancelled:
                print("cancelled")
            }
        }
    }
}

