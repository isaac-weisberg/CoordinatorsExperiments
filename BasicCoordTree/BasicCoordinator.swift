import UIKit
import RxSwift
import RxCocoa

class ProfileBasicCoordinator {
    let view: UIViewController
    let di: DI
    
    let done = PublishRelay<Void>()
    let disposeBag = DisposeBag()
    
    weak var profileController: ProfileController?
    
    init(view: UIViewController, di: DI) {
        self.view = view
        self.di = di
    }
    
    func start() {
        let viewModel = ProfileViewModel(di: di)
        let profileController = ProfileController(vm: viewModel)
        self.view.present(profileController, animated: true)
        
        Observable.merge(
            viewModel.onClose,
            profileController.rx.deallocated
        )
        .bind(to: done)
        .disposed(by: profileController.disposeBag)
    }
    
    func handleLink(_ profileLink: ProfileLink) {
        guard let profileController = self.profileController else {
            // means haven't started yet
            // or already finished
            return
        }
        // do whatever
    }
}

class MainBasicCoordinator {
    let view: UIWindow
    let di: DI
    
    var profileCoordinator: ProfileBasicCoordinator?
    
    var mainController: MainViewController?
    
    init(view: UIWindow, di: DI) {
        self.view = view
        self.di = di
    }
    
    func start() {
        let viewModel = MainViewModel(di: di)
        let controller = MainViewController(vm: viewModel)
        self.mainController = controller
        view.rootViewController = controller
        
        viewModel.profileRequested
            .bind(onNext: { [unowned self] _ in
                self.startProfileCoordinator()
            })
            .disposed(by: controller.disposeBag)
    }
    
    func handleLink(_ link: MainLink) {
        guard let mainController = self.mainController else {
            // means coordinator is not started yet
            // or already finished
            return
        }
        switch link {
        case .profile(let profileLink):
            let profileCoordinator = self.profileCoordinator ?? {
                let profileCoordinator = ProfileBasicCoordinator(view: mainController, di: di)
                self.profileCoordinator = profileCoordinator

                profileCoordinator.done
                    .bind(onNext: { [unowned self] _ in
                        self.profileCoordinator = nil
                    })
                    .disposed(by: profileCoordinator.disposeBag)

                profileCoordinator.start() // ?

                return profileCoordinator
            }()

            profileCoordinator.handleLink(profileLink)
        case .other:
            break
        }
    }

    private func startProfileCoordinator() {
        guard let mainController = self.mainController else {
            // means the coordinator is dead
            // or not yet alive
            return
        }
        let profileCoordinator = ProfileBasicCoordinator(view: mainController, di: di)

        self.profileCoordinator = profileCoordinator

        profileCoordinator.done
            .bind(onNext: { [unowned self] _ in
                self.profileCoordinator = nil
            })
            .disposed(by: profileCoordinator.disposeBag)

        profileCoordinator.start()
    }
}
