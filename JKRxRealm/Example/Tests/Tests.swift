// https://github.com/Quick/Quick


import XCTest
import JKRxRealm
import RealmSwift
class Book: Object {
    @objc dynamic var name = ""
    @objc dynamic var author = ""
    /// LinkingObjects 反向表示该对象的拥有者
    let owners = LinkingObjects(fromType: Student.self, property: "books")
}

class person: Object {
    
}

class Student: Object {
    @objc dynamic var name = ""
    @objc dynamic var age = 18
    @objc dynamic var weight = 156
    @objc dynamic var id = 0
    @objc dynamic var address = ""
    @objc dynamic var birthday : NSDate? = nil
    @objc dynamic var photo : NSData?  = nil
    @objc dynamic var tempID: String? = nil
    //重写 Object.primaryKey() 可以设置模型的主键。
    //声明主键之后，对象将被允许查询，更新速度更加高效，并且要求每个对象保持唯一性。
    //一旦带有主键的对象被添加到 Realm 之后，该对象的主键将不可修改。
//    override static func primaryKey() -> String? {
//        return "id"
//    }
    //重写 Object.ignoredProperties() 可以防止 Realm 存储数据模型的某个属性
    override static func ignoredProperties() -> [String] {
        return ["tempID"]
    }
    //重写 Object.indexedProperties() 方法可以为数据模型中需要添加索引的属性建立索引，Realm 支持为字符串、整型、布尔值以及 Date 属性建立索引。
    //    override static func indexedProperties() -> [String] {
    //        return ["name"]
    //    }
    //List 用来表示一对多的关系：一个 Student 中拥有多个 Book。
    let books = List<Book>()
}
class TableOfContentsSpec: XCTestCase {
    func testAdd() {
        let stu = Student()
        stu.name = "coolBoy_1"
        stu.weight = 151;
        stu.age = 26
//        stu.id = i;
        // 头像
        let birthdayStr = "1993-06-10"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        stu.birthday = dateFormatter.date(from: birthdayStr)! as NSDate
        
        JKRealmTool.add(object: stu)
    }
    
    func testAdds() {
        var stus = [Student]()
        for i in 100...144 {
            let stu = Student()
            stu.name = "极客学伟_\(i)"
            stu.weight = 151;
            stu.age = 26
            stu.id = i;
            // 头像
            let birthdayStr = "1993-06-10"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "YYYY-MM-dd"
            stu.birthday = dateFormatter.date(from: birthdayStr)! as NSDate
            stus.append(stu)
        }
        JKRealmTool.add(seq: stus)
        
    }
    
    func testDelete() {
        JKRealmTool.delete(list: Student.self)
    }
    
    func testQuery() {
        let result = JKRealmTool.queryObject(object: Student.self, where: nil)
        let array = result?.toArray()
        print("array \(array)")
    }
}
