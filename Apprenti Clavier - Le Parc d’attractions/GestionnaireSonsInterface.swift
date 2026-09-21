import AppKit

@MainActor
final class GestionnaireSonsInterface {

    static let shared = GestionnaireSonsInterface()

    private var sonEnCours: NSSound?

    private init() {
    }

    @discardableResult
    func jouerCadenasVerrouille() -> TimeInterval {
        jouerSon(
            nom: "CadenasVerrouille",
            extensionFichier: "wav"
        )
    }


    func arreterSonEnCours() {
        sonEnCours?.stop()
        sonEnCours = nil
    }

    @discardableResult
    private func jouerSon(
        nom: String,
        extensionFichier: String
    ) -> TimeInterval {
        arreterSonEnCours()

        guard let adresse = Bundle.main.url(
            forResource: nom,
            withExtension: extensionFichier
        ),
        let son = NSSound(
            contentsOf: adresse,
            byReference: false
        ) else {
            NSSound.beep()
            return 0
        }

        sonEnCours = son
        son.play()

        return son.duration
    }
}

