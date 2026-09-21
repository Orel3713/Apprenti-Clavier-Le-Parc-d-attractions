import SwiftUI
import AppKit
import AVFoundation

struct SansFauteView: View {
    let retourParc: () -> Void

    @State private var ecran: EcranSansFaute = .niveaux
    @State private var niveauSelectionne = 1
    @State private var niveauMaximumDebloque = 1
    private let cleProgressionJeu = "progressionSansFauteParUtilisateurV1"

    @State private var compteARebours: Int?
    @State private var partieEnCours = false
    @State private var partieTerminee = false
    @State private var saisie = ""
    @State private var motsPartie: [String] = []
    @State private var indexMot = 0
    @State private var serieCourante = 0
    @State private var meilleureSerie = 0
    @State private var motsReussis = 0
    @State private var erreurs = 0
    @State private var dateDebut: Date?
    @State private var dureeFinale: TimeInterval = 0
    @State private var secondesRestantes = 60
    @State private var minuterie: Timer?
    @State private var niveauReussi = false
    @State private var afficherCommentJouer = false
    @State private var textesCorrects: [String] = []

    @AccessibilityFocusState private var titreEnFocus: Bool
    @AccessibilityFocusState private var zoneNeutreEnFocus: Bool
    @AccessibilityFocusState private var resultatEnFocus: Bool

    private let configurations = ConfigurationSansFaute.toutes

    private var configuration: ConfigurationSansFaute {
        configurations[max(0, min(niveauSelectionne - 1, configurations.count - 1))]
    }

    private var motActuel: String {
        guard !motsPartie.isEmpty else { return configuration.mots.first ?? "chat" }
        return motsPartie[indexMot % motsPartie.count]
    }

    var body: some View {
        ZStack {
            DecorSansFaute()
                .accessibilityHidden(true)

            Group {
                switch ecran {
                case .niveaux: ecranNiveaux
                case .objectif: ecranObjectif
                case .partie: ecranPartie
                }
            }
        }
        .frame(minWidth: 960, minHeight: 680)
        .background(
            CaptureClavierSansFaute(
                actif: ecran == .partie && !partieTerminee,
                caractereSaisi: traiterCaractere,
                commandePressee: reannoncerMot,
                echapPresse: gererEchap
            )
            .frame(width: 0, height: 0)
        )
        .onExitCommand { gererEchap() }
        .onDisappear { arreterPartie() }
        .sheet(isPresented: $afficherCommentJouer) {
            CommentJouerSansFauteView { afficherCommentJouer = false }
        }
    }

