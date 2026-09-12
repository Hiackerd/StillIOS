import AVFoundation
import ExternalAccessory
import Combine

// MARK: - Model

struct HearingDevice {
    enum Category: String {
        case mfiHearingAid = "MFi-Hörgerät"
        case bluetoothLE   = "Bluetooth LE Hörgerät"
        case unknown       = "Unbekannter Typ"
    }
    let name: String
    let category: Category
}

// MARK: - Manager

/// Detects paired MFi hearing aids and cochlear implant processors
/// via AVAudioSession route and EAAccessoryManager.
@MainActor
final class HearingDeviceManager: ObservableObject {

    @Published private(set) var pairedDevices: [HearingDevice] = []

    private var cancellables = Set<AnyCancellable>()

    init() {
        observeRouteChanges()
        refresh()
    }

    func refresh() {
        pairedDevices = detectDevices()
    }

    // MARK: - Detection

    private func detectDevices() -> [HearingDevice] {
        var found: [HearingDevice] = []
        let session = AVAudioSession.sharedInstance()

        for port in session.currentRoute.outputs + session.currentRoute.inputs {
            if let device = hearingDevice(from: port),
               !found.contains(where: { $0.name == device.name }) {
                found.append(device)
            }
        }

        for accessory in EAAccessoryManager.shared().connectedAccessories {
            let isMfi = accessory.protocolStrings.contains {
                $0.lowercased().contains("hearing") ||
                $0.lowercased().contains("aid") ||
                $0.lowercased().contains("ci")
            }
            if isMfi, !found.contains(where: { $0.name == accessory.name }) {
                found.append(HearingDevice(name: accessory.name, category: .mfiHearingAid))
            }
        }

        return found
    }

    private func hearingDevice(from port: AVAudioSessionPortDescription) -> HearingDevice? {
        switch port.portType {
        case .bluetoothLE:
            return HearingDevice(name: port.portName, category: .bluetoothLE)
        case .bluetoothHFP, .bluetoothA2DP:
            let n = port.portName.lowercased()
            let knownBrands = ["hearing","ci","cochlear","oticon","phonak",
                               "widex","starkey","resound","signia","unitron"]
            guard knownBrands.contains(where: { n.contains($0) }) else { return nil }
            return HearingDevice(name: port.portName, category: .bluetoothLE)
        default:
            return nil
        }
    }

    // MARK: - Observation

    private func observeRouteChanges() {
        NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)
            .merge(with: NotificationCenter.default.publisher(for: .EAAccessoryDidConnect))
            .merge(with: NotificationCenter.default.publisher(for: .EAAccessoryDidDisconnect))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &cancellables)

        EAAccessoryManager.shared().registerForLocalNotifications()
    }
}