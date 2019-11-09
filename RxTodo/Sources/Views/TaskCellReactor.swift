//
//  TaskCellReactor.swift
//  RxTodo
//
//  Created by Suyeol Jeon on 7/1/16.
//  Copyright © 2016 Suyeol Jeon. All rights reserved.
//

import ReactorKit
import RxCocoa
import RxSwift

class TaskCellReactor: Reactor {
//    typealias Action = NoAction
    
    enum Action {
        case update(isDone: Bool)
    }
       
   enum Mutation {
       case update(isDone: Bool)
   }
    
    let initialState: Task
    
    init(task: Task) {
        self.initialState = task
    }
    
    func mutate(action: TaskCellReactor.Action) -> Observable<TaskCellReactor.Mutation> {
        switch action {
        case let .update(isDone: isDone):
            return .just(.update(isDone: isDone))
        }
    }
    
    func reduce(state: Task, mutation: TaskCellReactor.Mutation) -> Task {
//        switch mutation {
//        case let .update(isDone: isDone):
//            state.isDone = isDone
//        }
//        
        debugPrint("isDone:\(state.isDone)")
        return state
    }
}
