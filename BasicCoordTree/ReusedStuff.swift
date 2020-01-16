import UIKit
import RxSwift
import RxCocoa

enum ProfileLink {
    case showSettings
    case showAss
    case privacyNotice
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

class MainViewModel {
    let profileRequested: Observable<Void>!

    init(di: DI) { profileRequested = nil }
}

class MainViewController: UIViewController {
    let disposeBag = DisposeBag()

    init(vm: MainViewModel) { super.init(nibName: nil, bundle: nil) }

    required init?(coder aDecoder: NSCoder) { fatalError() }
}
