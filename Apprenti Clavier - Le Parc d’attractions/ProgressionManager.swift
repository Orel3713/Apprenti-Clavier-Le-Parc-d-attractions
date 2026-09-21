//
//  ProgressionManager.swift
//  Apprenti Clavier
//

import Foundation
import Combine

final class ProgressionManager: ObservableObject {

    enum JeuParc: String, CaseIterable, Codable, Identifiable {
        case defiEclair
        case dicteeAudio
        case jeuDesBallons
        case grandeRoue
        case sansFaute
        case sautGagnant

        var id: String { rawValue }

        var nom: String {
            switch self {
            case .defiEclair: return "Le Défi éclair"
            case .dicteeAudio: return "La Dictée audio"
            case .jeuDesBallons: return "Le Jeu des ballons"
            case .grandeRoue: return "La Grande Roue"
            case .sansFaute: return "Le Sans-faute"
            case .sautGagnant: return "Le Saut gagnant"
            }
        }
    }

    struct StatistiquesJeuParc: Codable {
        var niveauxTermines: Set<Int> = []
        var partiesJouees = 0
        var motsCorrects = 0
        var erreursDeFrappe = 0
        var caracteresValides = 0
        var dureeSaisie: TimeInterval = 0
        var meilleureVitesseMPM: Double = 0
    }

    struct StatistiquesParc: Codable {
        var jeux: [String: StatistiquesJeuParc] = [:]

        func statistiques(pour jeu: JeuParc) -> StatistiquesJeuParc {
            jeux[jeu.rawValue] ?? StatistiquesJeuParc()
        }

        var jeuxTermines: Int {
            JeuParc.allCases.filter {
                statistiques(pour: $0).niveauxTermines.contains(10)
            }.count
        }

        var niveauxTermines: Int {
            JeuParc.allCases.reduce(0) {
                $0 + statistiques(pour: $1).niveauxTermines.count
            }
        }

        var partiesJouees: Int {
            JeuParc.allCases.reduce(0) {
                $0 + statistiques(pour: $1).partiesJouees
            }
        }

        var motsCorrects: Int {
            JeuParc.allCases.reduce(0) {
                $0 + statistiques(pour: $1).motsCorrects
            }
        }

        var erreursDeFrappe: Int {
            JeuParc.allCases.reduce(0) {
                $0 + statistiques(pour: $1).erreursDeFrappe
            }
        }

        var caracteresValides: Int {
            JeuParc.allCases.reduce(0) {
                $0 + statistiques(pour: $1).caracteresValides
            }
        }

        var dureeSaisie: TimeInterval {
            JeuParc.allCases.reduce(0) {
                $0 + statistiques(pour: $1).dureeSaisie
            }
        }

        var precisionMoyenne: Double {
            let total = motsCorrects + erreursDeFrappe
            guard total > 0 else { return 0 }
            return Double(motsCorrects) / Double(total) * 100
        }

        var vitesseMoyenneMPM: Double {
            guard dureeSaisie > 0 else { return 0 }
            return (Double(caracteresValides) / 5) / dureeSaisie * 60
        }

        var meilleureVitesseMPM: Double {
            JeuParc.allCases.map {
                statistiques(pour: $0).meilleureVitesseMPM
            }.max() ?? 0
        }
    }

    struct StatistiquesVitesse: Codable {
        var caracteresValides: Int = 0
        var dureeTotale: TimeInterval = 0
        var meilleureVitesseMPM: Double = 0

        var vitesseMoyenneMPM: Double {
            guard dureeTotale > 0 else {
                return 0
            }

            let motsNormalises =
                Double(caracteresValides) / 5.0

            return motsNormalises
                / dureeTotale
                * 60.0
        }
    }

    struct ProfilExportable: Codable {
        let version: Int
        let nom: String
        let leconsTerminees: [Int]
        let statistiquesVitesse: StatistiquesVitesse?
        let statistiquesParc: StatistiquesParc?
        let progressionJeux: [String: Int]?
        let dateExportation: Date
    }

    enum ErreurProfil: LocalizedError {
        case aucunUtilisateurActif
        case fichierInvalide
        case nomInvalide
        case parcoursPedagogiqueIncomplet