    private var ecranNiveaux: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Button("Retour au parc d’attractions") { retourParc() }
                    Spacer()
                }

                HStack(spacing: 12) {
                    Image(systemName: "target")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(.purple)
                        .accessibilityHidden(true)
                    Text("Sans faute")
                        .font(.largeTitle).bold()
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityFocused($titreEnFocus)
                }

                Text("Enchaînez sans erreur le nombre de mots demandé dans chaque niveau pour passer au suivant.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 760)

                Button("Comment jouer") { afficherCommentJouer = true }

                VStack(spacing: 12) {
                    ForEach(configurations) { item in
                        boutonNiveau(item)
                    }
                }
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }
            .padding(36)
        }
        .onAppear {
            niveauMaximumDebloque = ProgressionManager.shared.niveauMaximumDebloqueJeu(
                cle: cleProgressionJeu,
                cleHistorique: "sansFauteNiveauMaximumDebloqueV2"
            )
            placerFocusTitre()
        }
    }

    private func boutonNiveau(_ item: ConfigurationSansFaute) -> some View {
        let verrouille = item.numero > niveauMaximumDebloque
        return Button {
            if verrouille {
                _ = GestionnaireSonsInterface.shared.jouerCadenasVerrouille()
            } else {
                niveauSelectionne = item.numero
                ecran = .objectif
                placerFocusTitre()
            }
        } label: {
            ZStack {
                VStack(spacing: 3) {
                    Text("Niveau \(item.numero)").font(.headline)
                    Text(item.titre).font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

                HStack {
                    Spacer()
                    Image(systemName: verrouille ? "lock.fill" : "chevron.right.circle.fill")
                        .foregroundStyle(verrouille ? .red : .accentColor)
                        .accessibilityHidden(true)
                }
            }
            .padding(14)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(verrouille ? "Niveau \(item.numero), \(item.titre), verrouillé" : "Niveau \(item.numero), \(item.titre)")
        .accessibilityHint(verrouille ? "Terminez d’abord le niveau précédent." : "Ouvre ce niveau.")
    }

    private var phraseNiveau: String {
        switch niveauSelectionne {
        case 1: return "Gardez le cap à travers les véhicules et les transports."
        case 2: return "Traversez la nature sans laisser passer la moindre erreur."
        case 3: return "Enchaînez les prénoms, chacun commençant par une majuscule."
        case 4: return "Parcourez la maison, pièce après pièce, sans faute."
        case 5: return "Passez d’un métier à l’autre en gardant une série parfaite."
        case 6: return "Enchaînez vêtements et accessoires sans trébucher sur une lettre."
        case 7: return "Parcourez le corps humain en conservant votre série."
        case 8: return "Maniez les mots du bricolage avec précision."
        case 9: return "Plongez parmi les animaux marins sans faire d’erreur."
        case 10: return "Terminez au jardin en cultivant une série parfaite."
        default: return "Enchaînez les mots sans erreur."
        }
    }

    private var ecranObjectif: some View {
        VStack(spacing: 24) {
            Text("Niveau \(niveauSelectionne)")
                .font(.largeTitle).bold()
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($titreEnFocus)
            Text(configuration.titre).font(.title).bold()
            Text("Objectif").font(.title2).bold()
            Text(phraseNiveau)
                .font(.title2)
                .multilineTextAlignment(.center)
            Text("Réussissez \(configuration.objectif) mots consécutifs sans erreur avant la fin du temps. Vous disposez de \(configuration.duree) secondes.")
                .multilineTextAlignment(.center)
                .frame(maxWidth: 720)
            if let consigne = configuration.consigneSupplementaire {
                Text(consigne)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 720)
            }
            Button("Commencer") { demarrerPartie() }
                .keyboardShortcut(.defaultAction)
        }
        .padding(40)
        .onAppear { placerFocusTitre() }
    }

    private var ecranPartie: some View {
        ZStack(alignment: .trailing) {
            VStack(spacing: 22) {
                if partieTerminee {
                    resultatPartie
                } else {
                    HStack {
                        Text("Série : \(serieCourante) / \(configuration.objectif)").font(.headline)
                        Spacer()
                        Text("Temps : \(secondesRestantes) s").font(.headline)
                        Spacer()
                        Text("Erreurs : \(erreurs)").font(.headline)
                    }
                    .padding(.horizontal, 30)
                    .accessibilityHidden(true)

                    Spacer()

                    if let compteARebours {
                        Text("\(compteARebours)")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .accessibilityHidden(true)
                    } else {
                        Image(systemName: "target")
                            .font(.system(size: 150, weight: .thin))
                            .foregroundStyle(.purple.opacity(0.8))
                            .accessibilityHidden(true)

                        Text("Mot annoncé par VoiceOver")
                            .font(.title2).bold()
                            .accessibilityHidden(true)
                        Text("Tapez directement au clavier. Commande permet de réécouter le mot.")
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }

                    Spacer()
                }
            }
            .padding(28)

            if !partieTerminee {
                PointFocusSansFauteSilencieux()
                    .frame(width: 2, height: 2)
                    .accessibilityFocused($zoneNeutreEnFocus)
                    .padding(.trailing, 2)
            }
        }
    }

    private var messageReussiteResultat: String {
        guard niveauReussi else { return "" }

        if niveauSelectionne < 10 {
            return "Bravo, vous avez réussi ce niveau. Le niveau \(niveauSelectionne + 1) est maintenant déverrouillé."
        } else {
            return "Bravo, vous avez terminé tous les niveaux de Sans faute !"
        }
    }

    private var resultatPartie: some View {
        Button {
            ecran = .niveaux
            placerFocusTitre()
        } label: {
            VStack(spacing: 20) {
                Text(niveauReussi ? "Niveau réussi !" : "Temps écoulé").font(.largeTitle).bold()
                if niveauReussi {
                    Text(messageReussiteResultat)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                }
                Text(niveauReussi ? "Série parfaite : \(configuration.objectif) mots." : "Votre meilleure série : \(meilleureSerie) mot\(meilleureSerie > 1 ? "s" : "").").font(.title2)
                Text("Mots réussis au total : \(motsReussis). Erreurs : \(erreurs).")
                    .font(.headline)
                Text("Meilleure série : \(meilleureSerie). Vitesse moyenne : \(vitesseMoyenne) mots par minute.")
                    .font(.headline)
                Text("Durée : \(dureeFormatee).")
                    .font(.headline)
                Text("Appuyez sur Entrée pour revenir à la liste des niveaux.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(resumeAccessible)
        .accessibilityHint("Appuyez sur Entrée pour revenir à la liste des niveaux.")
        .accessibilityFocused($resultatEnFocus)
        .keyboardShortcut(.defaultAction)
        .onAppear { placerFocusResultat() }
    }

    private var vitesseMoyenne: Int {
        guard dureeFinale > 0 else { return 0 }
        return Int((Double(motsReussis) / dureeFinale * 60).rounded())
    }

    private var dureeFormatee: String {
        let secondes = max(0, Int(dureeFinale.rounded()))
        let minutes = secondes / 60
        let reste = secondes % 60
        return minutes > 0 ? "\(minutes) minute\(minutes > 1 ? "s" : "") et \(reste) seconde\(reste > 1 ? "s" : "")" : "\(reste) seconde\(reste > 1 ? "s" : "")"
    }

    private var resumeAccessible: String {
        if niveauReussi {
            return "\(messageReussiteResultat) Série parfaite : \(configuration.objectif) mots. Mots réussis au total : \(motsReussis). Erreurs : \(erreurs). Meilleure série : \(meilleureSerie). Vitesse moyenne : \(vitesseMoyenne) mots par minute. Durée : \(dureeFormatee). Appuyez sur Entrée pour revenir à la liste des niveaux."
        }
        return "Temps écoulé. Meilleure série : \(meilleureSerie) sur \(configuration.objectif). Mots réussis au total : \(motsReussis). Erreurs : \(erreurs). Appuyez sur Entrée pour revenir à la liste des niveaux."
    }

    private func demarrerPartie() {
        arreterPartie()
        titreEnFocus = false
        resultatEnFocus = false
        ecran = .partie
        compteARebours = 3
        partieEnCours = false
        partieTerminee = false
        saisie = ""
        serieCourante = 0
        meilleureSerie = 0
        motsReussis = 0
        erreurs = 0
        dureeFinale = 0
        secondesRestantes = configuration.duree
        niveauReussi = false
        textesCorrects = []
        motsPartie = configuration.mots.shuffled()
        indexMot = 0
        placerFocusZoneNeutre()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            guard ecran == .partie, !partieTerminee else { return }
            VoiceOverAnnouncer.annoncerTexte("3")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.85) {
            guard ecran == .partie, !partieTerminee else { return }
            compteARebours = 2
            VoiceOverAnnouncer.annoncerTexte("2")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.85) {
            guard ecran == .partie, !partieTerminee else { return }
            compteARebours = 1
            VoiceOverAnnouncer.annoncerTexte("1")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            guard ecran == .partie, !partieTerminee else { return }
            compteARebours = nil
            partieEnCours = true
            dateDebut = Date()
            demarrerMinuterie()
            annoncerMotActuel(apres: 0.35)
        }
    }

    private func traiterCaractere(_ caractere: String) {
        guard partieEnCours, !partieTerminee, compteARebours == nil else { return }
        let attendu = motActuel.precomposedStringWithCanonicalMapping
        let tentative = (saisie + caractere).precomposedStringWithCanonicalMapping

        if attendu.hasPrefix(tentative) {
            saisie = tentative
            if tentative == attendu { motReussi() }
        } else {
            erreurDeFrappe()
        }
    }

    private func motReussi() {
        motsReussis += 1
        textesCorrects.append(motActuel)
        serieCourante += 1
        meilleureSerie = max(meilleureSerie, serieCourante)
        saisie = ""

        if serieCourante >= configuration.objectif {
            terminerPartie(reussi: true)
            return
        }

        avancerMot()
        VoiceOverAnnouncer.annoncerTexte("\(serieCourante) sur \(configuration.objectif). \(annonceMot(motActuel))", apres: 0.35)
    }

    private func erreurDeFrappe() {
        erreurs += 1
        meilleureSerie = max(meilleureSerie, serieCourante)
        serieCourante = 0
        saisie = ""
        SonSansFaute.shared.jouerErreur()
        secondesRestantes = max(0, configuration.duree - (erreurs * 5))

        if secondesRestantes == 0 {
            terminerPartie(reussi: false)
            return
        }

        remelangerApresErreur()
        VoiceOverAnnouncer.annoncerTexte("\(secondesRestantes) secondes restantes. \(annonceMot(motActuel))", apres: 0.65)
    }

    private func avancerMot() {
        let precedent = motActuel
        indexMot += 1
        if indexMot >= motsPartie.count {
            motsPartie = configuration.mots.shuffled()
            indexMot = 0
        }
        if motsPartie.count > 1, motActuel == precedent {
            let suivant = (indexMot + 1) % motsPartie.count
            motsPartie.swapAt(indexMot, suivant)
        }
    }

    private func remelangerApresErreur() {
        let precedent = motActuel
        motsPartie = configuration.mots.shuffled()
        indexMot = 0
        if motsPartie.count > 1, motsPartie.first == precedent {
            motsPartie.swapAt(0, 1)
        }
    }

    private func reannoncerMot() {
        guard partieEnCours, !partieTerminee, compteARebours == nil else { return }
        VoiceOverAnnouncer.annoncerTexte(annonceMot(motActuel))
    }

    private func annoncerMotActuel(apres delai: Double) {
        VoiceOverAnnouncer.annoncerTexte(annonceMot(motActuel), apres: delai)
    }

    private func annonceMot(_ mot: String) -> String {
        mot
    }

    private func demarrerMinuterie() {
        minuterie?.invalidate()
        minuterie = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard partieEnCours, !partieTerminee else { return }
            if secondesRestantes > 1 {
                secondesRestantes -= 1
            } else {
                secondesRestantes = 0
                terminerPartie(reussi: false)
            }
        }
    }

    private func terminerPartie(reussi: Bool) {
        partieEnCours = false
        partieTerminee = true
        niveauReussi = reussi
        minuterie?.invalidate()
        minuterie = nil
        if let dateDebut { dureeFinale = Date().timeIntervalSince(dateDebut) }
        ProgressionManager.shared.enregistrerPartie(
            jeu: .sansFaute,
            niveau: niveauSelectionne,
            reussie: reussi,
            motsCorrects: textesCorrects.reduce(0) { $0 + ProgressionManager.nombreDeMots(dans: $1) },
            erreursDeFrappe: erreurs,
            caracteresValides: textesCorrects.reduce(0) { $0 + $1.count },
            dureeSaisie: dureeFinale
        )
        if reussi, niveauSelectionne < 10 {
            niveauMaximumDebloque = max(niveauMaximumDebloque, niveauSelectionne + 1)
            ProgressionManager.shared.enregistrerNiveauMaximumDebloqueJeu(
                niveauMaximumDebloque,
                cle: cleProgressionJeu
            )
        }
        zoneNeutreEnFocus = false
        placerFocusResultat()
    }

    private func arreterPartie() {
        partieEnCours = false
        compteARebours = nil
        dateDebut = nil
        minuterie?.invalidate()
        minuterie = nil
        SonSansFaute.shared.arreter()
    }

    private func gererEchap() {
        switch ecran {
        case .niveaux:
            retourParc()
        case .objectif:
            ecran = .niveaux
            placerFocusTitre()
        case .partie:
            if compteARebours != nil {
                arreterPartie()
                ecran = .objectif
                placerFocusTitre()
            }
            // Une fois la partie commencée, Échap est volontairement ignorée.
        }
    }

    private func placerFocusZoneNeutre() {
        titreEnFocus = false
        resultatEnFocus = false
        zoneNeutreEnFocus = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            guard ecran == .partie, !partieTerminee else { return }
            zoneNeutreEnFocus = true
        }
    }

    private func placerFocusResultat() {
        zoneNeutreEnFocus = false
        titreEnFocus = false
        resultatEnFocus = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            guard ecran == .partie, partieTerminee else { return }
            resultatEnFocus = true
        }
    }

    private func placerFocusTitre() {
        zoneNeutreEnFocus = false
        resultatEnFocus = false
        titreEnFocus = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) { titreEnFocus = true }
    }
}

