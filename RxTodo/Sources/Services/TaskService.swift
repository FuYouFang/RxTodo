//
//  TaskService.swift
//  RxTodo
//
//  Created by Suyeol Jeon on 12/01/2017.
//  Copyright © 2017 Suyeol Jeon. All rights reserved.
//

import RxSwift

enum TaskEvent {
    case create(Task)
    case update(Task)
    case delete(id: String)
    case move(id: String, to: Int)
    case markAsDone(id: String)
    case markAsUndone(id: String)
}

protocol TaskServiceType {
    var event: PublishSubject<TaskEvent> { get }
    func fetchTasks() -> Observable<[Task]>
    
    @discardableResult
    func saveTasks(_ tasks: [Task]) -> Observable<Void>
    
    // memo 备忘录
    func create(title: String, memo: String?) -> Observable<Task>
    func update(taskID: String, title: String, memo: String?) -> Observable<Task>
    func delete(taskID: String) -> Observable<Task>
    func move(taskID: String, to: Int) -> Observable<Task>
    func markAsDone(taskID: String) -> Observable<Task>
    func markAsUndone(taskID: String) -> Observable<Task>
}

final class TaskService: BaseService, TaskServiceType {
    
    let event = PublishSubject<TaskEvent>()
    private lazy var tasks: [Task] = {
        if let savedTaskDictionaries = self.provider.userDefaultsService.value(forKey: .tasks) {
            let tasks = savedTaskDictionaries.compactMap(Task.init)
            return tasks
        }
        let defaultTasks: [Task] = [
            Task(title: "Go to https://github.com/devxoul"),
            Task(title: "Star repositories I am intersted in"),
            Task(title: "Make a pull request"),
        ]
        let defaultTaskDictionaries = defaultTasks.map { $0.asDictionary() }
        self.provider.userDefaultsService.set(value: defaultTaskDictionaries, forKey: .tasks)
        return defaultTasks
    }()
    
    // 返回只有一个数据的时候，使用 Observable.just()
    func fetchTasks() -> Observable<[Task]> {
        return .just(tasks)
    }
    
    @discardableResult
    func saveTasks(_ tasks: [Task]) -> Observable<Void> {
        let dicts = tasks.map { $0.asDictionary() }
        self.provider.userDefaultsService.set(value: dicts, forKey: .tasks)
        return .just(Void())
    }
    
    func create(title: String, memo: String?) -> Observable<Task> {
        return self.fetchTasks()
            .flatMap { [weak self] tasks -> Observable<Task> in
                // https://juejin.im/post/5ba8cbeae51d450e877f5a4d
                // 可以直接用 self 做变量了
                guard let self = self else {
                    return .empty()
                }

                let newTask = Task(title: title, memo: memo)
                // 通过加法，直接把两个数组进行了组合
                // 因为 tasks 是只读的，通过加法组合 两个数组，代码很简洁
                return self.saveTasks(tasks + [newTask]).map { newTask }
            }
            .do(onNext: { task in
                self.event.onNext(.create(task))
            })
    }
    
    func update(taskID: String, title: String, memo: String?) -> Observable<Task> {
        return self.fetchTasks()
            .flatMap { [weak self] tasks -> Observable<Task> in
                guard let `self` = self else { return .empty() }
                guard let index = tasks.index(where: { $0.id == taskID }) else { return .empty() }
                var tasks = tasks
                let newTask = tasks[index].with {
                    $0.title = title
                    $0.memo = memo
                }
                tasks[index] = newTask
                return self.saveTasks(tasks).map { newTask }
            }
            .do(onNext: { task in
                // 注册新回调
                self.event.onNext(.update(task))
            })
    }
    
    
    func delete(taskID: String) -> Observable<Task> {
        return self.fetchTasks()
            .flatMap { [weak self] tasks -> Observable<Task> in
                guard let `self` = self else { return .empty() }
                guard let index = tasks.index(where: { $0.id == taskID }) else {
                    return .empty()
                    
                }
                var tasks = tasks
                let deletedTask = tasks.remove(at: index)
                // 将一个调用，转换为一个异步的队列
                return self.saveTasks(tasks).map { deletedTask }
            }
            .do(onNext: { task in
                self.event.onNext(.delete(id: task.id))
            })
    }
    
    func move(taskID: String, to destinationIndex: Int) -> Observable<Task> {
        return self.fetchTasks()
            .flatMap { [weak self] tasks -> Observable<Task> in
                guard let `self` = self else { return .empty() }
                guard let sourceIndex = tasks.index(where: { $0.id == taskID }) else { return .empty() }
                var tasks = tasks
                let task = tasks.remove(at: sourceIndex)
                tasks.insert(task, at: destinationIndex)
                return self.saveTasks(tasks).map { task }
            }
            .do(onNext: { task in
                self.event.onNext(.move(id: task.id, to: destinationIndex))
            })
    }
    
    func markAsDone(taskID: String) -> Observable<Task> {
        return self.fetchTasks()
            .flatMap { [weak self] tasks -> Observable<Task> in
                guard let self = self else { return .empty() }
                guard let index = tasks.index(where: { $0.id == taskID }) else { return .empty() }
                let task = tasks[index].then {
                    $0.isDone = true
                }
                return self.saveTasks(tasks).map { task }
            }
            .do(onNext: { task in
                self.event.onNext(.markAsDone(id: task.id))
            })
    }
    
    func markAsUndone(taskID: String) -> Observable<Task> {
        return self.fetchTasks()
            .flatMap { [weak self] tasks -> Observable<Task> in
                guard let `self` = self else { return .empty() }
                guard let index = tasks.index(where: { $0.id == taskID }) else { return .empty() }
                
                let task = tasks[index].then {
                    $0.isDone = false
                }
                return self.saveTasks(tasks).map { task }
            }
            .do(onNext: { task in
                self.event.onNext(.markAsUndone(id: task.id))
            })
    }
    
    
}
