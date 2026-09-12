import AVFoundation
import ExternalAccessory
import Combine

// MARK: - Model

struct HearingDevice {
    enum Category: String {
        case mfiHearingAid   = "MFi-Hörgerät"
        case bluetoothLE     = "Bluetooth LE Hörgerät"
        case unknown         = "Unbekannter Typ"
    }

    let name: String
    let category: Category
}

// MARK: - Manager

/// Detects paired MFi hearing aids and cochlear implant processors.
///
/// Apple's official APIs for hearing devices:
///   - `AVAudioSession.currentRoute.outputs` – shows active audio route
///   - `EAAccessoryManager.shared().connectedAccessories` – MFi accessories
///   - There is no dedicated Core Bluetooth API for hearing aids exposed publicly;
///     BTLE hearing aids appear in AVAudioSession route descriptions.
///   - No direct API to query CI processors vs hearing aids – we infer from
///     AVAudioSessionPortDescription.portType.
@MainActor
final class HearingDeviceManager: ObservableObject {

    @Published private(set) var pairedDevices: [HearingDevice] = []

    private var cancellables = Set<AnyCancellable>()

    init() {
        observeRouteChanges()
        refresh()
    }

    // MARK: - Public

    func refresh() {
        pairedDevices = detectDevices()
    }

    // MARK: - Detection

    private func detectDevices() -> [HearingDevice] {
        var found: [HearingDevice] = []

        // 1. Check AVAudioSession output ports for known hearing device types.
        let session = AVAudioSession.sharedInstance()
        let outputs = session.currentRoute.outputs

        for port in outputs {
            if let device = hearingDevice(from: port) {
                found.append(device)
            }
        }

        // 2. Check available inputs as well (some hearing aids expose a mic input port).
        let inputs = session.currentRoute.inputs
        for port in inputs {
            if let device = hearingDevice(from: port), !found.contains(where: { $0.name == device.name }) {
                found.append(device)
            }
        }

        // 3. Check MFi accessories via ExternalAccessory.
        let mfiAccessories = EAAccessoryManager.shared().connectedAccessories
        for accessory in mfiAccessories {
            // MFi hearing aids don't have a fixed protocol string we can hard-code,
            // but we can surface them so the developer can filter by known protocols.
            let isMfiHearingDevice = accessory.protocolStrings.contains { proto in
                // Common vendor-specific protocol patterns for hearing aids:
                proto.lowercased().contains("hearing") ||
                proto.lowercased().contains("aid") ||
                proto.lowercased().contains("ci") ||
                // Add manufacturer-specific protocol strings here as needed.
                false
            }
            if isMfiHearingDevice {
                let device = HearingDevice(name: accessory.name, category: .mfiHearingAid)
                if !found.contains(where: { $0.name == device.name }) {
                    found.append(device)
                }
            }
        }

        return found
    }

    private func hearingDevice(from port: AVAudioSessionPortDescription) -> HearingDevice? {
        switch port.portType {
        case .bluetoothLE:
            // BT LE is the transport used by Made-for-iPhone hearing aids.
            return HearingDevice(name: port.portName, category: .bluetoothLE)
        case .bluetoothHFP, .bluetoothA2DP:
            // Standard BT – could be hearing aids routing via HFP/A2DP profile.
            // Only include if name suggests a hearing device.
            let nameLower = port.portName.lowercased()
            if nameLower.contains("hearing") || nameLower.contains("ci") ||
               nameLower.contains("cochlear") || nameLower.contains("oticon") ||
               nameLower.contains("phonak") || nameLower.contains("widex") ||
               nameLower.contains("starkey") || nameLower.contains("resound") ||
               nameLower.contains("signia") || nameLower.contains("unitron") {
                return HearingDevice(name: port.portName, category: .bluetoothLE)
            }
            return nil
        default:
            return nil
        }
    }

    // MARK: - Route Change Observation

    private func observeRouteChanges() {
        NotificationCenter.default.publisher(
            for: AVAudioSession.routeChangeNotification
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.refresh()
        }
        .store(in: &cancellables)

        // Also observe MFi accessory connect/disconnect.
        NotificationCenter.default.publisher(for: .EAAccessoryDidConnect)
            .merge(with: NotificationCenter.default.publisher(for: .EAAccessoryDidDisconnect))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &cancellables)

        // Register for MFi notifications (required for EAAccessoryManager).
        EAAccessoryManager.shared().registerForLocalNotifications()
    }
}
