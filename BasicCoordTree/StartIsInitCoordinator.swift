import UIKit
import RxSwift
import RxCocoa

class ProfileSICoordinator {
    let view: UIViewController
    let di: DI

    let done = PublishRelay<Void>()
    let disposeBag = DisposeBag()

    weak var profileController: ProfileController?

    init(view: UIViewController, di: DI, link: ProfileLink?) {
        self.view = view
        self.di = di

        let viewModel = ProfileViewModel(di: di)
        let profileController = ProfileController(vm: viewModel)
        view.present(profileController, animated: true)

        Observable
            .merge(
                viewModel.onClose,
                profileController.rx.deallocated
            )
            .bind(to: done)
            .disposed(by: profileController.disposeBag)
    }

    func handleLink(_ profileLink: ProfileLink) {
        guard let profileController = profileController else {
            // means the coordinator is already dead
            // should theoretically never be called
            return
        }
        // find view model, inject new state,
        // maybe push new screens and shit
    }
}

class MainSICoordinator {
    let di: DI
    let view: UIWindow

    let disposeBag = DisposeBag()
    var profileCoordinator: ProfileSICoordinator?
    let mainController: MainViewController

    init(di: DI, view: UIWindow, link: MainLink?) {
        self.di = di
        self.view = view

        let viewModel = MainViewModel(di: di)
        let controller = MainViewController(vm: viewModel)
        self.mainController = controller
        view.rootViewController = controller

        viewModel.profileRequested
            .bind(onNext: { [unowned self] _ in
                self.startProfileCoordinator(link: nil)
            })
            .disposed(by: controller.disposeBag)
    }

    func handleLink(_ link: MainLink) {
        switch link {
        case .profile(let profileLink):
            if let profileCoordinator = self.profileCoordinator {
                profileCoordinator.handleLink(profileLink)
                break
            }

            self.startProfileCoordinator(link: profileLink)
        case .other:
            break
        }
    }

    private func startProfileCoordinator(link: ProfileLink?) {
        let profileCoordinator = ProfileSICoordinator(view: mainController, di: self.di, link: link)

        self.profileCoordinator = profileCoordinator

        profileCoordinator.done
            .bind(onNext: { [unowned self] _ in
                self.profileCoordinator = nil
            })
            .disposed(by: profileCoordinator.disposeBag)
    }
}
