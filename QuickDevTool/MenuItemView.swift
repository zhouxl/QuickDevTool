//
//  MenuItemView.swift
//  QuickDevTool
//
//  Created by cat on 2023/2/1.
//

import SwiftUI

struct MenuItem: Identifiable, Hashable {
    
    enum Action {
    case jsonToModel
    }
    
    var id = UUID()
    var name: String
    var image: String
    var subMenuItems: [MenuItem]?
    var type = Action.jsonToModel
}

struct MenuItemView: View {
    var item: MenuItem
    var body: some View {
        HStack {
            Image(item.image)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
            Text(item.name)
                .font(.system(.title3, design: .rounded))
                .bold()
        }
    }
}

struct MenuItemView_Previews: PreviewProvider {
    static var previews: some View {
        MenuItemView(item: MenuItem(name: "测试", image: "", type: .jsonToModel))
    }
}
