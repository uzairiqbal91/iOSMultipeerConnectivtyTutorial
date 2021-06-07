//
//  TaskViewModel.swift
//  task
//
//  Created by Macbook on 6/5/21.
//

import Foundation
import UIKit
import Combine
import MultipeerConnectivity

// NOTE
// we can alos add service layer for downloading and sending images to peer 
// @available(iOS 13.0, *) this line because I set target ios version 12.2 and combine came from ios 13
// I did this because MultipeerConnectivity not working properly when I set the target abouve version 13
// That is why i did this
// The commit will show as muhammad rizwan because this mac name is muhammad rizwan

@available(iOS 13.0, *)
class TaskViewModel : NSObject , URLSessionDownloadDelegate, MCSessionDelegate, MCBrowserViewControllerDelegate {
    
    
    var taskArray : [Task]!
    var downloadedTaskArray : [Task]!
    var session : URLSession!
    let config = URLSessionConfiguration.background(withIdentifier: "\(Bundle.main.bundleIdentifier!).background")
    var taskCompleteSubject = PassthroughSubject<Task, Error>()
    var taskProgressSubject = PassthroughSubject<Task, Error>()
    var transferImageSubject = PassthroughSubject<UIImage, Error>()
    
    
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    
    override init() {
        super.init()
        session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: self.peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
        
    }
    
    
    deinit {
        self.mcAdvertiserAssistant.stop()
        
        }

    
    func sendImage(img: UIImage) {
        if mcSession.connectedPeers.count > 0 {
            if let imageData = img.pngData() {
                do {
                    try mcSession.send(imageData, toPeers: mcSession.connectedPeers, with: .reliable)
                } catch let error as NSError {
                   print(error.localizedDescription)
                }
            }
        }
    }
    
    func resetTaskArray(){
        self.taskArray = []
        self.downloadedTaskArray = []
    }
    
    
    func startDownloadSingleFile(imageUrl: String, completion: @escaping (Task) -> Void) {
        
        
        let session = self.session
        var downloadInfo : Task = Task()

        let url:URL = URL.init(string: imageUrl)!;
        downloadInfo.downloadTask = session!.downloadTask(with: url)
        downloadInfo.downloadTaskId = downloadInfo.downloadTask?.taskIdentifier;
        downloadInfo.downloadTask!.resume();
        downloadInfo.isDownload = false;
        downloadInfo.downloadedData = nil;
        
        self.taskArray.append(downloadInfo)
        
        completion(downloadInfo)
        
    }
    
    
    func downloadAllImages(_ urls: [String]) {
        
        DispatchQueue.global(qos: .utility).async {
            for url in urls {
               
                // weak self because of memory optimization and make sure that refrence counter should not in memory
                
                self.startDownloadSingleFile(imageUrl: url) { [weak self] task in
                   // can be done when we use Diapatch group and leave dispatch group
                    
                    print("recived image")
                    
                }
                
            }
           
        }
        
    }
    
    func downloadAll(){
        let urlString = [

//            "https://images.unsplash.com/photo-1516918656725-e9b3ae9ee7a4?ixid=MnwxMjA3fDB8MHxzZWFyY2h8MTV8fGhpZ2glMjByZXNvbHV0aW9ufGVufDB8fDB8fA%3D%3D&ixlib=rb-1.2.1",
            "https://cdn.wallpapersafari.com/31/94/0mKkXA.jpeg",
            "https://images.unsplash.com/photo-1516918656725-e9b3ae9ee7a4?ixid=MnwxMjA3fDB8MHxzZWFyY2h8MTV8fGhpZ2glMjByZXNvbHV0aW9ufGVufDB8fDB8fA%3D%3D&ixlib=rb-1.2.1&w=1000&q=80",
            "https://cdn.wallpapersafari.com/0/13/uXFCxY.jpg"

        ]
        
        downloadAllImages(urlString)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let data = try? Data(contentsOf: location) else {
            print("The data could not be loaded")
            
            return
        }
     
        let image = UIImage(data: data)
        var downloadInfo : Task = Task()
        print("downloaded id \(downloadTask.taskIdentifier)")
        downloadInfo.downloadTaskId = downloadTask.taskIdentifier;
        downloadInfo.downloadedData = image?.pngData() as NSData?
        downloadInfo.isDownload = true
        downloadedTaskArray.append(downloadInfo)
        
        // emitting in taskCompleteSubject steam and will observe in view controller
        self.taskCompleteSubject.send(downloadInfo)

        
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = (Float(totalBytesWritten) / Float(totalBytesExpectedToWrite))*100
        var downloadInfo : Task = Task()
        print("downloaded id \(downloadTask.taskIdentifier)")
        downloadInfo.downloadTaskId = downloadTask.taskIdentifier;
        downloadInfo.progress = progress
        
        // emitting in taskProgressSubject steam and will observe in view controller
        self.taskProgressSubject.send(downloadInfo)
        
    }
    
    
    func hostSession(action: UIAlertAction) {
      mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "mytask", discoveryInfo: nil, session: mcSession)
      mcAdvertiserAssistant.start()
    }
    
    func joinSession(action: UIAlertAction) {
      let mcBrowser = MCBrowserViewController(serviceType: "mytask", session: mcSession)
      mcBrowser.delegate = self
        UIApplication.shared.windows.first!.rootViewController!.present(mcBrowser, animated: true)
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
      switch state {
      case .connected:
        
        print("Connected: \(peerID.displayName)")
      case .connecting:
        print("Connecting: \(peerID.displayName)")
      case .notConnected:
        print("Not Connected: \(peerID.displayName)")
      @unknown default:
        print("fatal error")
      }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let image = UIImage(data: data) {
                DispatchQueue.main.async { [unowned self] in
                    
                    
                    transferImageSubject.send(image)
                    
                    
                    // do something with the image
                }
            }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
      
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
      
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
      
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        UIApplication.shared.windows.first!.rootViewController!.dismiss(animated: true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        UIApplication.shared.windows.first!.rootViewController!.dismiss(animated: true)
    }
    
    
}
