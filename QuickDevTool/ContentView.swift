//
//  ContentView.swift
//  QuickDevTool
//
//  Created by cat on 2023/1/31.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>

    @State private var selectedItemAction: MenuItem.Action?
    private var menuList = [
        MenuItem(name: "JSONToModel", image: "arrow.left.arrow.right", type: .jsonToModel)
    ]
    
    var body: some View {
        NavigationSplitView {
            List(menuList,selection: $selectedItemAction) { item in
                MenuItemView(item: item)
            }
        } detail: {
            if let selectedItemAction {
                if selectedItemAction == .jsonToModel {
                        JSONModelView()
                }
                
            } else {
                Text("Please select a category")
            }
        }
    }

   
}




struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
