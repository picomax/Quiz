//
//  MainViewController.swift
//  Quiz
//
//  Created by picomax on 04/08/2017.
//  Copyright © 2017 picomax. All rights reserved.
//

import UIKit
import SnapKit
import FirebaseAuth

enum QuizFeature {
    case map
    case video
    
    init(rawValue: Int) {
        switch rawValue {
        case 0: self = .map
        case 1: self = .video
        default: self = .map
        }
    }
    
    func title() -> String {
        switch self {
        case .map: return "Quiz #1 - MapView"
        case .video: return "Quiz #2 - Record Video"
        }
    }
}

class MainViewController: UIViewController {
    @IBOutlet fileprivate weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont.systemFont(ofSize: 13),
                                                                   NSForegroundColorAttributeName: UIColor.gray]
        
        let signoutButton = UIButton(frame: .zero)
        signoutButton.setTitle("SIGN OUT", for: .normal)
        signoutButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        signoutButton.setTitleColor(.blue, for: .normal)
        signoutButton.sizeToFit()
        signoutButton.addTarget(self, action: #selector(didSelectSignOut), for: .touchUpInside)
        let rightBarButtonItem = UIBarButtonItem(customView: signoutButton)
        navigationItem.rightBarButtonItem = rightBarButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateNavigationTitle()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showSignInViewControllerIfNeeded()
    }
    
    func didSelectSignOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            let alert = UIAlertController(text: error.localizedDescription, actionTitle: "OK")
            present(alert, animated: true, completion: nil)
            return
        }
        showSignInViewControllerIfNeeded()
    }
    
    fileprivate func updateNavigationTitle() {
        guard let user = Auth.auth().currentUser else {
            navigationItem.title = ""
            return
        }
        navigationItem.title = user.email ?? user.displayName ?? ""
    }
    
    fileprivate func showSignInViewControllerIfNeeded() {
        guard Auth.auth().currentUser == nil else { return }
        let vc = UIStoryboard(name: "SignIn", bundle: nil).instantiateInitialViewController() as! SignInViewController
        vc.modalPresentationStyle = .currentContext
        navigationController?.present(vc, animated: true, completion: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.navigationController?.popToRootViewController(animated: false)
        })
    }
}

extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch QuizFeature(rawValue: indexPath.row) {
        case .map:
            let vc = MapViewController()
            navigationController?.pushViewController(vc, animated: true)
        case .video:
            let vc = VideoViewController()
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MainTableViewCell") as! MainTableViewCell
        cell.titleLabel.text = QuizFeature(rawValue: indexPath.row).title()
        return cell
    }
}

class MainTableViewCell: UITableViewCell {
    @IBOutlet fileprivate weak var titleLabel: UILabel!
}