private enum EcranSansFaute { case niveaux, objectif, partie }

private struct ConfigurationSansFaute: Identifiable {
    let numero: Int
    let titre: String
    let objectif: Int
    let duree: Int
    let mots: [String]
    let consigneSupplementaire: String?
    var id: Int { numero }

    static let toutes: [ConfigurationSansFaute] = [
        .init(numero: 1, titre: "Véhicules et transports", objectif: 8, duree: 60, mots: ["voiture","camion","autobus","tracteur","hélicoptère","locomotive","ambulance","caravane","remorque","scooter","trottinette","bicyclette","métro","tramway","fusée","navette","limousine","décapotable","téléphérique","corbillard"], consigneSupplementaire: nil),
        .init(numero: 2, titre: "Nature", objectif: 9, duree: 60, mots: ["algue","forêt","étang","buisson","montagne","champignon","rivière","cascade","prairie","falaise","rocher","vallée","colline","fougère","sentier","volcan","branche","racine","pétale","mousse"], consigneSupplementaire: nil),
        .init(numero: 3, titre: "Prénoms", objectif: 10, duree: 60, mots: ["Antoine","Aurélie","Baptiste","Caroline","Émilie","Fabien","Christophe","Isabelle","Raymond","Juliette","Laurent","Mélanie","Nicolas","Pauline","Guillaume","Sébastien","Stéphanie","Théo","Valérie","Xavier"], consigneSupplementaire: "Les prénoms commencent par une majuscule. VoiceOver annonce uniquement le prénom."),
        .init(numero: 4, titre: "La maison", objectif: 10, duree: 60, mots: ["canapé","fauteuil","armoire","commode","matelas","vaisselle","couverture","baignoire","douche","lavabo","miroir","serviette","casserole","assiette","fourchette","couteau","placard","réfrigérateur","aspirateur","poubelle"], consigneSupplementaire: nil),
        .init(numero: 5, titre: "Métiers", objectif: 11, duree: 60, mots: ["boulanger","coiffeur","chirurgien","pharmacien","facteur","pompier","policier","serveur","cuisinier","jardinier","mécanicien","électricien","plombier","architecte","animateur","journaliste","photographe","professeur","libraire","footballeur"], consigneSupplementaire: nil),
        .init(numero: 6, titre: "Vêtements et accessoires", objectif: 11, duree: 60, mots: ["pantalon","chemise","chaussette","écharpe","bonnet","casquette","manteau","blouson","bottine","maillot","chaussure","gourmette","ceinture","cravate","bracelet","collier","sandale","culotte","salopette","imperméable"], consigneSupplementaire: nil),
        .init(numero: 7, titre: "Corps humain", objectif: 10, duree: 60, mots: ["épaule","cheville","poignet","coude","genou","menton","poitrine","ventre","hanche","cuisse","mollet","talon","oreille","sourcil","narine","langue","nombril","squelette","colonne","cerveau"], consigneSupplementaire: nil),
        .init(numero: 8, titre: "Outils et bricolage", objectif: 10, duree: 60, mots: ["marteau","tournevis","perceuse","pince","scie","clou","vis","écrou","boulon","niveau","échelle","pinceau","rouleau","mètre","rabot","lime","étau","truelle","spatule","agrafeuse"], consigneSupplementaire: nil),
        .init(numero: 9, titre: "Animaux marins", objectif: 11, duree: 60, mots: ["dauphin","baleine","requin","méduse","pieuvre","homard","crabe","crevette","sardine","morue","thon","saumon","poulpe","orque","raie","phoque","oursin","moule","langouste","corail"], consigneSupplementaire: nil),
        .init(numero: 10, titre: "Jardinage", objectif: 12, duree: 60, mots: ["légume","potager","arrosoir","brouette","récolte","pelle","serre","sécateur","tuyau","plantation","engrais","graine","pelouse","plante","arbuste","rosier","tulipe","jonquille","marguerite","tournesol"], consigneSupplementaire: nil)
    ]
}

