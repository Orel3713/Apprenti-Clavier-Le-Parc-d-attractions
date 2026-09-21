import Foundation

enum AppInfo {
    static let name = "Apprenti Clavier - Le Parc d’attractions"
    static var version: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "1.0"
    }
    static var build: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String ?? "1"
    }
    static let developer = "Aurélien Reffay"
    static let initialAccessibilityAnnouncement =
        "\(name). Version \(version). Développé par \(developer)."
    static let iconAccessibilityLabel =
        "Logo d’Apprenti Clavier le Parc d’attractions. Au premier plan, deux mains tapent sur un clavier surmonté d’un œil vert. En arrière-plan s’étend une fête foraine colorée, avec notamment une grande roue, des montagnes russes, des ballons et un chapiteau. Un bandeau rouge porte le titre « Apprenti Clavier le Parc d’attractions »."
    static let summary = "Des jeux autour de la frappe au clavier, dans un parc d’attractions ludique et accessible avec VoiceOver."
    static let accessibilityStatement = "Conçu pour être pleinement accessible avec VoiceOver."
    static let copyright = "© 2026 Aurélien Reffay."
}

