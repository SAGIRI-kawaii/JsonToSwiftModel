import Cocoa

let fileName = "test"
var objects: [String:String] = [String:String]()

// 对Array进行判断处理
func typeArray(dataString: String) -> String{
    
    var dataStr = dataString
    dataStr.popLast()
    dataStr.remove(at: dataStr.startIndex)
//    print("*|",dataStr,"|*")
    var newStr: String = ""
    if dataStr.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1) == "["{
        for i in dataStr{
            if newStr == "]"{
                break
            }
            newStr = newStr + String(i)
        }
//        print(newStr)
        return "[\(typeArray(dataString: newStr.trimmingCharacters(in: .whitespacesAndNewlines)))]"
    }else if dataStr.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1) == "{"{
        return "Object"
    }else if dataStr.trimmingCharacters(in: .whitespacesAndNewlines) == ""{
        return "nil"
    }else if dataStr.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1) == "\""{
        return "String"
    }else{
        do{
            let arraySubstrings: [Substring] = dataStr.split(separator: ",")
            let noTypeMatchError = try! Int(arraySubstrings[0])
            if arraySubstrings[0].contains("."){
                return "Float"
            }
            return "Int"
        }catch{
            print(error)
            exit(0)
        }
    }
}

// 判断数据类型
func typeJudge(dataStr: String) -> String{
    if dataStr.prefix(1) == "{" && dataStr.suffix(1) == "}"{
        return "Object"
    }else if dataStr.prefix(1) == "[" && dataStr.suffix(1) == "]"{
        return "[\(typeArray(dataString: dataStr))]"
    }else if dataStr.contains("\""){
        return "String"
    }else if dataStr == "null"{
        return "nil"
    }else if dataStr == ""{
        return "String?"
    }else{
        do{
            let noTypeMatchError = try Int(dataStr)
            if dataStr.contains("."){
                return "Float"
            }
            return "Int"
        }catch{
            print(error)
            exit(0)
        }
    }
}

// 根据字典内容拼接为swift字符串
func jsonDataToSwiftStr(jsonFileName: String, jsonData: [String: String]) -> String{
    let indentation: String = "    "
    var swiftStr: String = "struct \(jsonFileName): Codable{\n"
    for item in jsonData{
        let key: String = item.key
        let value: String = item.value
        
        swiftStr = swiftStr + "\(indentation)\(key): "
        swiftStr = swiftStr + "\(typeJudge(dataStr: value))\n"
        if typeJudge(dataStr: value) == "Object"{
            objects.updateValue(value, forKey: key)
        }
    }
    swiftStr = swiftStr + "}"
    return swiftStr
}

// 获取匹配的括号
func getMatch(char: Character) -> Character{
    if char == "}"{
        return "{"
    }else if char == "]"{
        return "["
    }else if char == ")"{
        return "("
    }else{
        print("error!")
        exit(0)
    }
}

// 读取Json文件
func readJsonFile(fileName: String) -> String{
    let baseUrl = URL(fileURLWithPath: NSHomeDirectory())
    let filename = "/Desktop/Code/IOS/\(fileName).json"
    let file = baseUrl.appendingPathComponent(filename)
//    print(file)
    let readHandler = try! FileHandle(forReadingFrom:file)
    let data = readHandler.readDataToEndOfFile()
    var readString: String = String(data: data, encoding: String.Encoding.utf8)!
//    print(readString)
    return readString
}

// 创建文件
func createSwiftFile(fileName: String){
    let manager = FileManager.default
    let baseUrl = URL(fileURLWithPath: NSHomeDirectory())
    let filename = "/Desktop/Code/IOS/\(fileName).swift"
    let file = baseUrl.appendingPathComponent(filename)
    
    let exist = manager.fileExists(atPath: file.path)
    if !exist {
        let data = Data(base64Encoded:"" ,options:.ignoreUnknownCharacters)
        let createSuccess = manager.createFile(atPath: file.path,contents:data,attributes:nil)
        print("文件创建结果: \(createSuccess)")
    }
}

// 保存文件
func saveSwiftFile(fileName: String, content: String){
    let manager = FileManager.default
    let baseUrl = URL(fileURLWithPath: NSHomeDirectory())
    let filename = "/Desktop/Code/IOS/\(fileName).swift"
    let file = baseUrl.appendingPathComponent(filename)
    
    if manager.fileExists(atPath: file.path){
        try! manager.removeItem(atPath: file.path)
    }
    
    createSwiftFile(fileName: fileName)
    
    let appendedData = content.data(using: String.Encoding.utf8, allowLossyConversion: true)
    let writeHandler = try? FileHandle(forWritingTo:file)
//    writeHandler!.seekToEndOfFile()
    writeHandler!.write(appendedData!)
}

