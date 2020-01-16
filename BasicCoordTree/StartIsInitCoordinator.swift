import UIKit
import RxSwift
import RxCocoa

class MainSICoordinator {
    let di: DI
    let view: UIWindow

    init(di: DI, view: UIWindow, link: MainLink?) {
        self.di = di
        self.view = view

        let viewModel = MainViewModel(di: di)
        let controller = MainViewController(vm: viewModel)
        view.rootViewController = controller

//        viewModel.profileRequested
    }
}
