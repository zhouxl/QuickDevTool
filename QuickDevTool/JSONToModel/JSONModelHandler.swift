//
//  JSONModelHandler.swift
//  QuickDevTool
//
//  Created by cat on 2023/1/31.
//

import Foundation

protocol ModelHelper: CaseIterable {}

enum CodeLanguage: String,CaseIterable {
    
    case OC
    
}

indirect enum ValueClassType {
    case kArray(ValueClassType)
    case kObject(String)
    case kInt
    case kString
    case kFloat
    case kDouble
    case kBool
    case kAny
    
    var tagForOC: String {
        switch self {
        case .kArray(let value):
            return "NSArray<\(value.tagForOC)> *"
            
        case .kObject(let objectName):
            return "\(objectName) *"
            
        case .kInt:
            return "NSInteger "
            
        case .kString:
            return "NSString *"
            
        case .kDouble:
            return "double "
            
        case .kBool:
            return "BOOL "
        case .kFloat:
            return "CGFloat "
        case .kAny:
            return "id "
        }
        
    }
}

struct CodeStyle {
    
}


struct JSONModelInfo {
    var projectName: String = "" {
        didSet {
            updateModel()
        }
    }
    var author: String = "" {
        didSet {
            updateModel()
        }
    }
    var superName: String = "" {
        didSet {
            updateModel()
        }
    }
    var fileName: String = "" {
        didSet {
            updateModel()
        }
    }
    var prefix: String = "" {
        didSet {
            updateModel()
        }
    }
    var json: String = "" {
        didSet {
            updateModel()
        }
    }
    
    var useCamelCase: Bool = true {
        didSet {
            updateModel()
        }
    }
    
    
    var suffix: String = "Model"
    
    var language: CodeLanguage = .OC {
        didSet {
            updateModel()
        }
    }
    
    
    
    var result:[String] = []
    
    var validJSONTag = ""
    var isValidJSON = false
    
    private mutating func updateModel()  {
        result.removeAll()
        
        guard self.jsonToDic().count > 0 && JSONSerialization.isValidJSONObject(self.jsonToDic()) else {
            validJSONTag = self.json.count == 0 ? "" :  "❌JSON数据"
            isValidJSON = false;
            return
        }
        isValidJSON = true
        validJSONTag = "✅JSON数据"
        convertToModelClass()
    }
    
    
    mutating func convertToModelClass()  {
        guard !self.json.isEmpty else {
            result = []
            return
        }
        
        var tool =  ConvertToOC(info: self)
        result.append(contentsOf: tool.build())
    }
    
    func jsonToDic() -> [String: Any] {
        if let data = json.data(using: String.Encoding.utf8){
            if let dic = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) {
                
                return dic as! [String : Any]
            }
        }
        
        //TODO: show error
        return [String : Any]()
    }
    
}

