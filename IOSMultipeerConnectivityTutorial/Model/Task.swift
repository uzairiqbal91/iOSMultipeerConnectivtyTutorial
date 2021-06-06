//
//  Task.swift
//  task
//
//  Created by Macbook on 6/5/21.
//

import Foundation
class Task: NSObject {
    
    var name:String?;
    var url:String?;
    var isDownload:Bool = false;
    var progress:Float = 0.0;
    var downloadTask:URLSessionDownloadTask?;
    var downloadTaskId:Int?;
    var downloadedData:NSData?;

}
