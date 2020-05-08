//
//  JKObservableExtension.swift
//  QuanyiPharmacyStore
//
//  Created by Jekin on 4/21/20.
//  Copyright © 2020 zjChilink. All rights reserved.
//

import UIKit
import RxSwift
import RealmSwift

public struct JKRealmChangeset {
    /// the indexes in the collection that were deleted
    public let deleted: [Int]

    /// the indexes in the collection that were inserted
    public let inserted: [Int]

    /// the indexes in the collection that were modified
    public let updated: [Int]
}
//集合信号相关监听
public extension ObservableType where Element: JKNotificationEmitter {
    /// 返回一个' Observable<Element> '，它在每次收集数据发生变化时发出数据。被观察对象在订阅时发出初始值。
    /// - Parameters:
    ///   - collection: 对应集合类型实体
    ///   - synchronousStart: 是否创建就发生一个元素,默认是
    /// - Returns: 该信号
    static func collection(from collection: Element, synchronousStart: Bool = true)
        -> Observable<Element> {
            return Observable.create { observer in
                if synchronousStart {
                    observer.onNext(collection)
                }
                let token = collection.observe { changeset in
                    let value: Element
                    switch changeset {
                    case let .initial(latestValue):
                        guard !synchronousStart else { return }
                        value = latestValue
                    case .update(let latestValue, _, _, _):
                        value = latestValue                        
                    case let .error(error):
                        observer.onError(error)
                        return
                    }
                    observer.onNext(value)
                }
                return Disposables.create {
                    token.invalidate()
                }
            }
    }
    
    /// 返回一个`Observable <Array <Element.ElementType >>`，该值在每次更改集合数据时发出。 观察者在订阅时发出初始值。
    /// - Parameters:
    ///   - collection: 对应协议集合
    ///   - synchronousStart: 产生的Observable是否应同步发出其第一个元素（例如，对于UI绑定更好）
    /// - Returns: 一个包含源集合中所有对象的数组
    static func array(from collection: Element, synchronousStart: Bool = true)
        -> Observable<[Element.ElementType]> {
            return Observable.collection(from: collection, synchronousStart: synchronousStart)
                .map { $0.toArray() }
    }
    
    /// 集合中对象修改
    /// - Parameters:
    ///   - collection: 对应集合类型实体
    ///   - synchronousStart: 是否创建就发生一个元素,默认是
    /// - Returns: Observable<(AnyRealmCollection<E.ElementType>, JKRealmChangeset?)>
    static func changeset(from collection: Element, synchronousStart: Bool = true)
          -> Observable<(AnyRealmCollection<Element.ElementType>, JKRealmChangeset?)> {
              return Observable.create { observer in
                  if synchronousStart {
                      observer.onNext((collection.toAnyCollection(), nil))
                  }
                  let token = collection.toAnyCollection().observe { changeset in
                      switch changeset {
                      case let .initial(value):
                          guard !synchronousStart else { return }
                          observer.onNext((value, nil))
                      case let .update(value, deletes, inserts, updates):
                          observer.onNext((value, JKRealmChangeset(deleted: deletes, inserted: inserts, updated: updates)))
                      case let .error(error):
                          observer.onError(error)
                          return
                      }
                  }
                  return Disposables.create {
                      token.invalidate()
                  }
              }
      }
    static func arrayWithChangeset(from collection: Element, synchronousStart: Bool = true)
        -> Observable<([Element.ElementType], JKRealmChangeset?)> {
            return Observable.changeset(from: collection)
                .map { ($0.toArray(), $1) }
    }
}
//具体Object 的监听
public extension Observable where Element: Object {
    
    /// 返回一个 Observable<Object> 信号，它在对象每次改变时发出。被观察对象在订阅时发出初始值。
    /// - Parameters:
    ///   - object: 该泛型对象
    ///   - synchronousStart: 产生信号的同时是否发出第一个元素
    ///   - properties: 哪些属性将触发发出.next事件
    /// - Returns: 信号
    static func from(object: Element, synchronousStart: Bool = true,
                     properties: [String]? = nil) -> Observable<Element> {
        return Observable<Element>.create { observer in
            if synchronousStart {
                observer.onNext(object)
            }
            let token = object.observe { change in
                switch change {
                case let .change(changedProperties):
                    if let properties = properties, !changedProperties.contains(where: { return properties.contains($0.name) }) {
                        //不存在需要处理的属性
                        return
                    }
                    observer.onNext(object)
                case .deleted:
                    observer.onError(JKRealmError.objectDeleted)
                case let .error(error):
                    observer.onError(error)
                }
            }
            return Disposables.create {
                token.invalidate()
            }
        }
    }
    /// 属性修改信号
    /// - Parameter object: 对应对象
    /// - Returns: 返回对应修改属性
    static func propertyChanges(object: Element) -> Observable<PropertyChange> {
        return Observable<PropertyChange>.create { observer in
            let token = object.observe { change in
                switch change {
                case let .change(changes):
                    for change in changes {
                        observer.onNext(change)
                    }
                case .deleted:
                    observer.onError(JKRealmError.objectDeleted)
                case let .error(error):
                    observer.onError(error)
                }
            }
            return Disposables.create {
                token.invalidate()
            }
        }
    }
}
public extension Observable {
    /// 整个数据库变化
    /// - Parameter realm: 对应数据库
    /// - Returns: 数据库变化信号
    static func from(realm: Realm) -> Observable<(Realm, Realm.Notification)> {
        return Observable<(Realm, Realm.Notification)>.create { observer in
            let token = realm.observe { (notification: Realm.Notification, realm: Realm) in
                observer.onNext((realm, notification))
            }
            return Disposables.create {
                token.invalidate()
            }
        }
    }
}
