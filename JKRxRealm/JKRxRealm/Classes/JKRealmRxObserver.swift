//
//  JKRealmRx.swift
//  QuanyiPharmacyStore
//
//  Created by Jekin on 4/21/20.
//  Copyright © 2020 zjChilink. All rights reserved.
//

import UIKit
import RxSwift
import RealmSwift
import Foundation
//数据库监听返回的错误
public enum JKRealmError: Error {
    case objectDeleted
    case unknown
}
//数据库的观察者
public class JKRealmRxObserver<Element>: ObserverType {
    private(set) public var realm: Realm?
    private(set) public var configuration: Realm.Configuration = Realm.Configuration.defaultConfiguration
    private let binding: (Realm?, Element, Error?) -> Void
    
    public init(realm: Realm, binding: @escaping (Realm?,Element, Error?) -> Void) {
        self.realm = realm
        self.binding = binding
    }
    
    init(configuration: Realm.Configuration, binding: @escaping (Realm?, Element, Error?) -> Void) {
        self.configuration = configuration
        self.binding = binding
    }
    deinit {
        realm = nil
    }
    public func on(_ event: Event<Element>) {
        switch event {
            //将会缓存realm 直到完成以及出错
        case let .next(element):
            if  realm == nil {
                do {
                    let realm = try Realm(configuration: configuration)
                    binding(realm, element, nil)
                } catch let e {
                    binding(nil, element, e)
                }
                return
            }
            guard let realm = realm else {
                fatalError("realm 不能为空")
            }
            binding(realm, element, nil)
        case .error:
            realm = nil
        case .completed:
            realm = nil
        }
    }
    public  func asObserver() -> AnyObserver<Element> {
        return AnyObserver(eventHandler: on)
    }
}






