//
//  InputViewController.swift
//  taskapp
//
//  Created by 白土顕一 on 2021/05/01.
//

import UIKit
import RealmSwift
import UserNotifications



class InputViewController: UIViewController {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var contentsTextView: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var categoryTextField: UITextField!
    
    
    
    let realm = try! Realm()
    var task: Task!
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 背景をタップしたら dismissKeyboard メソッドを呼ぶように設定する
        let tapGesture : UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        
        titleTextField.text = task.title
        contentsTextView.text = task.contents
        datePicker.date = task.date
        categoryTextField.text = task.category

        // Do any additional setup after loading the view.
    }
    
    
    // タスク一覧画面へ戻るときにUIに入力された値をデータベースに保存する
    override func viewWillDisappear(_ animated: Bool) {
        try! realm.write {
            self.task.title = self.titleTextField.text!
            self.task.contents = self.contentsTextView.text
            self.task.date = self.datePicker.date
            self.task.category = self.categoryTextField.text!
            self.realm.add(self.task, update: .modified)
        }
        
        setNotification(task: task)
        super.viewWillDisappear(animated)
    }
    
    
    
    // タスクのローカル通知を登録する
    func setNotification(task: Task) {
        let content = UNMutableNotificationContent()
        // タイトルと内容を設定（中身がない場合メッセージ無しで音だけの通知になるので「(xxなし)」を表示する）
        if task.title == "" {
            content.title = "(タイトルなし)"
        } else {
            content.title = task.title
        }

        if task.contents == "" {
            content.body = "(内容なし)"
        } else {
            content.body = task.contents
        }

        content.sound = UNNotificationSound.default
        
        // ローカル通知が発動するtrigger (日付マッチ) を作成
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: task.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        // identifier , content , trigger からローカル通知を作成（identifier が同じだとローカル通知を上書き保存）
        let request = UNNotificationRequest(identifier: String(task.id), content: content, trigger: trigger)
        
        // ローカル通知を登録
        let center = UNUserNotificationCenter.current()
        center.add(request) { (error) in
            // error が nil ならローカル通知の登録に成功したと表示します。
            // error が存在すれば error を表示します。
            print(error ?? "ローカル通知登録 OK")
        }
        
        // 未通知のローカル通知一覧をログ出力
        center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in for request in requests {
                print("/---------------")
                print(request)
                print("---------------/")
            }
        }
        
        
        
    }
    
    
    
    
    
    
    
    
    
    @objc func dismissKeyboard(){
        // キーボードを閉じる
        view.endEditing(true)
    }
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
