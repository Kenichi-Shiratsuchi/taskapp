//
//  ViewController.swift
//  taskapp
//
//  Created by 白土顕一 on 2021/05/01.
//

import UIKit
import RealmSwift   // 追加
import UserNotifications    // 追加

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    
    // Realmインスタンスを取得する
    let realm = try! Realm()    // 追加
    
    // DB内のタスクが格納されるリスト
    // 日付の近い順でソート:昇順
    // 以降内容をアップデートするとリスト内は自動的に更新される
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date",ascending: true) // 追加
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self   // Search Bar のデリゲートを追加
        
        // searchBar.showsCancelButton = true
        // searchBar.enablesReturnKeyAutomatically = false
        
    }

    // データの数（＝セルの数）を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskArray.count // 修正する
    }
    
    
    // 各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // 再利用可能なcellを得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
    
    
        // Cellに値を設定する。
        let task = taskArray[indexPath.row]
        cell.textLabel?.text = task.title
    
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
    
        let dateString:String = formatter.string(from: task.date)
        cell.detailTextLabel?.text = dateString
    
        return cell
    }

    
    
    // 各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellSegue",sender: nil)
    }
    
    // セルが削除可能なことを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    // Deleteボタンが押された時に呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        // --- ここから ---
        if editingStyle == .delete {
            // 削除するタスクを取得する
            let task = self.taskArray[indexPath.row]
        
            // ローカル通知をキャンセルする
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])
        
            // データベースから削除する
            try! realm.write {
                self.realm.delete(task)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        
            // 未通知のローカル通知一覧をログ出力
            center.getPendingNotificationRequests { (requests:[UNNotificationRequest]) in for request in requests {
                    print("/---------------")
                    print(request)
                    print("---------------/")
                }
            }
        }
    }
    
    
    // segueで画面遷移する時に呼ばれる
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let inputViewController:InputViewController = segue.destination as! InputViewController
        
        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = taskArray[indexPath!.row]
        } else {
            let task = Task()
            
            let allTasks = realm.objects(Task.self)
            if allTasks.count != 0 {
                task.id = allTasks.max(ofProperty: "id")! + 1
            }
            
            inputViewController.task = task
        }
    }
    
    
    // 入力画面から戻ってきたときに TableView を更新する
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    // カテゴリの検索開始
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // searchBar.endEditing(true)
        
        // searchTextがnilの時はここで終了
        guard let searchText = searchBar.text else {
            return
        }
        
        // 検索条件(プロパティ名=値)に合うタスクをresultに出力する
        let result = realm.objects(Task.self).filter("category == '\(searchText)'")
        // Memo : filter("category BEGINSWITH '\(searchText)'")     前方一致検索
        // Memo : filter("category ENDSWITH '\(searchText)'")       後方一致検索
        // Memo : filter("category CONTAINS '\(searchText)'")       部分一致検索
        
        
        // Memo : 検索対象が無い場合に全てのタスクを表示したい場合は下記のコードを有効にする
        //categoryの検索結果数
        //let count = result.count
        //if (count == 0) {
        //    taskArray = realm.objects(Task.self)    // 検索対象が無い場合は全てのタスクを表示
        //} else {
        //    taskArray = result                      // 条件に合ったタスクを表示
        //}
        
        // 検索結果のタスクをタスクリストに格納
        taskArray = result
        
        // TableViewの更新
        tableView.reloadData()
    }
    
    // キャンセルボタンを押した時は全タスクを表示します
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        taskArray = realm.objects(Task.self)
        tableView.reloadData()
    }

    
}

