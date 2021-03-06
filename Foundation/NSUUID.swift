// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation

#if os(OSX) || os(iOS)
    import Darwin.uuid
#elseif os(Linux)
    import Glibc
#endif

open class NSUUID : NSObject, NSCopying, NSSecureCoding, NSCoding {
    internal var buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
    
    public override init() {
        _cf_uuid_generate_random(buffer)
    }
    
    public convenience init?(uuidString string: String) {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
        if _cf_uuid_parse(string, buffer) != 0 {
            return nil
        }
        self.init(uuidBytes: buffer)
    }
    
    public init(uuidBytes bytes: UnsafePointer<UInt8>) {
        memcpy(unsafeBitCast(buffer, to: UnsafeMutableRawPointer.self), UnsafeRawPointer(bytes), 16)
    }
    
    open func getBytes(_ uuid: UnsafeMutablePointer<UInt8>) {
        _cf_uuid_copy(uuid, buffer)
    }
    
    open var uuidString: String {
        let strPtr = UnsafeMutablePointer<Int8>.allocate(capacity: 37)
        _cf_uuid_unparse_upper(buffer, strPtr)
        return String(cString: strPtr)
    }
    
    open override func copy() -> Any {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    public convenience required init?(coder: NSCoder) {
        if coder.allowsKeyedCoding {
            let decodedData : Data? = coder.withDecodedUnsafeBufferPointer(forKey: "NS.uuidbytes") {
                guard let buffer = $0 else { return nil }
                return Data(buffer: buffer)
            }

            guard let data = decodedData else { return nil }
            guard data.count == 16 else { return nil }
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
            data.copyBytes(to: buffer, count: 16)
            self.init(uuidBytes: buffer)
        } else {
            // NSUUIDs cannot be decoded by non-keyed coders
            coder.failWithError(NSError(domain: NSCocoaErrorDomain, code: CocoaError.coderReadCorrupt.rawValue, userInfo: [
                                "NSDebugDescription": "NSUUID cannot be decoded by non-keyed coders"
                                ]))
            return nil
        }
    }
    
    open func encode(with aCoder: NSCoder) {
        aCoder.encodeBytes(buffer, length: 16, forKey: "NS.uuidbytes")
    }
    
    open override func isEqual(_ value: Any?) -> Bool {
        if let other = value as? UUID {
            return other.uuid.0 == buffer[0] &&
                other.uuid.1 == buffer[1] &&
                other.uuid.2 == buffer[2] &&
                other.uuid.3 == buffer[3] &&
                other.uuid.4 == buffer[4] &&
                other.uuid.5 == buffer[5] &&
                other.uuid.6 == buffer[6] &&
                other.uuid.7 == buffer[7] &&
                other.uuid.8 == buffer[8] &&
                other.uuid.9 == buffer[9] &&
                other.uuid.10 == buffer[10] &&
                other.uuid.11 == buffer[11] &&
                other.uuid.12 == buffer[12] &&
                other.uuid.13 == buffer[13] &&
                other.uuid.14 == buffer[14] &&
                other.uuid.15 == buffer[15]
        } else if let other = value as? NSUUID {
            if other === self {
                return true
            }
            return _cf_uuid_compare(buffer, other.buffer) == 0
        }
        return false
    }
    
    open override var hash: Int {
        return Int(bitPattern: CFHashBytes(buffer, 16))
    }
    
    open override var description: String {
        return uuidString
    }
}

extension NSUUID : _StructTypeBridgeable {
    public typealias _StructType = UUID
    
    public func _bridgeToSwift() -> UUID {
        return UUID._unconditionallyBridgeFromObjectiveC(self)
    }
}
