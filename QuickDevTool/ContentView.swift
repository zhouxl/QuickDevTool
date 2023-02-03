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

    @State private var selectedItemId: SideBarItem.ID?
    private var menuList = [
        SideBarItem(name: "JSONToModel", image: "arrow.left.arrow.right", type: .jsonToModel)
    ]
    
    var body: some View {
        
        NavigationView {
            List(menuList,selection: $selectedItemId) { item in
                NavigationLink {
                    JSONModelView()
                } label: {
                    SideBarView(item: item)
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 160)
        }
        .toolbar {
            ToolbarItem(placement: ToolbarItemPlacement.navigation) {
                Button {
                    toggleSidebar()
                } label: {
                    Label("Sidebar", systemImage: "sidebar.left")
                }
            }

        }
        
    }

    private func toggleSidebar() { // 2
#if os(iOS)
#else
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
#endif
    }
   
}





struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
