//
//  JKRealmElementExtension.swift
//  QuanyiPharmacyStore
//
//  Created by Jekin on 4/21/20.
//  Copyright © 2020 zjChilink. All rights reserved.
//

import UIKit
import RxSwift
import RealmSwift

public protocol JKNotificationEmitter {
    associatedtype ElementType: RealmCollectionValue
    //启用当前集合的更改通知
    func observe(_ block: @escaping (RealmCollectionChange<Self>) -> Void) -> NotificationToken
    //转换为容易使用序列
    func toArray() -> [ElementType]
    //转realm集合
    func toAnyCollection() -> AnyRealmCollection<ElementType>
}

extension List: JKNotificationEmitter {
    public func toArray() -> [Element] {
        return Array(self)
    }
    public func toAnyCollection() -> AnyRealmCollection<Element> {
        return AnyRealmCollection<Element>(self)
    }
}

extension AnyRealmCollection: JKNotificationEmitter {
    public typealias ElementType = Element
    public func toAnyCollection() -> AnyRealmCollection<Element> {
        return AnyRealmCollection<ElementType>(self)
    }
    public func toArray() -> [ElementType] {
        return Array(self)
    }
}

extension Results: JKNotificationEmitter {
    public typealias ElementType = Element
    public func toAnyCollection() -> AnyRealmCollection<Element> {
        return AnyRealmCollection<ElementType>(self)
    }
    public func toArray() -> [ElementType] {
        return Array(self)
    }
}

extension LinkingObjects: JKNotificationEmitter {
    public typealias ElementType = Element
    public func toAnyCollection() -> AnyRealmCollection<Element> {
        return AnyRealmCollection<ElementType>(self)
    }
    public func toArray() -> [ElementType] {
        return Array(self)
    }
}
