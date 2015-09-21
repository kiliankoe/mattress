//
//  String+Crypto.swift
//  Mattress
//
//  Created by Kevin Lord on 5/22/15.
//  Copyright (c) 2015 BuzzFeed. All rights reserved.
//

import Foundation

extension String {
    func mattress_MD5() -> String? {
        NSLog("String.MD5()")
        let MD5data = (self as NSString).dataUsingEncoding(NSUTF8StringEncoding)?.mattress_MD5()
        NSLog("MD5data: %@ type: %@", MD5data ?? "", String(MD5data?.dynamicType))
        let hexString = MD5data?.mattress_hexString()
        NSLog("MD5 hexString: %@ type: %@", hexString ?? "", String(hexString?.dynamicType))
        return hexString
    }

    func mattress_SHA1() -> String? {
        return (self as NSString).dataUsingEncoding(NSUTF8StringEncoding)?.mattress_SHA1().mattress_hexString()
    }
}