private struct CommentJouerSansFauteView: View {
    let fermer: () -> Void
    @AccessibilityFocusState private var titreEnFocus: Bool
    @State private var contenuAccessible = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Comment jouer")
                    .font(.largeTitle).bold()
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($titreEnFocus)
                Text("Dans ce jeu, un mot est annoncé par VoiceOver. Tapez-le directement au clavier : aucun mot n’est affiché et aucun champ de saisie n’est utilisé.")
                Text("Chaque mot correctement tapé fait avancer votre série. Le but est d’enchaîner le nombre de mots demandé par le niveau.")
                Text("Dès la première mauvaise touche, le son de mauvaise réponse retentit et votre série s’arrête. Il n’est pas possible d’effacer ou de corriger la frappe.")
                Text("Après une erreur, les mots sont remélangés afin que la nouvelle série ne reproduise pas la précédente.")
                Text("Chaque niveau commence avec 60 secondes. Après une erreur, la nouvelle tentative dispose de 5 secondes de moins.")
                Text("Appuyez sur la touche Commande pour réentendre le mot en cours.")
                Button("Fermer") { fermer() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(36)
            .frame(maxWidth: 760, alignment: .leading)
        }
        .frame(minWidth: 720, minHeight: 520)
        .accessibilityHidden(!contenuAccessible)
        .onAppear {
            // La feuille macOS peut placer son focus initial sur le premier bouton.
            // On attend que la feuille soit complètement présentée, puis on force
            // explicitement le focus VoiceOver sur le titre de « Comment jouer ».
            contenuAccessible = false
            titreEnFocus = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                contenuAccessible = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    titreEnFocus = true
                }
            }
        }
    }
}

