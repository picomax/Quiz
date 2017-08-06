//
//  ModelProtocol.swift
//  Quiz
//
//  Created by picomax on 06/08/2017.
//  Copyright © 2017 picomax. All rights reserved.
//

import Foundation

protocol ModelProtocol {
    static var path: String { get }
    var key: String { get }
    var rawValue: [AnyHashable: Any] { get }
    
    func update()
    
    associatedtype Model
    static func fetch(callback: @escaping (_ result: [Model]) -> Void)
}

