//
//  ViewController.swift
//  task
//
//  Created by Macbook on 6/5/21.
//

import UIKit
import Combine
import MultipeerConnectivity
@available(iOS 13.0, *)
class ViewController: UIViewController {
    
    
    
    @IBOutlet weak var downloadImageView1: UIImageView!
    @IBOutlet weak var downloadImageView2: UIImageView!
    @IBOutlet weak var downloadImageView3: UIImageView!
    @IBOutlet weak var buttonView: UIButton!
    @IBOutlet weak var uploadImageView1: UIImageView!
    @IBOutlet weak var uploadImageView2: UIImageView!
    @IBOutlet weak var uploadImageView3: UIImageView!
    @IBOutlet weak var progressLabelView1: UILabel!
    @IBOutlet weak var progressLabelView2: UILabel!
    @IBOutlet weak var progressLabelView3: UILabel!
    @IBOutlet weak var snedImagesButtonView: UIButton!
    
    @IBOutlet weak var centerView: UIView!
    
    
    var imageViews : [UIImageView]!
    var uplaodImageViews : [UIImageView]!
    var progressViews : [UILabel]!
    var taskCompleteSubscriber : AnyCancellable?
    var taskProgressSubscriber : AnyCancellable?
    var reciveImageSubscriber : AnyCancellable?
    var taskViewModel = TaskViewModel()
    var isAllDownloaded : [Bool] = []{
        
        
        
        didSet{
            
            // checking that all images are downloaded or not , we can alos do this by dispatch group and observe when all done
            // I am putting the static value which is 3 but can also be done by dynamically aswell
            
            if isAllDownloaded.count == 3 {
                
                buttonView.isHidden = true
                centerView.isHidden = false
                
                print("tasks done")
            }
            
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setValues()
        observeCompleteTask()
        observeProgressTask()
        observeRecieveImage()
        imageViews = [downloadImageView1,downloadImageView2,downloadImageView3]
        progressViews = [progressLabelView1,progressLabelView2,progressLabelView3]
        uplaodImageViews = [uploadImageView1,uploadImageView2,uploadImageView3]
        // Do any additional setup after loading the view.
    }
    
    func observeCompleteTask(){
        taskCompleteSubscriber = taskViewModel.taskCompleteSubject.sink(receiveCompletion: { (resultCompletion) in
            switch resultCompletion {
            case .failure(let error):
                print(error.localizedDescription)
            default: break
            }
        }) { (downloadTasks) in
            
            DispatchQueue.main.async {
                print("called")
                
                
                if let array = self.taskViewModel.taskArray {
                    
                    for i in 0..<self.taskViewModel.taskArray.count{
                        
                        if(self.taskViewModel.taskArray[i].downloadTaskId == downloadTasks.downloadTaskId){
                            
                            self.isAllDownloaded.append(true)
                            if let data = downloadTasks.downloadedData {
                                self.imageViews[i].image = UIImage(data: data as Data)
                            }
                            
                            
                        }
                    }
                }
                
                
            }
            
        }
    }
    
    func setValues(){
        centerView.isHidden = true
        buttonView.isHidden = false
        self.taskViewModel.resetTaskArray()
        isAllDownloaded = []
    }
    
    func observeProgressTask(){
        if #available(iOS 13.0, *) {
            taskProgressSubscriber = taskViewModel.taskProgressSubject.sink(receiveCompletion: { (resultCompletion) in
                switch resultCompletion {
                case .failure(let error):
                    print(error.localizedDescription)
                default: break
                }
            }) { (progressTasks) in
                
                DispatchQueue.main.async {
                    print("called")
                    
                    if let array = self.taskViewModel.taskArray {
                        for i in 0..<array.count{
                            
                            if(self.taskViewModel.taskArray[i].downloadTaskId == progressTasks.downloadTaskId){
                                self.progressViews[i].text = String(progressTasks.progress)
                            }
                        }
                    }
                    
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    func observeRecieveImage(){
        if #available(iOS 13.0, *) {
            reciveImageSubscriber = taskViewModel.transferImageSubject.sink(receiveCompletion: { (resultCompletion) in
                switch resultCompletion {
                case .failure(let error):
                    print(error.localizedDescription)
                default: break
                }
            }) { (resultImage) in
                
                DispatchQueue.main.async {
                    
                    for i in 0..<self.uplaodImageViews.count {
                        
                        if(self.uplaodImageViews[i].image == nil)
                        {
                            self.uplaodImageViews[i].image = resultImage
                            break
                        }
                        
                    }
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    
    @IBAction func connectPeerButtonAction(_ sender: Any) {
        showConnectionMenu()
    }
    
    @IBAction func snedImagesButtonAction(_ sender: Any) {
        
        imageViews.forEach { imageView in
            if let image = imageView.image {
                taskViewModel.sendImage(img: image)
            }
        }
        
    }
    
    @objc func showConnectionMenu() {
        let ac = UIAlertController(title: "Connection Menu", message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Host a session", style: .default, handler: taskViewModel.hostSession))
        ac.addAction(UIAlertAction(title: "Join a session", style: .default, handler: taskViewModel.joinSession))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    func cancel(action: UIAlertAction){
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func downloadButtonClickAction(_ sender: Any) {
        
        setValues()
        self.taskViewModel.downloadAll()
    }
    
    
    
}






