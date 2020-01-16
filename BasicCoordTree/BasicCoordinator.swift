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
    
    func handleLink(_ profileLink: ProfileLink) -> Bool {
        if self.profileController == nil {
            // means haven't started yet
            start()
        }
        return true
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
        view.rootViewController = controller
        
        viewModel.profileRequested
            .bind(onNext: { [unowned controller, unowned self] _ in
                let profileCoordinator = ProfileBasicCoordinator(view: controller, di: self.di)
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
            let profileCoordinator = ProfileBasicCoordinator(view: mainController, di: di)
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