        var errorDescription: String? {
            switch self {
            case .aucunUtilisateurActif:
                return "Aucun utilisateur n’est actuellement sélectionné."
            case .fichierInvalide:
                return "Le fichier choisi n’est pas un profil Apprenti Clavier valide."
            case .nomInvalide:
                return "Le profil importé ne contient pas de nom valide."
            case .parcoursPedagogiqueIncomplet:
                return "Ce profil n’a pas encore terminé les quatorze modules d’Apprenti Clavier. Terminez le parcours pédagogique, exportez à nouveau le profil, puis importez-le dans le Parc d’attractions."
            }
        }
    }

    static let shared = ProgressionManager()

    @Published private(set) var profilsUtilisateurs: [String] = []
    @Published private(set) var utilisateurActif: String? = nil
    @Published private(set) var leconsTerminees: [Int] = []
    @Published private(set) var statistiquesVitesse =
        StatistiquesVitesse()
    @Published private(set) var statistiquesParc = StatistiquesParc()

    private let cleProfils = "profilsUtilisateurs"
    private let cleUtilisateurActif = "utilisateurActif"
    private let cleProgressions = "progressionsParUtilisateurV2"
    private let cleStatistiquesVitesse =
        "statistiquesVitesseParUtilisateurV1"
    private let cleStatistiquesParc =
        "statistiquesParcParUtilisateurV1"
    private let cleAncienneProgression = "chapitresTermines"
    private let cleMigrationEffectuee =
        "migrationProgressionParUtilisateurEffectuee"

    private var progressionsParUtilisateur: [String: [Int]] = [:]
    private var statistiquesVitesseParUtilisateur:
        [String: StatistiquesVitesse] = [:]
    private var statistiquesParcParUtilisateur:
        [String: StatistiquesParc] = [:]

    private init() {
        chargerDonnees()
    }

    @discardableResult
    func creerEtActiverUtilisateur(_ nom: String) -> Bool {
        let nomNettoye = nettoyerNom(nom)

        guard !nomNettoye.isEmpty else {
            return false
        }

        if let profilExistant = profilCorrespondant(auNom: nomNettoye) {
            activerUtilisateur(profilExistant)
            return true
        }

        let estPremierProfil = profilsUtilisateurs.isEmpty

        profilsUtilisateurs.append(nomNettoye)
        trierProfils()

        if estPremierProfil
            && !UserDefaults.standard.bool(
                forKey: cleMigrationEffectuee
            ) {
            let ancienneProgression =
                UserDefaults.standard.array(
                    forKey: cleAncienneProgression
                ) as? [Int] ?? []

            progressionsParUtilisateur[nomNettoye] =
                ancienneProgression

            UserDefaults.standard.set(
                true,
                forKey: cleMigrationEffectuee
            )
        } else {
            progressionsParUtilisateur[nomNettoye] = []
        }

        statistiquesVitesseParUtilisateur[nomNettoye] =
            StatistiquesVitesse()
        statistiquesParcParUtilisateur[nomNettoye] =
            StatistiquesParc()

        sauvegarderDonnees()
        activerUtilisateur(nomNettoye)
        return true
    }

    func activerUtilisateur(_ nom: String) {
        guard let profil = profilCorrespondant(auNom: nom) else {
            return
        }

        utilisateurActif = profil
        leconsTerminees =
            progressionsParUtilisateur[profil] ?? []
        statistiquesVitesse =
            statistiquesVitesseParUtilisateur[profil]
            ?? StatistiquesVitesse()
        statistiquesParc =
            statistiquesParcParUtilisateur[profil]
            ?? StatistiquesParc()

        UserDefaults.standard.set(
            profil,
            forKey: cleUtilisateurActif
        )
    }

    func fermerSessionUtilisateur() {
        utilisateurActif = nil
        leconsTerminees = []
        statistiquesVitesse = StatistiquesVitesse()
        statistiquesParc = StatistiquesParc()

        UserDefaults.standard.removeObject(
            forKey: cleUtilisateurActif
        )
    }