// 获取json转译的字典
func getJsonData(jsonString: String) -> [String:String]{
    var jsonStr = jsonString
    jsonStr.popLast()
    jsonStr.remove(at: jsonStr.startIndex)
    
    var matchStack = [Character]()
    var jsonData =  [String: String]()

    var jsonKey: String = ""
    var jsonValue: String = ""

    var kvJudge:Bool = true
    var valueObjectjudge:Bool = false
    var valueStringjudge:Bool = false

    for char in jsonStr{
    //    print("\nchar:",char)
    //    print("jsonKey:",jsonKey,"       jsonValue:|",jsonValue,"|")
        if valueObjectjudge{
            if char == "{" || char == "["{
                jsonValue = jsonValue + String(char)
                matchStack.append(char)
            }else if char == "}" || char == "]"{
                jsonValue = jsonValue + String(char)
                if matchStack[matchStack.count-1] == getMatch(char: char){
                    matchStack.popLast()
                }
            }else if char == "," && matchStack.isEmpty{
                valueObjectjudge = false
                kvJudge = !kvJudge
                jsonKey = jsonKey.trimmingCharacters(in: .whitespacesAndNewlines)
                jsonValue = jsonValue.trimmingCharacters(in: .whitespacesAndNewlines)
                jsonData.updateValue(jsonValue, forKey: jsonKey)
//                print(jsonKey)
                jsonKey = ""
                jsonValue = ""
            }else{
                jsonValue = jsonValue + String(char).replacingOccurrences(of: "\\",with: "")
            }
        }else if valueStringjudge{
            if char == "\""{
                valueStringjudge = !valueStringjudge
            }
            if kvJudge{
                jsonKey = jsonKey + String(char).replacingOccurrences(of: "\"",with: "")
            }else{
                jsonValue = jsonValue + String(char).replacingOccurrences(of: "\\",with: "")
            }
        }else if char == ":"{
            kvJudge = !kvJudge
        }else if char == ","{
            kvJudge = !kvJudge
            jsonKey = jsonKey.trimmingCharacters(in: .whitespacesAndNewlines)
            jsonValue = jsonValue.trimmingCharacters(in: .whitespacesAndNewlines)
            jsonData.updateValue(jsonValue, forKey: jsonKey)
            jsonKey = ""
            jsonValue = ""
        }else if (char == "{" || char == "[") && jsonValue.replacingOccurrences(of: " ",with: "") == ""{
            jsonValue = jsonValue + String(char)
            matchStack.append(char)
            valueObjectjudge = true
        }else{
            if char == "\"" && jsonValue.trimmingCharacters(in: .whitespacesAndNewlines) == ""{
                valueStringjudge = !valueStringjudge
            }
            if kvJudge{
                jsonKey = jsonKey + String(char).replacingOccurrences(of: "\"",with: "")
            }else{
                jsonValue = jsonValue + String(char).replacingOccurrences(of: "\\",with: "")
            }
        }
    }
    jsonKey = jsonKey.trimmingCharacters(in: .whitespacesAndNewlines)
    jsonValue = jsonValue.trimmingCharacters(in: .whitespacesAndNewlines)
    if jsonKey != ""{
        jsonData.updateValue(jsonValue, forKey: jsonKey)
    }
    
    return jsonData
}

// 主函数
func main(){
    
    let fileManager = FileManager.default
    let filePath:String = NSHomeDirectory() + "/Desktop/Code/IOS/\(fileName).json"
    let exist = fileManager.fileExists(atPath: filePath)

    if !exist{
        print("错误！文件\(fileName)不存在！")
        exit(0)
    }
    
    let jsonStr: String = readJsonFile(fileName: fileName)
    
    let jsonData = getJsonData(jsonString: jsonStr)
    var result: String = jsonDataToSwiftStr(jsonFileName: fileName, jsonData: jsonData)
    
    while !objects.isEmpty{
        let dictKeys = [String](objects.keys)
        let jsonKey: String = dictKeys[0]
        let jsonStr: String = objects[jsonKey]!
        result = result + "\n\n\(jsonDataToSwiftStr(jsonFileName: jsonKey, jsonData: getJsonData(jsonString: jsonStr)))"
        objects.removeValue(forKey: jsonKey)
    }
    
    print(result)
    
    saveSwiftFile(fileName: fileName,content: result)
}

main()