private struct DecorSansFaute: View {
    @Environment(\.colorScheme) private var apparence
    var body: some View {
        ZStack {
            LinearGradient(
                colors: apparence == .dark
                    ? [Color(red: 0.08, green: 0.04, blue: 0.16), Color(red: 0.18, green: 0.08, blue: 0.24)]
                    : [Color(red: 0.92, green: 0.86, blue: 1.0), Color(red: 1.0, green: 0.94, blue: 0.78)],
                startPoint: .top, endPoint: .bottom
            )
            VStack {
                HStack(spacing: 22) {
                    ForEach(0..<12, id: \.self) { i in
                        TriangleSansFaute()
                            .fill(i.isMultiple(of: 2) ? Color.purple.opacity(0.35) : Color.orange.opacity(0.35))
                            .frame(width: 34, height: 28)
                    }
                }
                Spacer()
                HStack {
                    Image(systemName: "target").font(.system(size: 250, weight: .ultraLight)).opacity(0.10)
                    Spacer()
                    Image(systemName: "target").font(.system(size: 200, weight: .ultraLight)).opacity(0.08)
                }
                .padding(50)
            }
        }
        .ignoresSafeArea()
    }
}

private struct TriangleSansFaute: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path(); p.move(to: CGPoint(x: rect.midX, y: rect.maxY)); p.addLine(to: CGPoint(x: rect.minX, y: rect.minY)); p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY)); p.closeSubpath(); return p
    }
}

