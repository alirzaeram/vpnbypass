import SwiftUI

@main
struct VPNBypassApp: App {
    @StateObject private var viewModel = DomainListViewModel(store: DomainStore())

    var body: some Scene {
        WindowGroup {
//            MainView(viewModel: viewModel)
//                .frame(minWidth: 900, minHeight: 620)
            
            ManagerView(viewModel: viewModel)
                .frame(minWidth: 500, idealWidth: 500, minHeight: 600, idealHeight: 700)
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
