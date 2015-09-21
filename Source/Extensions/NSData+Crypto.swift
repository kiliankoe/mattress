//
//  NSData+Crypto.swift
//  Mattress
//
//  Created by Kevin Lord on 5/22/15.
//  Copyright (c) 2015 BuzzFeed. All rights reserved.
//

import Foundation
import CommonCrypto

extension NSData {
    func mattress_hexString() -> String {
        NSLog("hexString")
        var string = String()
        for i in UnsafeBufferPointer<UInt8>(start: UnsafeMutablePointer<UInt8>(bytes), count: length) {
            NSLog("hex string fragment: %@", NSString(format:"%02x", i) as String)
            string += String(format:"%02x", i)
            NSLog("hex string: %@", string)
        }
        return string
    }

    func mattress_MD5() -> NSData {
        NSLog("NSData.MD5()")
        let result = NSMutableData(length: Int(CC_MD5_DIGEST_LENGTH))!
        CC_MD5(bytes, CC_LONG(length), UnsafeMutablePointer<UInt8>(result.mutableBytes))
        return NSData(data: result)
    }

    func mattress_SHA1() -> NSData {
        let result = NSMutableData(length: Int(CC_SHA1_DIGEST_LENGTH))!
        CC_SHA1(bytes, CC_LONG(length), UnsafeMutablePointer<UInt8>(result.mutableBytes))
        return NSData(data: result)
    }
}