private struct PointFocusSansFauteSilencieux: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let vue = NSView(frame: .zero)
        vue.setAccessibilityElement(true)
        vue.setAccessibilityRole(.unknown)
        vue.setAccessibilityLabel(nil)
        return vue
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

private struct CaptureClavierSansFaute: NSViewRepresentable {
    let actif: Bool
    let caractereSaisi: (String) -> Void
    let commandePressee: () -> Void
    let echapPresse: () -> Void

    func makeCoordinator() -> Coordinateur { Coordinateur() }
    func makeNSView(context: Context) -> VueCaptureSansFaute {
        let vue = VueCaptureSansFaute()
        vue.caractereSaisi = caractereSaisi
        vue.echapPresse = echapPresse
        context.coordinator.mettreAJour(actif: actif, commandePressee: commandePressee)
        context.coordinator.installer()
        return vue
    }
    func updateNSView(_ vue: VueCaptureSansFaute, context: Context) {
        vue.caractereSaisi = caractereSaisi
        vue.echapPresse = echapPresse
        context.coordinator.mettreAJour(actif: actif, commandePressee: commandePressee)
        DispatchQueue.main.async {
            guard let fenetre = vue.window else { return }
            if actif, fenetre.firstResponder !== vue { fenetre.makeFirstResponder(vue) }
            else if !actif, fenetre.firstResponder === vue { fenetre.makeFirstResponder(nil) }
        }
    }
    static func dismantleNSView(_ nsView: VueCaptureSansFaute, coordinator: Coordinateur) { coordinator.retirer() }