    @discardableResult
    func supprimerUtilisateurActif() -> String? {
        guard let utilisateur = utilisateurActif else {
            return nil
        }

        profilsUtilisateurs.removeAll {
            $0 == utilisateur
        }

        progressionsParUtilisateur.removeValue(
            forKey: utilisateur
        )
        statistiquesVitesseParUtilisateur.removeValue(
            forKey: utilisateur
        )
        statistiquesParcParUtilisateur.removeValue(
            forKey: utilisateur
        )

        utilisateurActif = nil
        leconsTerminees = []
        statistiquesVitesse = StatistiquesVitesse()
        statistiquesParc = StatistiquesParc()

        UserDefaults.standard.removeObject(
            forKey: cleUtilisateurActif
        )

        sauvegarderDonnees()
        return utilisateur
    }

    func donneesDuProfilActif() throws -> Data {
        guard let utilisateur = utilisateurActif else {
            throw ErreurProfil.aucunUtilisateurActif
        }

        let profil = ProfilExportable(
            version: 3,
            nom: utilisateur,
            leconsTerminees:
                progressionsParUtilisateur[utilisateur] ?? [],
            statistiquesVitesse:
                statistiquesVitesseParUtilisateur[utilisateur],
            statistiquesParc:
                statistiquesParcParUtilisateur[utilisateur]
                ?? StatistiquesParc(),
            progressionJeux:
                progressionJeuxPourExport(),
            dateExportation: Date()
        )

        let encodeur = JSONEncoder()
        encodeur.outputFormatting = [
            .prettyPrinted,
            .sortedKeys
        ]
        encodeur.dateEncodingStrategy = .iso8601

        return try encodeur.encode(profil)
    }

    @discardableResult
    func importerProfil(depuis donnees: Data) throws -> String {
        let decodeur = JSONDecoder()
        decodeur.dateDecodingStrategy = .iso8601

        guard let profil = try? decodeur.decode(
            ProfilExportable.self,
            from: donnees
        ) else {
            throw ErreurProfil.fichierInvalide
        }

        let nomNettoye = nettoyerNom(profil.nom)

        guard !nomNettoye.isEmpty else {
            throw ErreurProfil.nomInvalide
        }

        let progressionImportee = Set(
            profil.leconsTerminees.filter { $0 > 0 }
        )

        // Le parcours pédagogique actuel utilise les identifiants 1 à 82.
        // Ils doivent tous être présents pour que le profil serve de billet d’entrée.
        let leconsRequises = Set(1...82)
        guard leconsRequises.isSubset(of: progressionImportee) else {
            throw ErreurProfil.parcoursPedagogiqueIncomplet
        }

        let nomFinal = nomDisponible(
            aPartirDe: nomNettoye
        )

        let progressionNettoyee = Array(
            Set(
                profil.leconsTerminees.filter {
                    $0 > 0
                }
            )
        ).sorted()

        profilsUtilisateurs.append(nomFinal)
        trierProfils()

        progressionsParUtilisateur[nomFinal] =
            progressionNettoyee
        statistiquesVitesseParUtilisateur[nomFinal] =
            profil.statistiquesVitesse
            ?? StatistiquesVitesse()
        statistiquesParcParUtilisateur[nomFinal] =
            profil.statistiquesParc
            ?? StatistiquesParc()

        restaurerProgressionJeux(
            profil.progressionJeux,
            pour: nomFinal
        )

        sauvegarderDonnees()

        return nomFinal
    }

    private var clesProgressionJeux: [JeuParc: String] {
        [
            .defiEclair: "progressionDefiEclairParUtilisateurV1",
            .dicteeAudio: "progressionDicteeAudioParUtilisateurV1",
            .jeuDesBallons: "progressionJeuDesBallonsParUtilisateurV1",
            .grandeRoue: "progressionGrandeRoueParUtilisateurV1",
            .sansFaute: "progressionSansFauteParUtilisateurV1",
            .sautGagnant: "progressionSautGagnantParUtilisateurV2"
        ]
    }

    private func progressionJeuxPourExport() -> [String: Int] {
        guard utilisateurActif != nil else { return [:] }

        var resultat: [String: Int] = [:]

        for jeu in JeuParc.allCases {
            guard let cle = clesProgressionJeux[jeu] else { continue }
            resultat[jeu.rawValue] = niveauMaximumDebloqueJeu(cle: cle)
        }

        return resultat
    }

