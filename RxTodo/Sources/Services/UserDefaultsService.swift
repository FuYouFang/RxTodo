//
//  UserDefaultsService.swift
//  RxTodo
//
//  Created by Suyeol Jeon on 12/01/2017.
//  Copyright © 2017 Suyeol Jeon. All rights reserved.
//

import Foundation

extension UserDefaultsKey {
    // 一个固定的 Key
    static var tasks: Key<[[String: Any]]> {
        // 用到了用一个字符串，初始化一个 Key
        return "tasks"
    }
}

protocol UserDefaultsServiceType {
    // 通过给 UserDefaultsKey 添加一个 类型，让一个 String 类型的 key，和一个特定的类型的 value 绑定在一起
    func value<T>(forKey key: UserDefaultsKey<T>) -> T?
    func set<T>(value: T?, forKey key: UserDefaultsKey<T>)
}

final class UserDefaultsService: BaseService, UserDefaultsServiceType {
    
    private var defaults: UserDefaults {
        return UserDefaults.standard
    }
    
    func value<T>(forKey key: UserDefaultsKey<T>) -> T? {
        return self.defaults.value(forKey: key.key) as? T
    }
    
    func set<T>(value: T?, forKey key: UserDefaultsKey<T>) {
        self.defaults.set(value, forKey: key.key)
        self.defaults.synchronize()
    }
    
}
