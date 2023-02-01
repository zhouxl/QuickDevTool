//
//  JSONModelView.swift
//  QuickDevTool
//
//  Created by cat on 2023/1/31.
//

import SwiftUI

protocol ModelHelper: CaseIterable {}

enum CodeLanguage: String,CaseIterable {
    case OC
    
    func modelHelper() -> [any ModelHelper] {
        switch self {
        case .OC:
            return OCModelHelper.allCases
        }
    }
    
    
    enum OCModelHelper:String, ModelHelper {
        case None
        case YYModel
    }
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
    
    var description: String {
        switch self {
        case .kArray(let value):
            return "NSArray<\(value.description)> *"
            
        case .kObject(let objectName):
            return "\(objectName) *"
            
        case .kInt:
            return "NSInteger"
            
        case .kString:
            return "NSString *"
            
        case .kDouble:
            return "double"
            
        case .kBool:
            return "BOOL"
        case .kFloat:
            return "CGFloat"
        case .kAny:
            return "id"
        }
        
    }
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
    var language: CodeLanguage = .OC {
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
    var result:[String] = []
    
    var isValidJSON = true
    
    mutating func updateModel()  {
        result.removeAll()
        convertToModelClass()
    }
    
    func showValidResult() -> Bool {
        guard !json.isEmpty else {
            return false
        }
        return isValidJSON
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
    var listKeyWord = blackKeyWord
    var dictObject: [String: [String: ValueClassType]] = [:]
    
    mutating func build() -> [String] {
        var result:[String] = []
        let className = buildName(name: info.fileName)
        covertJSONToModel(name: className, dic: info.jsonToDic())
        let fileH = buildHContent();
        result.append(fileH)
        return result
    }
    
    mutating func covertJSONToModel(name: String, dic: [String: Any]) {
        let className = buildName(name: name)
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
                                                               key: className + "_" + propertyName,
                                                               value: value as! Array<Any>
                                                               )
                dictObject[className]?[propertyName] = .kArray(dataTypeOfArray)
                
                
            case is [String : Any]:
                
                guard let value = value as? [String: Any] else { fatalError("???")}
                
                let objectName = self.buildName(name: className + "_" + propertyName)
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
    func covertToObjectString(uClassName: String, value: [String: ValueClassType]) -> String {
        
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
            strListParameters += "\(lowPName): \(self.buildName(name: pValue.description)), \n\t\t\t\t\t\t\t"
        }
        
        if strListParameters.count > 9 {
            strListParameters.removeLast(10)
        }
        
        strObject += strProperties + "\n"
        
        strObject += "@end\n"
        
        return strObject
    }
    
    func createProperty(_ valueType: ValueClassType,
                        key : String
                        ) -> String {
        let strValueType =  valueType.description
        var result = ""
        switch valueType {
        case .kArray(_), .kObject(_):
            result = "@property (nonatomic, strong) \(strValueType) \(self.buildProperty(name: key));\n"
        case .kString:
            result = "@property (nonatomic, copy) \(strValueType) \(self.buildProperty(name: key));\n"
        default:
            result = "@property (nonatomic, assign) \(strValueType) \(self.buildProperty(name: key));\n"
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
    
    func buildHContent() -> String {
        var result = ""
        var allClasses: [String] = []
        for (name, values) in dictObject {
            let uClassName = buildName(name: name)
            allClasses.append(uClassName)
            let str = covertToObjectString(uClassName:uClassName, value: values)
            result += str
        }
        let fileName = buildName(name: info.fileName)
        allClasses.removeAll { name in
            fileName == name
        }
        let preClass = "@class " + allClasses.joined(separator: ",") + ";\n"
        result.insert(contentsOf: preClass, at: result.startIndex)
        return result
    }
    
    func buildName(name: String) -> String {
        guard !name.isEmpty else {
            return "CustomModel"
        }
        return name;
    }
    
    func buildProperty(name: String) -> String {
        return name;
    }
    
    static let blackKeyWord = [
        "class",
        "operator",
        "deinit",
        "enum",
        "extension",
        "func",
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


struct JSONModelView: View {
    @State var modelInfo = JSONModelInfo()
    
    
    
    var body: some View {
        /* 左边是JSON，右边是Model */
        VStack(alignment: .leading) {
            HStack {
                // JSON
                VStack(alignment: .center){
                    Text("JSON 信息")
                    HStack {
                        TextField("工程名", text: $modelInfo.projectName, prompt: nil)
                        TextField("作者", text: $modelInfo.author, prompt: nil);
                    }
                    HStack {
                        TextField("父类", text: $modelInfo.superName, prompt: Text("NSObject"));
                        TextField("类名", text: $modelInfo.fileName, prompt: nil);
                    }
                    TextEditor(text: $modelInfo.json)
                }
                VStack{
                    if($modelInfo.result.count > 0) {
                        Text("生成Model信息")
                        ForEach(0..<modelInfo.result.count, id: \.self) { i in
                            TextEditor(text: $modelInfo.result[i])
                        }
                    }
                }
                
                
            }
            
            HStack() {
                if(modelInfo.showValidResult()) {
                    Text((modelInfo.isValidJSON ? "JSON数据✅":"JSON数据❌"))
                        .foregroundColor(modelInfo.isValidJSON ? Color.green : Color.red)
                }
                
                Button("格式化") {
                    
                }
                Button {
                    
                } label: {
                    Text("保存文件")
                }
                
                Spacer()
                
                Picker("", selection: $modelInfo.language) {
                    ForEach(CodeLanguage.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .frame(width: 100)
                
            }
            .padding(.top, 8)
        }
        .padding(.init(top: 16, leading: 16, bottom: 16, trailing: 16))
        
    }
}

struct JSONModelView_Previews: PreviewProvider {
    static var previews: some View {
        JSONModelView()
    }
}
