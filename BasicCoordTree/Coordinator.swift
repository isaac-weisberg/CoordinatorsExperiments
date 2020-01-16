import UIKit
import RxSwift
import RxCocoa

enum ProfileLink {
    
}

enum MainLink {
    case profile(ProfileLink)
    case other
}

class DI {
    
}


class ProfileViewModel {
    init(di: DI) { onClose = nil }
    
    let onClose: Observable<Void>!
}

class ProfileController: UIViewController {
    let disposeBag = DisposeBag()
    init(vm: ProfileViewModel) { super.init(nibName: nil, bundle: nil) }

    required init?(coder aDecoder: NSCoder) { fatalError() }
}

class ProfileCoordinator {
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
    
    func handleLink(_ profileLink: ProfileLink) -> Bool {
        if self.profileController == nil {
            // means haven't started yet
            start()
        }
        return true
    }
}

class MainViewModel {
    let profileRequested: Observable<Void>!
    
    init(di: DI) { profileRequested = nil }
}

class MainViewController: UIViewController {
    let disposeBag = DisposeBag()
    
    init(vm: MainViewModel) { super.init(nibName: nil, bundle: nil) }
    
    required init?(coder aDecoder: NSCoder) { fatalError() }
}

class MainCoordinator {
    let view: UIWindow
    let di: DI
    
    var profileCoordinator: ProfileCoordinator?
    
    var mainController: MainViewController?
    
    init(view: UIWindow, di: DI) {
        self.view = view
        self.di = di
    }
    
    func start() {
        let viewModel = MainViewModel(di: di)
        let controller = MainViewController(vm: viewModel)
        view.rootViewController = controller
        
        viewModel.profileRequested
            .bind(onNext: { [unowned controller, unowned self] _ in
                let profileCoordinator = ProfileCoordinator(view: controller, di: self.di)
                self.profileCoordinator = profileCoordinator
                profileCoordinator.done
                    .bind(onNext: { [unowned self] _ in
                        self.profileCoordinator = nil
                    })
                    .disposed(by: profileCoordinator.disposeBag)
            })
            .disposed(by: controller.disposeBag)
    }
    
    func handleLink(_ link: MainLink) -> Bool {
        guard let mainController = self.mainController else {
            // means coordinator is not started yet
            return false
        }
        switch link {
        case .profile(let profileLink):
            if let profileCoordinator = self.profileCoordinator {
                return profileCoordinator.handleLink(profileLink)
            }
            let profileCoordinator = ProfileCoordinator(view: mainController, di: di)
            if profileCoordinator.handleLink(profileLink) {
                self.profileCoordinator = profileCoordinator
                
                profileCoordinator.done
                    .bind(onNext: { [unowned self] _ in
                        self.profileCoordinator = nil
                    })
                    .disposed(by: profileCoordinator.disposeBag)
                
                return true
            }
            return false
        case .other:
            return false
        }
    }
}