    private func restaurerProgressionJeux(
        _ progressionImportee: [String: Int]?,
        pour utilisateur: String
    ) {
        guard let progressionImportee else { return }

        let defaults = UserDefaults.standard

        for jeu in JeuParc.allCases {
            guard
                let cle = clesProgressionJeux[jeu],
                let niveau = progressionImportee[jeu.rawValue]
            else {
                continue
            }

            var dictionnaire = defaults.dictionary(forKey: cle) ?? [:]
            dictionnaire[utilisateur] = max(1, min(10, niveau))
            defaults.set(dictionnaire, forKey: cle)
        }
    }

    var profilActifEstAdmisAuParc: Bool {
        Set(1...82).isSubset(of: Set(leconsTerminees))
    }

    // MARK: - Progression des jeux du Parc

    /// Lit le niveau maximal déverrouillé pour le profil actif. Les jeux les plus
    /// anciens utilisaient parfois une clé globale : sa valeur est migrée une seule
    /// fois vers le profil actif afin de conserver la progression existante.
    func niveauMaximumDebloqueJeu(
        cle: String,
        cleHistorique: String? = nil
    ) -> Int {
        guard let utilisateur = utilisateurActif else { return 1 }

        let defaults = UserDefaults.standard
        var dictionnaire = defaults.dictionary(forKey: cle) ?? [:]

        if let valeur = dictionnaire[utilisateur] as? Int {
            return max(1, min(10, valeur))
        }

        if let cleHistorique, defaults.object(forKey: cleHistorique) != nil {
            let valeurHistorique = max(1, min(10, defaults.integer(forKey: cleHistorique)))
            dictionnaire[utilisateur] = valeurHistorique
            defaults.set(dictionnaire, forKey: cle)
            defaults.removeObject(forKey: cleHistorique)
            return valeurHistorique
        }

        return 1
    }

    func enregistrerNiveauMaximumDebloqueJeu(
        _ niveau: Int,
        cle: String
    ) {
        guard let utilisateur = utilisateurActif else { return }

        let defaults = UserDefaults.standard
        var dictionnaire = defaults.dictionary(forKey: cle) ?? [:]
        let precedent = dictionnaire[utilisateur] as? Int ?? 1
        dictionnaire[utilisateur] = max(precedent, max(1, min(10, niveau)))
        defaults.set(dictionnaire, forKey: cle)
    }

    func enregistrerPartie(
        jeu: JeuParc,
        niveau: Int,
        reussie: Bool,
        motsCorrects: Int,
        erreursDeFrappe: Int,
        caracteresValides: Int,
        dureeSaisie: TimeInterval
    ) {
        guard let utilisateur = utilisateurActif else { return }

        var ensemble = statistiquesParcParUtilisateur[utilisateur]
            ?? StatistiquesParc()
        var jeuStats = ensemble.statistiques(pour: jeu)
        jeuStats.partiesJouees += 1
        jeuStats.motsCorrects += max(0, motsCorrects)
        jeuStats.erreursDeFrappe += max(0, erreursDeFrappe)
        jeuStats.caracteresValides += max(0, caracteresValides)

        let duree = max(0, dureeSaisie)
        jeuStats.dureeSaisie += duree
        if duree > 0, caracteresValides > 0 {
            let vitesse = (Double(caracteresValides) / 5) / duree * 60
            jeuStats.meilleureVitesseMPM = max(
                jeuStats.meilleureVitesseMPM,
                vitesse
            )
        }

        if reussie, (1...10).contains(niveau) {
            jeuStats.niveauxTermines.insert(niveau)
        }

        ensemble.jeux[jeu.rawValue] = jeuStats
        statistiquesParcParUtilisateur[utilisateur] = ensemble
        statistiquesParc = ensemble
        sauvegarderDonnees()
    }

    static func nombreDeMots(dans texte: String) -> Int {
        texte.split { !$0.isLetter && !$0.isNumber }.count
    }

