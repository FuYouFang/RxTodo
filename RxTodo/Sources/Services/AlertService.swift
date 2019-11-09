//
//  AlertService.swift
//  RxTodo
//
//  Created by Suyeol Jeon on 29/03/2017.
//  Copyright © 2017 Suyeol Jeon. All rights reserved.
//

import UIKit
import RxSwift
import URLNavigator

protocol AlertActionType {
    var title: String? { get }
    var style: UIAlertAction.Style { get }
}

extension AlertActionType {
    var style: UIAlertAction.Style {
        return .default
    }
}

protocol AlertServiceType: class {
    func show<Action: AlertActionType>(
        title: String?,
        message: String?,
        preferredStyle: UIAlertController.Style,
        actions: [Action]
    ) -> Observable<Action>
}

// 所有的 BaseService 都拥有 总的 service
final class AlertService: BaseService, AlertServiceType {
    
    // 每个方法的返回值都是 Observable
    func show<Action: AlertActionType>(
        title: String?,
        message: String?,
        preferredStyle: UIAlertController.Style,
        actions: [Action]
    ) -> Observable<Action> {
        return Observable.create { observer in
            let alert = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)
            for action in actions {
                let alertAction = UIAlertAction(title: action.title, style: action.style) { _ in
                    
                    observer.onNext(action)
                    observer.onCompleted()
                }
                alert.addAction(alertAction)
            }

            // 仅仅用到 Navigator 获取最顶层 view controller 的方法
            Navigator().present(alert)
            //
            return Disposables.create {
                alert.dismiss(animated: true, completion: nil)
            }
        }
    }
    
}
