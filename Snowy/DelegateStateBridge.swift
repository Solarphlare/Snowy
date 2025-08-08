import Foundation

class DelegateStateBridge: ObservableObject {
    @Published var isRegisteredWithAPNS: Bool
    @Published var didRegistrationSucceed: Bool?
    
    init(isRegisteredWithAPNS: Bool) {
        self.isRegisteredWithAPNS = isRegisteredWithAPNS
    }
}
