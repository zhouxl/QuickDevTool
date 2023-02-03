//
//  JSONModelView.swift
//  QuickDevTool
//
//  Created by cat on 2023/1/31.
//

import SwiftUI

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
                        TextField("文件名（外层类名）", text: $modelInfo.fileName, prompt: nil);
                    }
                    TextEditor(text: $modelInfo.json)
                }
                .listStyle(SidebarListStyle())
                VStack{
                    if($modelInfo.result.count > 0) {
                        Text("生成Model信息")
                        ForEach(0..<modelInfo.result.count, id: \.self) { i in
                            TextEditor(text: $modelInfo.result[i])
                                .padding(8)
                        }
                    }
                }
                .listStyle(SidebarListStyle())
                
            }
            
            HStack() {
                
                Text(modelInfo.validJSONTag)
                    .foregroundColor(modelInfo.isValidJSON ? Color.green : Color.red)
                
                
                Button("格式化") {
                    modelInfo.prettyJson()
                }
                Button {
                    
                } label: {
                    Text("保存文件")
                }
                .disabled(true)
                
                
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
