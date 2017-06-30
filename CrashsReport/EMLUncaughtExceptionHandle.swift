//
//  EMLUncaughtExceptionHandle.swift
//  CrashsReport
//
//  Created by 田子瑶 on 2017/6/1.
//  Copyright © 2017年 田子瑶. All rights reserved.
//

import Foundation
import UIKit

public class EMLUncaughtExceptionHandle: NSObject {
    
    // 单例
    static let shared = EMLUncaughtExceptionHandle()
    
    // 本地日志路径
    lazy var exceptionFilePath: String = {
        let documentpath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).last!
        let path = documentpath.stringByAppendingString("/Exception.txt")
        return path
    }()
    
    // 打印本地日志
    public func getdataPath() {
        if let data = NSData.init(contentsOfFile: exceptionFilePath) {
            let crushStr = String.init(data: data, encoding: NSUTF8StringEncoding)
            //let crushStr = String.init(data: data as NSData, encoding: String.Encoding.utf8)
            print(crushStr!)
        }
        else {
            print("无报错信息")
        }
    }
    
    // 写入日志文件
    public func setDefaultHandler() {
        
        NSSetUncaughtExceptionHandler { (exception) in
            
            let timeFormatter = NSDateFormatter()
            timeFormatter.dateFormat = "YYYY/MM/dd hh:mm:ss SS"
            let date: NSDate = NSDate()
            
            /// 堆栈信息
            let callStackSymbols: NSArray = exception.callStackSymbols as NSArray
            
            /// 错误原因
            let reason: String = exception.reason!
            
            /// 错误标识
            let name: String = exception.name
            
            /// 抛出时间
            let time = timeFormatter.stringFromDate(date)
            let format = "========异常错误报告========\n抛出时间:%@\n错误标识:%@\n错误原因:\n%@\n堆栈信息:\n%@"
            let info = String(format: format, time, name, reason, callStackSymbols.componentsJoinedByString("\n"))
            
            print(info)
            
            // 写入本地
            let documentpath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).last!
            let path = documentpath.stringByAppendingString("/Exception.txt")
            do{
                //try info.write(toFile: path, atomically: true, encoding: String.Encoding.utf8)
                try info.writeToFile(path, atomically: true, encoding: NSUTF8StringEncoding)
            }catch{
                print("写入失败")
            }
            
            // 上传到服务器
            /*
            var request = NSURLRequest(URL: NSURL.init(string: "https://www.baidu.com/s")!)
            request.httpMethod = "GET"
            request.httpBody = ("wd=" + info).data(using: .utf8)
            request.timeoutInterval = 5.0
            let session = NSURLSession.shared.dataTask(with: request, completionHandler: { (data, resp, error) in
                guard error == nil else { return }
                print("上传成功")
            })
            session.resume()
            */
                        
            // 发送邮件
            //UIApplication.sharedApplication().openURL(NSURL(string: "mailto://ziyao.tian@gmail.com")!)
        }
    }
}
