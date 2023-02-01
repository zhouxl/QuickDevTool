//
//  MenuItemView.swift
//  QuickDevTool
//
//  Created by cat on 2023/2/1.
//

import SwiftUI

struct SideBarItem: Identifiable, Hashable {
    
    enum Action {
    case jsonToModel
    }
    
    var id = UUID()
    var name: String
    var image: String
    var subMenuItems: [SideBarItem]?
    var type = Action.jsonToModel
}

struct SideBarView: View {
    var item: SideBarItem
    var body: some View {
        HStack {
            Image(systemName: item.image)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
            Text(item.name)
                .font(.system(.headline, design: .rounded))
                .bold()
        }
    }
}

struct MenuItemView_Previews: PreviewProvider {
    static var previews: some View {
        SideBarView(item: SideBarItem(name: "测试", image: "repeat", type: .jsonToModel))
    }
}
