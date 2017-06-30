//
//  UncaughtExceptionHandler.swift
//  CrashsReport
//
//  Created by 田子瑶 on 2017/6/1.
//  Copyright © 2017年 田子瑶. All rights reserved.
//

import Foundation
import UIKit

let UncaughtExceptionHandlerSignalExceptionName = "UncaughtExceptionHandlerSignalExceptionName"
let UncaughtExceptionHandlerSignalKey = "UncaughtExceptionHandlerSignalKey"
let UncaughtExceptionHandlerAddressesKey = "UncaughtExceptionHandlerAddressesKey"

var UncaughtExceptionCount: Int32 = 0
var UncaughtExceptionMaximum: Int32 = 10

var showAlertView: Bool?

typealias HandleException = (@convention(c) (NSException) -> Swift.Void)
typealias SignalHandler = (@convention(c) (Int32) -> Swift.Void)

public class UncaughtExceptionHandler: NSObject, UIAlertViewDelegate {
    
    /// 单例
    public static let shared = UncaughtExceptionHandler()
    
    /// Exception 闭包
    private static var handleException: HandleException = { (exception) in
        let exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount)
        // 如果太多不用处理
        if exceptionCount > UncaughtExceptionMaximum {
            return
        }
        
        let sel = #selector(UncaughtExceptionHandler.shared.handleException(_:))
        UncaughtExceptionHandler.shared.performSelectorOnMainThread(sel, withObject: exception, waitUntilDone: true)
    }
    
    /// Signal 闭包
    private static var signalHandler: SignalHandler = { (signal) in
        
        let exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount)
        // 如果太多不用处理
        if exceptionCount > UncaughtExceptionMaximum {
            return
        }
        
        var description: String? = nil
        
        switch signal {
        case SIGABRT:
            description = String(format: "Signal SIGABRT was raised!\n", "")
        case SIGILL:
            description = String(format: "Signal SIGILL was raised!\n", "")
        case SIGSEGV:
            description = String(format: "Signal SIGSEGV was raised!\n", "")
        case SIGFPE:
            description = String(format: "Signal SIGFPE was raised!\n", "")
        case SIGBUS:
            description = String(format: "Signal SIGBUS was raised!\n", "")
        case SIGPIPE:
            description = String(format: "Signal SIGPIPE was raised!\n", "")
        default:
            description = String(format: "Signal %d was raised!", signal)
        }
        
        var userInfo: [NSObject : AnyObject] = [NSObject : AnyObject]()
        guard let callStackSymbols = UncaughtExceptionHandler.getBacktrace() else {
            return
        }
        userInfo[UncaughtExceptionHandlerAddressesKey] = callStackSymbols
        userInfo[UncaughtExceptionHandlerSignalKey] = NSNumber.init(int: signal)
        let data = NSException(name: UncaughtExceptionHandlerSignalExceptionName, reason: description, userInfo: userInfo)
        let sel = #selector(UncaughtExceptionHandler.shared.handleException(_:))
        UncaughtExceptionHandler.shared.performSelectorOnMainThread(sel, withObject: data, waitUntilDone: true)
    }
    
    /// alertView 是否在窗口
    private var dismissed: Bool = false
    
    /// 设置异常处理
    ///
    /// - Parameters:
    ///   - install: 是否使用 Signal 处理异常
    ///   - showAlert: 是否弹出提醒
    public class func installUncaughtExceptionHandler(install: Bool, showAlert: Bool) {
        if install && showAlert {
            UncaughtExceptionHandler.shared.alertView(showAlert)
        }
        
        /*
         signal.h 头文件定义了一个变量类型 sig_atomic_t、两个函数调用和一些宏来处理程序执行期间报告的不同信号。
         sig_atomic_t 是 int 类型，在信号处理程序中作为变量使用。它是一个对象的整数类型，
         该对象可以作为一个原子实体访问，即使存在异步信号时，该对象可以作为一个原子实体访问。
         
         ## 宏定义
         1.SIG_DFL 默认的信号处理程序。
         2.SIG_ERR 表示一个信号错误。
         3.SIG_IGN 忽视信号。
         
         1.SIGABRT 程序异常终止。
         2.SIGFPE 算术运算出错，如除数为 0 或溢出。
         3.SIGILL 非法函数映象，如非法指令。
         4.SIGINT 中断信号，如 ctrl-C。
         5.SIGSEGV 非法访问存储器，如访问不存在的内存单元。
         6.SIGTERM 发送给本程序的终止请求信号。
         
         ## 库函数
         void (*signal(int sig, void (*func)(int)))(int)         
         该函数设置一个函数来处理信号，即信号处理程序。
         
         int raise(int sig)
         该函数会促使生成信号 sig。sig 参数与 SIG 宏兼容。

         */
        NSSetUncaughtExceptionHandler(install ? handleException : nil)
        signal(SIGABRT, install ? signalHandler : SIG_DFL)
        signal(SIGILL, install ? signalHandler : SIG_DFL)
        signal(SIGSEGV, install ? signalHandler : SIG_DFL)
        signal(SIGFPE, install ? signalHandler : SIG_DFL)
        signal(SIGBUS, install ? signalHandler : SIG_DFL)
        signal(SIGPIPE, install ? signalHandler : SIG_DFL)
    }
    
    private func alertView(isShow: Bool) {
        showAlertView = isShow
    }
    
    /// 获取调用堆栈
    private class func getBacktrace() -> [String]? {
        
        //指针列表
        var callstack = [UnsafeMutablePointer<Void>](count: 128, repeatedValue: nil)
        //backtrace用来获取当前线程的调用堆栈，获取的信息存放在这里的callstack中
        //128用来指定当前的buffer中可以保存多少个void*元素
        //返回值是实际获取的指针个数
        let frames = backtrace(&callstack, 128)
        
        //backtrace_symbols将从backtrace函数获取的信息转化为一个字符串数组
        //返回一个指向字符串数组的指针
        //每个字符串包含了一个相对于callstack中对应元素的可打印信息，包括函数名、偏移地址、实际返回地址
        let symbols = backtrace_symbols(callstack, frames)
        
        var tempArr: [String] = [String]()
        for i in 0 ..< Int(frames) where symbols[i] != nil {
            tempArr.append(String((symbols[i])))
        }
        free(symbols)
        return tempArr
    }
    
    /// 验证和保存关键应用数据
    ///
    /// - Parameter exception: <#exception description#>
    private func validateAndSaveCriticalApplicationData(exception: NSException) {
        
        let timeFormatter = NSDateFormatter()
        timeFormatter.dateFormat = "YYYY/MM/dd hh:mm:ss SS"
        let date: NSDate = NSDate()
        
        /// 堆栈信息
        let callStackSymbols = exception.callStackSymbols as NSArray
        
        /// 错误原因
        let reason: String = exception.reason!
        
        /// 错误标识
        let name: String = exception.name
        
        /// 抛出时间
        let time = timeFormatter.stringFromDate(date)
        
        /// 包含与接收器有关的应用关键数据
        let userInfo = exception.userInfo == nil ? "no user info" : "\(exception.userInfo!)"
        
        /// 运行环境
        let appInfo = getAppInfo()
        
        let format = "\n========异常错误报告========\n%@\n传输数据:%@\n抛出时间:%@\n错误标识:%@\n错误原因:\n%@\n堆栈信息:\n%@"
        let info = String(format: format, appInfo, userInfo, time, name, reason, callStackSymbols.componentsJoinedByString("\n"))
        print(info)
        writeToDisk(withInfo: info)
    }
    
    // 写入日志文件
    private func writeToDisk(withInfo info: String) {
        let documentpath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).last!
        let path = documentpath.stringByAppendingString("/Exception.txt")
        if NSFileManager.defaultManager().fileExistsAtPath(path) {
            UncaughtExceptionHandler.removeFromDisk()
        }
        do {
            try info.writeToFile(path, atomically: true, encoding: NSUTF8StringEncoding)
        }
        catch {}
    }
    
    // 读取日志文件
    private func readFromDisk() -> String? {
        let documentpath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).last!
        let path = documentpath.stringByAppendingString("/Exception.txt")
        if let data = NSData.init(contentsOfFile: path) {
            let crushStr = String.init(data: data, encoding: NSUTF8StringEncoding)
            guard let log = crushStr where log != "" else {
                return nil
            }
            return log
        }
        else {
            return nil
        }
    }
    
    // 删除日志文件
    private class func removeFromDisk() {
        let documentpath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).last!
        let path = documentpath.stringByAppendingString("/Exception.txt")
        do {
            try NSFileManager.defaultManager().removeItemAtPath(path)
        }
        catch {
            print("文件删除失败")
        }
    }
    
    // 上传日志文件
     public class func uploadCrashLog() {
        guard let log = UncaughtExceptionHandler.shared.readFromDisk() else { return }
        var param: [String:AnyObject] = [String:AnyObject]()
        param["content"] = log
        param["type"] = "crash"
        param["userId"] = "userId"
        param["areaId"] = "location"
        param["deviceId"] = UIDevice.currentDevice().identifierForVendor?.UUIDString
        print("upload success")
    }
    
    // 处理异常抛出
    @objc private func handleException(exception: NSException) {
        
        validateAndSaveCriticalApplicationData(exception)
        UncaughtExceptionHandler.uploadCrashLog()
        
        if showAlertView == true {
            let alert = UIAlertView(title: "出错了", message: "你可以尝试继续操作，但是应用可能无法正常运行.\n", delegate: self, cancelButtonTitle: "退出")
            alert.addButtonWithTitle("继续")
            alert.show()
        }
        
        let runLoop = CFRunLoopGetCurrent()
        let allModes = CFRunLoopCopyAllModes(runLoop) as [AnyObject]
    
        while self.dismissed == false {
            for mode in allModes {
                print(mode)
                CFRunLoopRunInMode(mode as! CFString, 0.001, false)
            }
        }
        
        NSSetUncaughtExceptionHandler(nil)
        signal(SIGABRT, SIG_DFL)
        signal(SIGILL, SIG_DFL)
        signal(SIGSEGV, SIG_DFL)
        signal(SIGFPE, SIG_DFL)
        signal(SIGBUS, SIG_DFL)
        signal(SIGPIPE, SIG_DFL)

        if exception.name == UncaughtExceptionHandlerSignalExceptionName {
            kill(getpid(), exception.userInfo?[UncaughtExceptionHandlerSignalKey] as! Int32)
        }
        else {
            exception.raise()
        }
    }
    
    private func getAppInfo() -> String {
        let appName = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleDisplayName") as? String ?? ""
        let devVersion = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as? String ?? ""
        let appVersion = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleVersion") as? String ?? ""
        let systemModel = UIDevice.currentDevice().model
        let systemName = UIDevice.currentDevice().systemName
        let systemVersion = UIDevice.currentDevice().systemVersion
        
        let format = "名称:%@\n开发版本号:%@\n发布版本号:%@\n设备类型:%@\n系统名称:%@\n系统版本:%@\n"
        return String(format: format, appName, devVersion, appVersion, systemModel, systemName, systemVersion)
    }
    
    public func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        guard buttonIndex == 0 else { return }
        self.dismissed = true
    }
}