    func reinitialiserProgression() {
        guard let utilisateur = utilisateurActif else { return }

        let defaults = UserDefaults.standard
        let clesJeux = [
            "progressionDefiEclairParUtilisateurV1",
            "progressionDicteeAudioParUtilisateurV1",
            "progressionJeuDesBallonsParUtilisateurV1",
            "progressionGrandeRoueParUtilisateurV1",
            "progressionSansFauteParUtilisateurV1",
            "progressionSautGagnantParUtilisateurV1",
            "progressionSautGagnantParUtilisateurV2"
        ]

        for cle in clesJeux {
            var dictionnaire = defaults.dictionary(forKey: cle) ?? [:]
            dictionnaire.removeValue(forKey: utilisateur)
            defaults.set(dictionnaire, forKey: cle)
        }

        // Nettoyage des anciennes clés globales des deux jeux qui en utilisaient
        // encore. Elles ne doivent jamais ressusciter une progression réinitialisée.
        defaults.removeObject(forKey: "grandeRoueNiveauMaximumDebloque")
        defaults.removeObject(forKey: "sansFauteNiveauMaximumDebloqueV2")

        statistiquesParcParUtilisateur[utilisateur] = StatistiquesParc()
        statistiquesParc = StatistiquesParc()
        sauvegarderDonnees()
    }

    private func chargerDonnees() {
        let defaults = UserDefaults.standard

        profilsUtilisateurs =
            defaults.stringArray(forKey: cleProfils) ?? []

        if let donnees = defaults.data(
            forKey: cleProgressions
        ) {
            do {
                progressionsParUtilisateur =
                    try JSONDecoder().decode(
                        [String: [Int]].self,
                        from: donnees
                    )
            } catch {
                progressionsParUtilisateur = [:]
            }
        }

        if let donneesVitesse = defaults.data(
            forKey: cleStatistiquesVitesse
        ) {
            do {
                statistiquesVitesseParUtilisateur =
                    try JSONDecoder().decode(
                        [String: StatistiquesVitesse].self,
                        from: donneesVitesse
                    )
            } catch {
                statistiquesVitesseParUtilisateur = [:]
            }
        }

        if let donneesParc = defaults.data(forKey: cleStatistiquesParc) {
            do {
                statistiquesParcParUtilisateur = try JSONDecoder().decode(
                    [String: StatistiquesParc].self,
                    from: donneesParc
                )
            } catch {
                statistiquesParcParUtilisateur = [:]
            }
        }

        // À chaque nouveau lancement, l’application revient
        // sur la page d’accueil afin que la personne choisisse
        // explicitement le profil qu’elle souhaite utiliser.
        // Les profils et leurs progressions restent enregistrés.
        utilisateurActif = nil
        leconsTerminees = []
        statistiquesVitesse = StatistiquesVitesse()
        statistiquesParc = StatistiquesParc()

        defaults.removeObject(
            forKey: cleUtilisateurActif
        )
    }

    private func nettoyerNom(_ nom: String) -> String {
        nom.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private func profilCorrespondant(
        auNom nom: String
    ) -> String? {
        let nomNettoye = nettoyerNom(nom)

        return profilsUtilisateurs.first { profil in
            profil.compare(
                nomNettoye,
                options: [
                    .caseInsensitive,
                    .diacriticInsensitive
                ]
            ) == .orderedSame
        }
    }

    private func nomDisponible(
        aPartirDe nom: String
    ) -> String {
        if profilCorrespondant(auNom: nom) == nil {
            return nom
        }

        var numero = 2

        while true {
            let proposition =
                "\(nom) importé \(numero)"

            if profilCorrespondant(
                auNom: proposition
            ) == nil {
                return proposition
            }

            numero += 1
        }
    }

    private func trierProfils() {
        profilsUtilisateurs.sort {
            $0.localizedCaseInsensitiveCompare($1)
                == .orderedAscending
        }
    }

    private func sauvegarderDonnees() {
        let defaults = UserDefaults.standard

        defaults.set(
            profilsUtilisateurs,
            forKey: cleProfils
        )

        do {
            let donnees = try JSONEncoder().encode(
                progressionsParUtilisateur
            )

            defaults.set(
                donnees,
                forKey: cleProgressions
            )

            let donneesVitesse = try JSONEncoder().encode(
                statistiquesVitesseParUtilisateur
            )

            defaults.set(
                donneesVitesse,
                forKey: cleStatistiquesVitesse
            )

            let donneesParc = try JSONEncoder().encode(
                statistiquesParcParUtilisateur
            )
            defaults.set(donneesParc, forKey: cleStatistiquesParc)
        } catch {
            print(
                "Erreur de sauvegarde des données : \(error)"
            )
        }
    }
}