fileprivate struct ConvertToOC {
    let info: JSONModelInfo
    
    var dictObject: [String: [String: ValueClassType]] = [:]
    var camelCache:[String:String] = [:]
    var allClasses: [String] = []
    
    mutating func build() -> [String] {
        var result:[String] = []
        let className = buildName(name: info.fileName)
        covertJSONToModel(name: className, dic: info.jsonToDic())
        let fileH = buildHContent()
        result.append(fileH)
        let fileM = buildMContent()
        result.append(fileM)
        return result
    }
    
    mutating func covertJSONToModel(name: String, dic: [String: Any]) {
        let className = name
        dictObject[className] = [:]
        for(key, value) in dic {
            let propertyName = buildProperty(name: key)
            if type(of: value) == type(of: NSNumber(integerLiteral: 1)) {
                if let _ = value as? Int {
                    dictObject[className]?[propertyName] =  .kInt
                } else if let _ = value as? Float {
                    dictObject[className]?[propertyName] = .kFloat
                } else if let _ = value as? Double {
                    dictObject[className]?[propertyName] = .kDouble
                }
                continue
            }
            else if type(of: value) == type(of: NSNumber(booleanLiteral: true)) {
                dictObject[className]?[propertyName] = ValueClassType.kBool
                continue
            }
            
            switch value {
                
            case is String:
                
                dictObject[className]?[propertyName] = ValueClassType.kString
                
            case is Array<Any>:
                
                let dataTypeOfArray = self.createPropertyArray(numberOfChildren: 0,
                                                               key: buildChildClass(name: className, childName: propertyName),
                                                               value: value as! Array<Any>
                )
                dictObject[className]?[propertyName] = .kArray(dataTypeOfArray)
                
                
            case is [String : Any]:
                
                guard let value = value as? [String: Any] else { fatalError("???")}
                
                let objectName = buildChildClass(name: className, childName: propertyName)
                dictObject[className]?[propertyName] = .kObject(objectName)
                covertJSONToModel(name: objectName, dic: value)
            case is NSNull:
                dictObject[className]?[propertyName] = .kAny
            default:
                break
            }
        }
    }
    //TODO:
    mutating func covertToObjectString(uClassName: String, value: [String: ValueClassType]) -> String {
        
        let superClassName = info.superName.isEmpty ? "NSObject" : info.superName
        //
        
        
        var strObject = "\n#pragma mark - \(uClassName)\n\n"
        strObject += "@interface \(uClassName) : \(superClassName)\n\n"
        
        var strProperties = ""
        var strListParameters = ""
        
        
        for (pName, pValue) in value.sorted(by: {$0.key < $1.key}) {
            
            let lowPName = buildProperty(name: pName)
            
            strProperties += createProperty(pValue,
                                            key: lowPName)
            strListParameters += "\(lowPName): \(self.buildName(name: pValue.tagForOC)), \n\t\t\t\t\t\t\t"
        }
        
        if strListParameters.count > 9 {
            strListParameters.removeLast(10)
        }
        
        strObject += strProperties + "\n"
        
        strObject += "@end\n"
        
        return strObject
    }
    
    mutating func createProperty(_ valueType: ValueClassType,
                        key : String
    ) -> String {
        let strValueType =  valueType.tagForOC
        var result = ""
        switch valueType {
        case .kArray(_), .kObject(_):
            result = "@property (nonatomic, strong) \(strValueType)\(self.buildProperty(name: key));\n"
        case .kString:
            result = "@property (nonatomic, copy) \(strValueType)\(self.buildProperty(name: key));\n"
        default:
            result = "@property (nonatomic, assign) \(strValueType)\(self.buildProperty(name: key));\n"
        }
        
        return result
    }
    
    mutating func createPropertyArray(numberOfChildren : Int,key : String, value : [Any]) -> ValueClassType {
        guard let firstItem = value.first else {
            // ko lam
            print("array error")
            //TODO: 提示错误
            
            let valueType: ValueClassType = .kAny
            return numberOfChildren == 0 ? valueType : .kArray(valueType)
        }
        
        if type(of: value) == type(of: NSNumber(integerLiteral: 1)) {
            var valueType: ValueClassType = .kInt
            
            if let _ = value as? [Float] {
                valueType = .kFloat
            } else if let _ = value as? [Double] {
                valueType = .kDouble
            }
            
            return numberOfChildren == 0 ? valueType : .kArray(valueType)
        } else if type(of: value) == type(of: NSNumber(booleanLiteral: true)) {
            let valueType: ValueClassType = .kBool
            return numberOfChildren == 0 ? valueType : .kArray(valueType)
        }
        
        switch firstItem {
            
        case is String:
            let valueType: ValueClassType = .kString
            return numberOfChildren == 0 ? valueType : .kArray(valueType)
            
        case is Double:
            
            let valueType: ValueClassType = .kDouble
            return numberOfChildren == 0 ? valueType : .kArray(valueType)
            
        case is Array<Any>:
            
            guard let firstItem = firstItem as? [Any] else {
                fatalError("???")
            }
            
            let property = self.createPropertyArray(numberOfChildren: numberOfChildren + 1,
                                                    key: key,
                                                    value: firstItem
            )
            return numberOfChildren == 0 ? property : .kArray(property)
            
        case is [String : Any]:
            
            //                dictionary of all properties in all objects in array.
            var dicToalPropertyOfArray = [String : Any]()
            // list key having in all objects in array
            var listKeyHavingInAllElement = [String : Int]()
            // count of array
            let count = value.count
            
            //count key item appear in array
            // if count key == count then it appear in all objects
            for item in value {
                
                let itemDic = item as! [String : Any]
                
                for kk in itemDic.keys {
                    
                    let countTemp = listKeyHavingInAllElement[kk] ?? 0
                    
                    if countTemp == 0 {
                        dicToalPropertyOfArray[kk] = itemDic[kk]
                    }
                    listKeyHavingInAllElement[kk] = countTemp + 1
                }
            }
            // remove all countkey < count. it means remove all key which is not appear in all objects
            for itemKey in listKeyHavingInAllElement.keys {
                
                if listKeyHavingInAllElement[itemKey] != nil && listKeyHavingInAllElement[itemKey]! < count {
                    
                    listKeyHavingInAllElement.removeValue(forKey: itemKey)
                }
                
            }
            //TODO: show
            
            for itemKey in listKeyHavingInAllElement.keys {
                print("item key require = \(itemKey)")
            }
            
            if listKeyHavingInAllElement.count == 0 {
                self.covertJSONToModel(name: key,
                                       dic: dicToalPropertyOfArray
                )
            } else {
                self.covertJSONToModel(name: key,
                                       dic: dicToalPropertyOfArray
                )
            }
            return .kObject(self.buildName(name: key))
            
        default:
            
            let valueType: ValueClassType = .kAny
            return numberOfChildren == 0 ? valueType : .kArray(valueType)
        }
    }
    
    mutating func buildHContent() -> String {
        var result = ""
        for (name, values) in dictObject {
            let uClassName = buildName(name: name)
            allClasses.append(uClassName)
            let str = covertToObjectString(uClassName:uClassName, value: values)
            result += str
        }
        let fileName = buildName(name: info.fileName)
        
        var preClass = ""
        if allClasses.count > 0 {
            preClass = "@class " + allClasses.joined(separator: ",") + ";\n"
        }
        result.insert(contentsOf: preClass, at: result.startIndex)
        return result
    }
    /*
     + (nullable NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
     return @{
     @"cover":@"image.index_image",
     };
     }
     
     + (nullable NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass {
     return @{
     @"user_tasks": [PBBookUserTaskModel class]
     };
     }
     */
    mutating func buildMContent() -> String {
        var result = ""
        for className in allClasses {
            result = "\n#pragma mark - \(className)\n\n"
            result += "@implementation \(className)\n\n"
            if(info.useCamelCase) {
                result += "+ (nullable NSDictionary<NSString *, id> *)modelCustomPropertyMapper {\n"
                result += "\treturn @{\n"
                for (key, value) in camelCache {
                    result += "\t\t@\"\(key)\":@\"\(value)\",\n"
                }
                result += "\t};\n"
                result += "}\n"
            }
            result += "@end\n"
        }
        return result
    }
    
    func buildName(name: String) -> String {
        guard !name.isEmpty else {
            return "CustomModel"
        }
        
        return name;
    }
    
    func buildChildClass(name: String, childName: String) -> String {
        var preName = name;
        if(preName.hasSuffix(info.suffix)) {
            preName.removeSubrange(preName.range(of: info.suffix)!)
            preName += childName.capitalized + info.suffix
        }
        return preName
    }
    
    mutating func buildProperty(name: String) -> String {
        var proName = name;
        if KeyWord.OC.black.contains(proName) {
            proName = "b_" + proName
        }
        if( info.useCamelCase ) {
            
            if let cacheName = camelCache[name] {
                proName = cacheName
            }else  {
                proName = proName.lowerCameCase()
                camelCache[name] = proName
            }
        }
        
        
        return proName;
    }
}

extension String {
    func lowerCameCase(separatedBy word: String = "_") -> String {
        guard self.contains(word) else {
            return self
        }
        var name = self.components(separatedBy: word).map { $0.capitalized }.joined()
        let firstC = name.removeFirst()
        return firstC.lowercased() + name;
    }
}


struct KeyWord {
    struct OC {
        static let black: [String] = [
            "class",
            "operator",
            "deinit",
            "enum",
            "extension",
            "void",
            "import",
            "init",
            "let",
            "protocol",
            "static",
            "struct",
            "subscript",
            "typealias",
            "var",
            "break",
            "case",
            "continue",
            "default",
            "do",
            "else",
            "fallthrough",
            "if",
            "in",
            "for",
            "return",
            "switch",
            "where",
            "while",
            "as",
            "is",
            "new",
            "super",
            "self",
            "Self",
            "Type",
            "associativity",
            "didSet",
            "get",
            "infix",
            "inout",
            "mutating",
            "nonmutating",
            "operator",
            "override",
            "postfix",
            "precedence",
            "prefix",
            "set",
            "unowned",
            "weak",
            "Any",
            "AnyObject"
        ]
    }
    

}

