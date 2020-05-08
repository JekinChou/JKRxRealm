//
//  JKRealmTool.swift
//  JKRxRealm
//
//  Created by Jekin on 4/22/20.
//

import UIKit
import RxSwift
import RealmSwift
public class JKRealmTool {
    private(set) static var realm: Realm =  try! Realm(configuration: Realm.Configuration.defaultConfiguration)
    
    /// 配置数据库,最好在appdelegate配置
    /// - Parameters:
    ///   - configration: realm相关配置
    ///   - migrationCallBack: 迁移回调,配置版本比之前版本高时才会发生回调
    /// - Returns: 数据库
    @discardableResult
    public class func configRealm(configration: Realm.Configuration? = nil, migrationCallBack:(()->())? = nil) -> Realm {
        guard let con = configration  else {
            return JKRealmTool.realm
        }
        let dbName: String = "defalut"
        let dbVersion : UInt64 = configration?.schemaVersion ?? 0
        let docPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] as String
        var dbPath = docPath + "/" + dbName + ".realm"
        if let path = con.fileURL?.absoluteString {
            dbPath = path
        }
        let config = Realm.Configuration(fileURL: URL.init(string: dbPath), inMemoryIdentifier: nil, syncConfiguration: nil, encryptionKey: nil, readOnly: false, schemaVersion: dbVersion, migrationBlock: { (migration, oldSchemaVersion) in
            if oldSchemaVersion < dbVersion { //当前版本旧
                migrationCallBack?()
            }
        }, deleteRealmIfMigrationNeeded: false, shouldCompactOnLaunch: nil, objectTypes: nil)
        if let c = configration {
            Realm.Configuration.defaultConfiguration = c
        } else {
            Realm.Configuration.defaultConfiguration = config
        }
        let db = try! Realm()
        JKRealmTool.realm = db
        // 获取 Realm 文件的父目录
        let folderPath = db.configuration.fileURL!.deletingLastPathComponent().path
        // 禁用此目录的文件保护
        try! FileManager.default.setAttributes([FileAttributeKey(rawValue: FileAttributeKey.protectionKey.rawValue): FileProtectionType.none],
                                               ofItemAtPath: folderPath)
        return db
    }
    public class func add<O>(object: O) -> Disposable where O: Object {
       return Observable.just(object).subscribe(JKRealmTool.rx.add(realm: JKRealmTool.realm, update: Realm.UpdatePolicy.error, onError: nil))
        
    }
    public class func add<S: Sequence>(seq: S) -> Disposable where S.Iterator.Element: Object {
       return Observable.just(seq).subscribe(JKRealmTool.rx.add(realm: JKRealmTool.realm, update: Realm.UpdatePolicy.error, onError: nil))
    }
    
   public class func delete<S: Sequence>(seq: S) -> Disposable where S.Iterator.Element: Object {
        return Observable.just(seq).subscribe(JKRealmTool.rx.delete())
    }
  public  class func delete<O: Object>(object: O)-> Disposable {
        return Observable.just(object).subscribe(JKRealmTool.rx.delete())
    }
    
   public class func delete<T>(list: T.Type)-> Disposable where T: Object {
        return Observable.just(list).subscribe(JKRealmTool.rx.delete(realm: JKRealmTool.realm, type: list))
    }
    
   public class func queryObject<R>(object: R.Type, where: String?) -> Results<R>? where R: Object {
        var result = JKRealmTool.realm.objects(object)
            if let filter = `where` {
                result = result.filter(filter)
            }
            return result
    }
    
}
extension JKRealmTool: ReactiveCompatible {}
//对应行为的观察者
public extension Reactive where Base == JKRealmTool {
    
    /// 添加集合
    /// - Parameters:
    ///   - realm: 对应数据库
    ///   - update: 数据更新策略
    ///   - onError: 错误回调
    /// - Returns: 对应观察者
    static func add<S: Sequence>(realm: Realm,
                                 update: Realm.UpdatePolicy = .error,
                                 onError:((_ sequ: S?, _ err: Error)->Void)? = nil )
        -> AnyObserver<S> where S.Iterator.Element: Object {
            return JKRealmRxObserver(realm: realm) { (r: Realm?, elements, error: Error?) in
                guard let db = r else {
                    onError?(nil, error ?? JKRealmError.unknown)
                    return
                }
                do {
                    try db.write {
                        db.add(elements, update: update)
                    }
                } catch let e {
                    onError?(elements, e)
                }
            }.asObserver()
    }
    
    /// 添加具体对象的观察者
    /// - Parameters:
    ///   - realm: 对应数据库
    ///   - update: 数据更新策略
    ///   - onError: 错误回调
    /// - Returns: 对应观察者
    static func add<O: Object>(realm: Realm,
                               update: Realm.UpdatePolicy = .error,
                               onError: ((_ elem: O?, _ err: Error) -> Void)? = nil) -> AnyObserver<O> {
        return JKRealmRxObserver(realm: realm) { (r: Realm?, element, error: Error?) in
            guard let db = r else {
                onError?(nil, error ?? JKRealmError.unknown)
                return
            }
            do {
                try db.write {
                    db.add(element, update: update)
                }
            } catch let e {
                onError?(element, e)
            }
        }.asObserver()
    }
    
    /// 删除对应对象的观察者
    /// - Parameters:
    ///   - realm: 数据库
    ///   - onError: 错误回调
    /// - Returns: 观察者
    static  func delete<O: Object>(onError: ((_ elem: O?, _ err: Error) -> Void)? = nil)-> AnyObserver<O> {
        return AnyObserver { (event) in
            guard  let element = event.element, let r = element.realm else {
                onError?(nil, JKRealmError.unknown)
                return
            }
            do {
                try r.write {
                    r.delete(element)
                }
            } catch let e {
                onError?(element, e)
            }
        }
    }
    //删除对应集合的观察者
    static func delete<S: Sequence>(onError: ((S?, Error) -> Void)? = nil)
        -> AnyObserver<S> where S.Iterator.Element: Object {
            return AnyObserver { event in
                guard let elements = event.element,
                    var generator = elements.makeIterator() as S.Iterator?,
                    let first = generator.next(),
                    let realm = first.realm else {
                        onError?(nil, JKRealmError.unknown)
                        return
                }
                do {
                    try realm.write {
                        realm.delete(elements)
                    }
                } catch let e {
                    onError?(elements, e)
                }
            }
    }
    
    /// 删除该类型的表
    /// - Parameters:
    ///   - type: 对应Object类型
    ///   - onError: 错误
    /// - Returns: 返回对应观察者
    static func delete<T>(realm: Realm, type: T.Type, onError: ((T.Type?, Error) -> Void)? = nil)-> AnyObserver<T.Type> where T : Object{
        return AnyObserver { event in
            let result = realm.objects(type)
            if result.count == 0 {
                onError?(nil, JKRealmError.unknown)
                return
            }
            do {
                try realm.write {
                    realm.delete(result)
                }
            } catch let e {
                onError?(type, e)
            }
        }
    }
}
