//
//  EVReflection.swift
//
//  Created by Edwin Vermeer on 28-09-14.
//  Copyright (c) 2014 EVICT BV. All rights reserved.
//

import Foundation

/**
Reflection methods
*/
public class EVReflection {
    /**
    Create an object from a dictionary
    
    :param: dictionary The dictionary that will be converted to an object
    :param: anyobjectTypeString The string representation of the object type that will be created
    :return: The object that is created from the dictionary
    */
    public class func fromDictionary(dictionary:Dictionary<String, AnyObject?>, anyobjectTypeString: String) -> NSObject {
        var anyobjectype : AnyObject.Type = swiftClassFromString(anyobjectTypeString)
        var nsobjectype : NSObject.Type = anyobjectype as NSObject.Type
        var nsobject: NSObject = nsobjectype()
        for (key: String, value: AnyObject?) in dictionary {
            if (dictionary[key] != nil) {
                var newValue: AnyObject? = dictionary[key]!
                var error:NSError?
                if nsobject.validateValue(&newValue, forKey: key, error: &error) {
                    nsobject.setValue(newValue, forKey: key)
                }
            }
        }
        return nsobject
    }
    
    /**
    Convert an object to a dictionary
    
    :param: theObject The object that will be converted to a dictionary
    :return: The dictionary that is created from theObject
    */
    public class func toDictionary(theObject: NSObject) -> Dictionary<String, AnyObject> {
        var propertiesDictionary : Dictionary<String, AnyObject> = Dictionary<String, AnyObject>()
        let reflected = reflect(theObject)
        return reflectedSub(reflected)
    }
    
    
    private class func reflectedSub(reflected:MirrorType) -> Dictionary<String, AnyObject> {
        var propertiesDictionary : Dictionary<String, AnyObject> = Dictionary<String, AnyObject>()
        for i in 0..<reflected.count {
            let key : String = reflected[i].0
            let value = reflected[i].1.value
            if key != "super" || i != 0 {
                var v : AnyObject = valueForAny(value)
                propertiesDictionary.updateValue(v, forKey: key)
            } else {
                let superReflected = reflected[i].1
                let addProperties = reflectedSub(superReflected)
                for (k, v) in addProperties {
                    propertiesDictionary.updateValue(v, forKey: k)
                }
            }
        }
        return propertiesDictionary
    }
    
    /**
    Dump the content of this object
    
    :param: theObject The object that will be loged
    :return: No return value
    */
    public class func logObject(theObject: NSObject) {
        NSLog(description(theObject))
    }

    /**
    Return a string representation of this object
    
    :param: theObject The object that will be loged
    :return: The string representation of the object
    */
    public class func description(theObject: NSObject) -> String {
        var description : String = swiftStringFromClass(theObject) + " {\n"
        for (key: String, value: AnyObject) in toDictionary(theObject) {
            description = description  + "   key = \(key), value = \(value)\n"
        }
        description = description + "}\n"
        return description
    }

    
    /**
    Get the swift Class from a string
    
    :param: className The string representation of the class (name of the bundle dot name of the class)
    :return: The Class type
    */
    public class func swiftClassFromString(className: String) -> AnyClass! {
        if  var appName: String = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleName") as String? {
            appName = appName.stringByReplacingOccurrencesOfString(" ", withString: "_", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
            let classStringName = "\(appName).\(className)"
            return NSClassFromString(classStringName)
        }
        return nil;
    }
    
    /**
    Get the class name as a string from a swift class
    
    :param: theObject An object for whitch the string representation of the class will be returned
    :return: The string representation of the class (name of the bundle dot name of the class)
    */
    public class func swiftStringFromClass(theObject: NSObject) -> String! {
        if  var appName: String = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleName") as String? {
            appName = appName.stringByReplacingOccurrencesOfString(" ", withString: "_", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
            let classStringName: String = NSStringFromClass(theObject.dynamicType)
            return classStringName.stringByReplacingOccurrencesOfString(appName + ".", withString: "", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        }
        return nil;
    }

    /**
    Encode any object
    
    :param: theObject The object that we want to encode.
    :param: aCoder The NSCoder that will be used for encoding the object.
    */
    public class func encodeWithCoder(theObject:NSObject, aCoder: NSCoder) {
        for (key, value) in toDictionary(theObject) {
            aCoder.encodeObject(value, forKey: key)
        }
    }

    /**
    Decode any object
    
    :param: theObject The object that we want to decode.
    :param: aDecoder The NSCoder that will be used for decoding the object.
    */
    public class func decodeObjectWithCoder(theObject:NSObject, aDecoder: NSCoder) {
        for (key, value) in toDictionary(theObject) {
            if aDecoder.containsValueForKey(key) {
                var newValue: AnyObject? = aDecoder.decodeObjectForKey(key)
                if theObject.validateValue(&newValue, forKey: key, error: nil) {
                    theObject.setValue(newValue, forKey: key)
                }
            }
        }
    }

    //TODO: Make this work with nulable types
    /**
    Helper function to convert an Any to AnyObject
    
    :param: anyValue Something of type Any is converted to a type NSObject
    :return: The NSOBject that is created from the Any value
    */
    public class func valueForAny(anyValue:Any) -> NSObject {
        var theValue = anyValue
        let mi:MirrorType = reflect(theValue)
        if mi.disposition == .Optional {
          if mi.count == 0 { return NSNull() } // Optional.None
          let (name,some) = mi[0]
          theValue = some.value
        }
        
        switch(theValue) {
        case let intValue as Int:
            return NSNumber(int: CInt(intValue))
        case let doubleValue as Double:
            return NSNumber(double: CDouble(doubleValue))
        case let stringValue as String:
            return stringValue as NSString
        case let boolValue as Bool:
            return NSNumber(bool: boolValue)
        case let primitiveArrayValue as Array<String>:
            return primitiveArrayValue as NSArray
        case let primitiveArrayValue as Array<Int>:
            return primitiveArrayValue as NSArray
        case let anyvalue as NSObject:
            return anyvalue as NSObject
        default:
            return NSNull() // Could not happen
        }
    }
    
}