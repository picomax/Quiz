//
//  SignInViewController.swift
//  Quiz
//
//  Created by picomax on 04/08/2017.
//  Copyright © 2017 picomax. All rights reserved.
//

import UIKit
import SkyFloatingLabelTextField
import Firebase

class SignInViewController: UIViewController {
    @IBOutlet fileprivate weak var emailField: SkyFloatingLabelTextField!
    @IBOutlet fileprivate weak var passwordField: SkyFloatingLabelTextField!
    
    
    @IBAction func didSelectSignIn() {
        guard let email = emailField.text, let password = passwordField.text else {
            let alert = UIAlertController(text: "Enter email and password", actionTitle: "OK")
            present(alert, animated: true, completion: nil)
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (user, error) in
            guard let strongSelf = self else { return }
            guard let user = user else {
                dLog("failed to sign in ", error?.localizedDescription ?? "unknow error")
                return
            }
            
            dLog("signed in ", user.email)
            strongSelf.dismiss()
        }
    }
    
    @IBAction func didSelectSignUp() {
        guard let email = emailField.text, let password = passwordField.text else {
            let alert = UIAlertController(text: "Enter email and password", actionTitle: "OK")
            present(alert, animated: true, completion: nil)
            return
        }
        
        guard isEmailValid(email), isPasswordValid(password) else {
            let alert = UIAlertController(text: "Email or Password condition is wrong", actionTitle: "OK")
            present(alert, animated: true, completion: nil)
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] (user, error) in
            guard let strongSelf = self else { return }
            guard let user = user else {
                dLog("failed to create user ", error?.localizedDescription ?? "unknown error")
                return
            }
            
            dLog("created ", user.email)
            strongSelf.dismiss()
        }
    }
}

extension SignInViewController {
    fileprivate func isEmailValid(_ email: String) -> Bool {
        return true
    }
    
    fileprivate func isPasswordValid(_ password: String) -> Bool {
        return true
    }
    
    fileprivate func dismiss() {
        dismiss(animated: true, completion: nil)
    }
}
