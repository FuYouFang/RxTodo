//
//  TaskListViewController.swift
//  RxTodo
//
//  Created by Suyeol Jeon on 7/1/16.
//  Copyright © 2016 Suyeol Jeon. All rights reserved.
//

import UIKit
import ReactorKit
import RxCocoa
import RxDataSources
import RxSwift
import ReusableKit

final class TaskListViewController: BaseViewController, View {
    
    // MARK: Constants
    
    struct Reusable {
        static let taskCell = ReusableCell<TaskCell>()
    }
    
    
    // MARK: Properties
    
    let dataSource = RxTableViewSectionedReloadDataSource<TaskListSection>(
        configureCell: { _, tableView, indexPath, reactor in
            let cell = tableView.dequeue(Reusable.taskCell, for: indexPath)
            debugPrint("indexPath:\(indexPath)")
            cell.reactor = reactor
            return cell
    })
    
    let addButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
    let tableView = UITableView().then {
        // 在编辑状态下允许选择
        $0.allowsSelectionDuringEditing = true
        $0.register(Reusable.taskCell)
    }
    
    
    // MARK: Initializing
    
    init(reactor: TaskListViewReactor) {
        super.init()
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        self.navigationItem.rightBarButtonItem = self.addButtonItem
        self.reactor = reactor
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.view.addSubview(self.tableView)
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        self.tableView.snp.makeConstraints { make in
            make.edges.equalTo(0)
        }
    }
    
    
    // MARK: Binding
    
    func bind(reactor: TaskListViewReactor) {
        // DataSource
        self.tableView.rx.setDelegate(self).disposed(by: self.disposeBag)
        self.dataSource.canEditRowAtIndexPath = { _, _  in true }
        self.dataSource.canMoveRowAtIndexPath = { _, _  in true }
        
        // Action
        self.rx.viewDidLoad
            .map { Reactor.Action.refresh }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.editButtonItem.rx.tap
            .map { Reactor.Action.toggleEditing }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.tableView.rx.itemSelected
            .filterNot(reactor.state.map { $0.isEditing }) // 排除正在编辑的状态
            .map { indexPath in .toggleTaskDone(indexPath) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.tableView.rx.itemDeleted
            .map(Reactor.Action.deleteTask)
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.tableView.rx.itemMoved
            .map(Reactor.Action.moveTask)
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.addButtonItem.rx.tap
            .map(reactor.reactorForCreatingTask)
            .subscribe(onNext: { [weak self] reactor in
                guard let self = self else { return }
                
                let viewController = TaskEditViewController(reactor: reactor)
                let navigationController = UINavigationController(rootViewController: viewController)
                self.present(navigationController, animated: true, completion: nil)
            })
            .disposed(by: self.disposeBag)
        
        // 单元格选中事件响应
        // tableView.rx.itemSelected
        // tableView.rx.modelSelected
        
        // 单元格取消选中事件响应
        // tableView.rx.itemDeselected
        // tableView.rx.modelDeselected
        // Observable.zip(tableView.rx.itemDeselected, tableView.rx.modelDeselected(String.self))
        
        // 单元格删除事件响应
        // tableView.rx.itemDeleted
        // tableView.rx.modelDeleted
        
        // 获取 item 类型的方法
        // let itemType = type(of: self.dataSource).Section.Item.self
        
        self.tableView.rx.modelSelected(type(of: self.dataSource).Section.Item.self)
            .filter(reactor.state.map { $0.isEditing })
            
            .map(reactor.reactorForEditingTask)
            .subscribe(onNext: { [weak self] reactor in
                guard let self = self else { return }
                let viewController = TaskEditViewController(reactor: reactor)
                let navigationController = UINavigationController(rootViewController: viewController)
                self.present(navigationController, animated: true, completion: nil)
            })
            .disposed(by: self.disposeBag)
        
        // State
        reactor.state.asObservable().map { $0.sections }
            .bind(to: self.tableView.rx.items(dataSource: self.dataSource))
            .disposed(by: self.disposeBag)
        
        reactor.state.asObservable().map { $0.isEditing }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] isEditing in
                guard let `self` = self else { return }
                self.navigationItem.leftBarButtonItem?.title = isEditing ? "Done" : "Edit"
                self.navigationItem.leftBarButtonItem?.style = isEditing ? .done : .plain
                self.tableView.setEditing(isEditing, animated: true)
            })
            .disposed(by: self.disposeBag)
    }
    
}


// MARK: - UITableViewDelegate

extension TaskListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let reactor = self.dataSource[indexPath]
        return TaskCell.height(fits: tableView.width, reactor: reactor)
    }
    
    // deselectRow 在回调中设置
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