    final class Coordinateur {
        private var moniteur: Any?
        private var actif = false
        private var action: (() -> Void)?
        private var commandeDejaPressee = false
        func mettreAJour(actif: Bool, commandePressee: @escaping () -> Void) {
            self.actif = actif; self.action = commandePressee
            if !actif { commandeDejaPressee = false }
        }
        func installer() {
            guard moniteur == nil else { return }
            moniteur = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
                guard let self, self.actif else { return event }
                let active = event.modifierFlags.contains(.command)
                if active, !commandeDejaPressee { commandeDejaPressee = true; action?() }
                if !active { commandeDejaPressee = false }
                return event
            }
        }
        func retirer() { if let moniteur { NSEvent.removeMonitor(moniteur); self.moniteur = nil } }
    }
}

private final class VueCaptureSansFaute: NSView {
    var caractereSaisi: ((String) -> Void)?
    var echapPresse: (() -> Void)?
    private var diacritiqueEnAttente: String?
    override var acceptsFirstResponder: Bool { true }
    override init(frame frameRect: NSRect) { super.init(frame: frameRect); setAccessibilityElement(false) }
    required init?(coder: NSCoder) { super.init(coder: coder); setAccessibilityElement(false) }
    override func resignFirstResponder() -> Bool { diacritiqueEnAttente = nil; return super.resignFirstResponder() }
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { diacritiqueEnAttente = nil; echapPresse?(); return }
        if [36,76,51,117].contains(event.keyCode) { diacritiqueEnAttente = nil; return }
        if event.modifierFlags.contains(.command) || event.modifierFlags.contains(.control) || event.modifierFlags.contains(.option) { super.keyDown(with: event); return }
        let caracteres = event.characters ?? ""
        let sansModificateur = event.charactersIgnoringModifiers ?? ""
        if caracteres.isEmpty {
            let toucheAccent = event.keyCode == 33 || sansModificateur == "^" || sansModificateur == "¨"
            if toucheAccent {
                diacritiqueEnAttente = (event.modifierFlags.contains(.shift) || sansModificateur == "¨") ? "\u{0308}" : "\u{0302}"
                return
            }
            super.keyDown(with: event); return
        }
        guard let premier = caracteres.first else { return }
        var texte = String(premier)
        if let diacritique = diacritiqueEnAttente {
            let normalise = texte.precomposedStringWithCanonicalMapping
            let dejaAccentue = normalise != normalise.folding(options: .diacriticInsensitive, locale: Locale(identifier: "fr_FR"))
            texte = dejaAccentue ? normalise : (texte + diacritique).precomposedStringWithCanonicalMapping
            diacritiqueEnAttente = nil
        } else {
            texte = texte.precomposedStringWithCanonicalMapping
        }
        caractereSaisi?(texte)
    }
}

@MainActor
private final class SonSansFaute {
    static let shared = SonSansFaute()
    private var lecteur: AVAudioPlayer?
    private init() {}
    func jouerErreur() {
        arreter()
        guard let url = Bundle.main.url(forResource: "MauvaiseReponse", withExtension: "wav") else { NSSound.beep(); return }
        do { lecteur = try AVAudioPlayer(contentsOf: url); lecteur?.prepareToPlay(); lecteur?.play() }
        catch { NSSound.beep() }
    }
    func arreter() { lecteur?.stop(); lecteur = nil }
}
