import SwiftUI
import AppKit
import AVFoundation

struct SautGagnantView: View {
    let retourParc: () -> Void

    private enum Ecran { case niveaux, objectif, partie, resultat }
    @State private var ecran: Ecran = .niveaux
    @State private var niveau = 1
    @State private var niveauMaximum = 1
    @State private var afficherCommentJouer = false
    @State private var partieActive = false
    @State private var compteARebours: Int? = nil
    @State private var indexMot = 0
    @State private var motsPartie: [String] = []
    @State private var saisie = ""
    @State private var erreurs = 0
    @State private var debut: Date? = nil
    @State private var dureeFinale: TimeInterval = 0
    @State private var enSaut = false
    @State private var glissade = false
    @State private var generation = 0

    @AccessibilityFocusState private var titreEnFocus: Bool
    @AccessibilityFocusState private var zoneNeutreEnFocus: Bool
    @AccessibilityFocusState private var resultatEnFocus: Bool

    private let cleProgression = "progressionSautGagnantParUtilisateurV2"

    private let titres = [
        "Premiers bonds", "Les jongleurs", "Les clowns", "Les équilibristes",
        "Les trapézistes", "Les chevaux du cirque", "La parade",
        "Les artistes de feu", "Le grand spectacle", "Le cirque illuminé"
    ]
    private let nombres = [8,9,10,11,12,13,14,15,16,18]
    private let descriptionsNiveaux = [
        "Traversez la piste du cirque en sautant de plate-forme en plate-forme.",
        "Progressez au milieu des accessoires des jongleurs jusqu’à l’arrivée.",
        "Frayez-vous un chemin dans l’univers coloré des clowns.",
        "Avancez dans les hauteurs où précision et équilibre sont à l’honneur.",
        "Prenez de la hauteur dans le décor aérien des trapézistes.",
        "Traversez la piste consacrée aux chevaux et aux cavaliers du cirque.",
        "Suivez la grande parade au milieu des artistes et des décorations.",
        "Progressez dans un décor nocturne éclairé par les flammes et les lumières.",
        "Entrez au cœur du grand spectacle où tous les artistes se retrouvent.",
        "Rejoignez l’arrivée dans un cirque illuminé pour le grand final."
    ]
    private let banques: [[String]] = [
        ["piste centrale","tapis rouge","balle ronde","ruban bleu","étoile jaune","lampe verte","rideau mauve","tambour léger"],
        ["quille blanche","anneau doré","massue orange","foulard souple","diabolo rapide","cerceau brillant","torche claire","chapeau melon","ballon violet"],
        ["nez écarlate","perruque bouclée","veste large","chaussure énorme","bouton nacré","salopette rayée","trompette joyeuse","parapluie bariolé","valise comique","maquillage coloré"],
        ["câble tendu","perche longue","poutre étroite","marche lente","équilibre stable","hauteur calme","filet discret","passage aérien","appui précis","posture droite","souffle régulier"],
        ["trapèze volant","balançoire haute","portique solide","envol fluide","réception douce","voltige agile","acrobate habile","plateforme lointaine","poignée ferme","élan puissant","rotation vive","cordage robuste"],
        ["cheval docile","crinière soyeuse","écurie calme","étrier poli","carrière ocre","sabot noir","bride ajustée","selle confortable","cavalier prudent","trot léger","galop ample","manège ancien","barrière basse"],
        ["parade festive","fanfare sonore","char fleuri","drapeau flottant","confetti multicolore","musicien mobile","jongleur souriant","danseuse gracieuse","costume brodé","cortège animé","tambourin rythmé","masque décoré","lanterne suspendue","avenue illuminée"],
        ["flamme vive","torche brûlante","étincelle dorée","mèche allumée","charbon incandescent","chaleur intense","fumée légère","lumière orange","foyer rougeoyant","bâton enflammé","cercle lumineux","nuit profonde","silhouette sombre","reflet cuivré","ciel nocturne"],
        ["chapiteau majestueux","projecteur central","orchestre discret","coulisse feutrée","gradin rempli","entrée théâtrale","numéro spectaculaire","artiste concentré","voltigeur intrépide","équilibriste attentif","jonglerie précise","acrobatie élégante","final éclatant","applaudissement nourri","décor somptueux","ambiance magique"],
        ["fête foraine","grande roue","enseigne lumineuse","guirlande scintillante","carrousel enchanté","kiosque coloré","manège tournant","chapiteau éclairé","trapèze argenté","jongleur adroit","acrobate aérien","parade nocturne","musique entraînante","rideau étincelant","piste rayonnante","drapeau final","soirée féerique","spectacle grandiose"],
    ]

    var body: some View {
        ZStack {
            decor
                .accessibilityHidden(true)
            VStack(spacing: 22) {
                switch ecran {
                case .niveaux: ecranNiveaux
                case .objectif: ecranObjectif
                case .partie: ecranPartie
                case .resultat: ecranResultat
                }
            }
            .padding(36)
        }
        .frame(minWidth: 1100, minHeight: 700)
        .background(CaptureClavierSautGagnant(
            actif: ecran == .partie && partieActive,
            echapActif: !afficherCommentJouer,
            texte: { traiter($0) },
            commande: { relireMot() },
            echap: { gererEchap() }
        ).frame(width: 0, height: 0))
        .sheet(isPresented: $afficherCommentJouer) {
            CommentJouerSautGagnantView { afficherCommentJouer = false }
        }
        .onAppear { chargerProgression() }
        .onDisappear { generation += 1; SonSautGagnant.shared.stop() }
    }

    private var ecranNiveaux: some View {
        ScrollView {
            VStack(spacing: 18) {
                HStack {
                    Button("Retour au parc d’attractions") { retourParc() }
                    Spacer()
                }
                Text("Le Saut gagnant").font(.largeTitle).bold()
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($titreEnFocus)
                Text("Tapez correctement les couples de mots pour guider votre acrobate de plate-forme en plate-forme jusqu’à l’arrivée.")
                    .font(.title3).multilineTextAlignment(.center).frame(maxWidth: 780)
                Button("Comment jouer") { afficherCommentJouer = true }
                VStack(spacing: 10) {
                    ForEach(1...10, id: \.self) { n in
                        Button {
                            if n <= niveauMaximum { niveau = n; ecran = .objectif; placerTitre() }
                            else { _ = GestionnaireSonsInterface.shared.jouerCadenasVerrouille() }
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Niveau \(n)").font(.headline)
                                    Text(titres[n-1]).font(.title3)
                                }
                                Spacer()
                                Image(systemName: n > niveauMaximum ? "lock.fill" : "chevron.right.circle.fill")
                            }.padding(12).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        }.buttonStyle(.plain)
                        .accessibilityLabel(n > niveauMaximum ? "Niveau \(n), \(titres[n-1]), verrouillé" : "Niveau \(n), \(titres[n-1])")
                    }
                }.frame(maxWidth: 700)
            }
        }.onAppear { placerTitre() }
    }

    private var ecranObjectif: some View {
        VStack(spacing: 22) {
            Text("Niveau \(niveau) — \(titres[niveau-1])").font(.largeTitle).bold()
                .accessibilityAddTraits(.isHeader).accessibilityFocused($titreEnFocus)
            Text(descriptionsNiveaux[niveau-1])
                .font(.title2).multilineTextAlignment(.center).frame(maxWidth: 760)
            Text("Objectif : atteignez le drapeau d’arrivée en franchissant \(nombres[niveau-1]) plates-formes.")
                .font(.title2).multilineTextAlignment(.center)
            Button("Commencer le niveau") { commencer() }.keyboardShortcut(.defaultAction)
            Button("Retour aux niveaux") { ecran = .niveaux; placerTitre() }
        }
    }

    private var ecranPartie: some View {
        ZStack(alignment: .trailing) {
            VStack(spacing: 24) {
                if let c = compteARebours {
                    Text("\(c)").font(.system(size: 96, weight: .bold)).accessibilityHidden(true)
                } else if partieActive {
                    Text(motActuel).font(.system(size: 42, weight: .bold))
                        .padding(.horizontal, 28).padding(.vertical, 14)
                        .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(Color(nsColor: .textColor))
                        .accessibilityHidden(true)
                    Text("Plate-forme \(min(indexMot + 1, nombres[niveau-1])) sur \(nombres[niveau-1])")
                        .font(.headline).accessibilityHidden(true)
                    parcours
                    Text(saisie.isEmpty ? " " : saisie).font(.title3).accessibilityHidden(true)
                }
            }
            PointFocusVoiceOverSilencieuxSautGagnant()
                .frame(width: 2, height: 2)
                .accessibilityFocused($zoneNeutreEnFocus)
        }
    }

    private var parcours: some View {
        GeometryReader { geo in
            let total = nombres[niveau-1] + 1
            ZStack {
                ForEach(0..<total, id: \.self) { i in
                    let x = CGFloat(i) / CGFloat(max(1,total-1)) * (geo.size.width - 100) + 50
                    let y = geo.size.height * (0.48 + CGFloat((i % 3)-1) * 0.13)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(couleurPlateforme(i))
                        .frame(width: largeurPlateforme(i), height: 18)
                        .position(x: x, y: y)
                    if i == total-1 {
                        Image(systemName: "flag.checkered").font(.system(size: 28, weight: .bold))
                            .position(x: x, y: y-28)
                    }
                }
                let i = min(indexMot, total-1)
                let x = CGFloat(i) / CGFloat(max(1,total-1)) * (geo.size.width - 100) + 50
                let y = geo.size.height * (0.48 + CGFloat((i % 3)-1) * 0.13)
                Image(systemName: "figure.run")
                    .font(.system(size: 36, weight: .bold))
                    .rotationEffect(.degrees(glissade ? -18 : 0))
                    .offset(y: enSaut ? -38 : 0)
                    .position(x: x, y: y-25)
                    .animation(.easeInOut(duration: 0.18), value: enSaut)
                    .animation(.easeInOut(duration: 0.12), value: glissade)
            }
        }.frame(height: 300).accessibilityHidden(true)
    }

    private var messageResultat: String {
        if niveau < 10 {
            return "Bravo ! Votre acrobate a terminé le parcours. Le niveau \(niveau + 1) est maintenant déverrouillé."
        } else {
            return "Bravo, vous avez terminé tous les niveaux du Saut gagnant !"
        }
    }

    private var ecranResultat: some View {
        Button {
            ecran = .niveaux
            placerTitre()
        } label: {
            VStack(spacing: 18) {
                Text("Parcours terminé !").font(.largeTitle).bold()
                Text(messageResultat).font(.title2).multilineTextAlignment(.center)
                Text("Couples de mots réussis : \(nombres[niveau-1])").font(.title3)
                Text("Erreurs : \(erreurs)").font(.title3)
                Text("Vitesse moyenne : \(vitesse) mots par minute").font(.title3)
                Text("Appuyez sur Entrée pour revenir à la liste des niveaux.").font(.headline)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.defaultAction)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(messageResultat) Couples de mots réussis : \(nombres[niveau-1]). Erreurs : \(erreurs). Vitesse moyenne : \(vitesse) mots par minute. Appuyez sur Entrée pour revenir à la liste des niveaux.")
        .accessibilityFocused($resultatEnFocus)
        .onAppear { placerFocusResultat() }
    }

    private var motActuel: String {
        guard motsPartie.indices.contains(indexMot) else { return "" }
        return motsPartie[indexMot]
    }
    private var vitesse: Int {
        guard dureeFinale > 0 else { return 0 }
        return Int((Double(nombres[niveau-1]) / dureeFinale * 60).rounded())
    }

    private func commencer() {
        generation += 1
        let g = generation
        ecran = .partie; partieActive = false; indexMot = 0; erreurs = 0; saisie = ""
        let besoin = nombres[niveau-1]
        var banque = banques[niveau-1].shuffled()
        while banque.count < besoin { banque += banques[niveau-1].shuffled() }
        motsPartie = Array(banque.prefix(besoin))
        compteARebours = 3
        // Même principe que La Grande Roue : VoiceOver est placé une seule fois
        // sur un point neutre avant le décompte, puis le focus n'est plus déplacé.
        placerFocusZoneNeutre()
        for (delai, valeur) in [(1.2,3),(2.2,2),(3.2,1)] {
            DispatchQueue.main.asyncAfter(deadline: .now()+delai) {
                guard generation == g, ecran == .partie else { return }
                compteARebours = valeur
                VoiceOverAnnouncer.annoncerTexte("\(valeur)")
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now()+4.2) {
            guard generation == g, ecran == .partie else { return }
            compteARebours = nil
        }
        DispatchQueue.main.asyncAfter(deadline: .now()+5.2) {
            guard generation == g, ecran == .partie else { return }
            partieActive = true; debut = Date(); relireMot()
        }
    }

    private func traiter(_ texte: String) {
        guard partieActive, !enSaut, !motActuel.isEmpty else { return }
        saisie += texte
        let attendu = motActuel.precomposedStringWithCanonicalMapping
        let saisiNormalise = saisie.precomposedStringWithCanonicalMapping
        if attendu.hasPrefix(saisiNormalise) {
            if saisiNormalise == attendu { reussite() }
        } else {
            erreurs += 1; saisie = ""; glissade = true
            SonSautGagnant.shared.play("Erreur_Glissade")
            DispatchQueue.main.asyncAfter(deadline: .now()+0.32) { glissade = false }
        }
    }

    private func reussite() {
        partieActive = false; enSaut = true
        SonSautGagnant.shared.play("Saut")
        let delai = delaiVol(pour: motActuel)
        DispatchQueue.main.asyncAfter(deadline: .now()+delai) {
            indexMot += 1; saisie = ""; enSaut = false
            if indexMot >= nombres[niveau-1] { terminer() }
            else {
                partieActive = true
                DispatchQueue.main.asyncAfter(deadline: .now()+0.28) { relireMot() }
            }
        }
    }

    private func delaiVol(pour mot: String) -> Double {
        if mot.count <= 4 { return 0.34 }
        if mot.count <= 8 { return 0.50 }
        return 0.68
    }

    private func terminer() {
        partieActive = false
        dureeFinale = Date().timeIntervalSince(debut ?? Date())
        let textesCorrects = Array(motsPartie.prefix(nombres[niveau - 1]))
        ProgressionManager.shared.enregistrerPartie(
            jeu: .sautGagnant,
            niveau: niveau,
            reussie: true,
            motsCorrects: textesCorrects.reduce(0) { $0 + ProgressionManager.nombreDeMots(dans: $1) },
            erreursDeFrappe: erreurs,
            caracteresValides: textesCorrects.reduce(0) { $0 + $1.count },
            dureeSaisie: dureeFinale
        )
        SonSautGagnant.shared.play("01_Victoire_Eclair")
        if niveau < 10 {
            niveauMaximum = max(niveauMaximum, niveau+1)
            ProgressionManager.shared.enregistrerNiveauMaximumDebloqueJeu(niveauMaximum, cle: cleProgression)
        }
        ecran = .resultat
    }

    private func relireMot() {
        guard NSWorkspace.shared.isVoiceOverEnabled,
              ecran == .partie, partieActive, !motActuel.isEmpty else { return }
        LecteurMotSautGagnant.shared.lire(motActuel)
    }

    private func chargerProgression() {
        niveauMaximum = ProgressionManager.shared.niveauMaximumDebloqueJeu(cle: cleProgression)
    }

    private func gererEchap() {
        guard !afficherCommentJouer else { return }
        switch ecran {
        case .partie:
            if partieActive || compteARebours != nil { return }
            ecran = .objectif; placerTitre()
        case .resultat: break
        case .objectif: ecran = .niveaux; placerTitre()
        case .niveaux: retourParc()
        }
    }

    private func placerFocusZoneNeutre() {
        titreEnFocus = false
        resultatEnFocus = false
        zoneNeutreEnFocus = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            zoneNeutreEnFocus = true
        }
    }

    private func placerFocusResultat() {
        zoneNeutreEnFocus = false
        titreEnFocus = false
        resultatEnFocus = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            resultatEnFocus = true
        }
    }

    private func placerTitre() {
        zoneNeutreEnFocus = false
        resultatEnFocus = false
        titreEnFocus = false
        DispatchQueue.main.asyncAfter(deadline: .now()+0.45) { titreEnFocus = true }
    }

    private func couleurPlateforme(_ i: Int) -> Color {
        [.red,.blue,.yellow,.green,.orange,.purple,.cyan,.pink][i % 8]
    }
    private func largeurPlateforme(_ i: Int) -> CGFloat {
        let ref = (i < motsPartie.count ? motsPartie[i].count : 5)
        return ref <= 4 ? 58 : (ref <= 8 ? 72 : 88)
    }

    @ViewBuilder private var decor: some View {
        let n = max(1,min(10,niveau))
        ZStack {
            LinearGradient(colors: n >= 8 ? [.indigo.opacity(0.82), .black] : [.blue.opacity(0.35), .orange.opacity(0.18)], startPoint: .top, endPoint: .bottom)
            if ecran == .niveaux {
                // Accueil du Saut gagnant : conserver le décor étoilé tout en
                // rendant l'acrobate immédiatement identifiable visuellement.
                Image(systemName: "star.fill")
                    .font(.system(size: 260))
                    .opacity(0.10)

                Image(systemName: "figure.run")
                    .font(.system(size: 190, weight: .bold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
                    .shadow(radius: 12)
                    .opacity(0.82)
                    .offset(x: 300, y: 105)
                    .accessibilityHidden(true)
            } else {
                Group {
                    switch n {
                    case 1: Image(systemName:"sparkles")
                    case 2: Image(systemName:"circle.grid.3x3.fill")
                    case 3: Image(systemName:"face.smiling")
                    case 4: Image(systemName:"figure.walk")
                    case 5: Image(systemName:"figure.walk")
                    case 6: Image(systemName:"hare.fill")
                    case 7: Image(systemName:"music.note.list")
                    case 8: Image(systemName:"flame.fill")
                    case 9: Image(systemName:"sparkles")
                    default: Image(systemName:"star.fill")
                    }
                }.font(.system(size: 240)).opacity(0.09)
            }
        }.ignoresSafeArea()
    }
}

private struct CommentJouerSautGagnantView: View {
    let fermer: () -> Void
    @AccessibilityFocusState private var titreEnFocus: Bool
    @State private var contenuAccessible = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Comment jouer")
                    .font(.largeTitle)
                    .bold()
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($titreEnFocus)

                Text("Dans ce jeu, vous devez taper deux mots séparés par un espace.")
                Text("Tapez correctement les deux mots ainsi que l’espace qui les sépare pour faire sauter votre acrobate de plate-forme en plate-forme jusqu’à l’arrivée. La longueur des deux mots fait varier la distance du saut.")
                Text("Un son indique chaque saut réussi. En cas d’erreur, un son différent vous avertit et votre acrobate reste sur sa dernière plate-forme afin que vous puissiez réessayer.")
                Text("Lorsque votre acrobate atteint la plate-forme d’arrivée, un son de victoire indique que le niveau est réussi.")
                Text("Avec VoiceOver activé, le couple de mots est lu automatiquement. Appuyez sur la touche Commande pour le réécouter. Sans VoiceOver, lisez le couple de mots affiché à l’écran ; la touche Commande ne déclenche pas de lecture vocale.")

                HStack {
                    Spacer()
                    Button("J’ai compris") { fermer() }
                        .keyboardShortcut(.defaultAction)
                }
            }
            .padding(34)
            .frame(maxWidth: 760, alignment: .leading)
        }
        .frame(minWidth: 720, minHeight: 520)
        .accessibilityHidden(!contenuAccessible)
        .onAppear {
            contenuAccessible = false
            titreEnFocus = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                contenuAccessible = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    titreEnFocus = true
                }
            }
        }
        .onExitCommand { fermer() }
    }
}

private final class SonSautGagnant {
    static let shared = SonSautGagnant()
    private var player: AVAudioPlayer?
    func play(_ nom: String) {
        guard let url = Bundle.main.url(forResource: nom, withExtension: "wav") else { return }
        do { player = try AVAudioPlayer(contentsOf: url); player?.prepareToPlay(); player?.play() } catch {}
    }
    func stop() { player?.stop(); player = nil }
}

private final class LecteurMotSautGagnant {
    static let shared = LecteurMotSautGagnant()
    private let synth = NSSpeechSynthesizer()
    func lire(_ mot: String) { synth.stopSpeaking(); synth.startSpeaking(mot) }
}

private struct PointFocusVoiceOverSilencieuxSautGagnant: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let vue = NSView(frame: .zero)
        vue.setAccessibilityElement(true)
        vue.setAccessibilityRole(.unknown)
        vue.setAccessibilityLabel(nil)
        vue.setAccessibilityHelp(nil)
        vue.setAccessibilityValue(nil)
        return vue
    }

    func updateNSView(_ nsView: NSView, context: Context) { }
}

private struct CaptureClavierSautGagnant: NSViewRepresentable {
    let actif: Bool
    let echapActif: Bool
    let texte: (String) -> Void
    let commande: () -> Void
    let echap: () -> Void

    func makeNSView(context: Context) -> NSView {
        let v = VueClavierSautGagnant(); config(v); return v
    }
    func updateNSView(_ nsView: NSView, context: Context) {
        guard let v = nsView as? VueClavierSautGagnant else { return }; config(v)
    }
    private func config(_ v: VueClavierSautGagnant) {
        v.actif=actif; v.echapActif=echapActif; v.texte=texte; v.commande=commande; v.echap=echap
    }
}

private final class VueClavierSautGagnant: NSView {
    var actif=false
    var echapActif=true
    var texte: ((String)->Void)?
    var commande: (()->Void)?
    var echap: (()->Void)?
    private var keyMonitor: Any?
    private var flagsMonitor: Any?
    private var commandeEtaitEnfoncee = false
    private var diacritiqueEnAttente: String?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if keyMonitor == nil {
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] e in
                guard let self else { return e }
                let mods = e.modifierFlags
                    .intersection(.deviceIndependentFlagsMask)
                    .intersection([.command, .control, .option, .shift])

                // Échap suit la navigation générale du Parc, mais n'est jamais
                // avalée lorsque la fenêtre « Comment jouer » est ouverte.
                if e.keyCode == 53, mods.isEmpty, self.echapActif {
                    self.echap?()
                    return nil
                }

                // Entrée doit rester disponible au bouton par défaut de l'écran
                // d'objectif, comme dans les autres jeux. On ne l'intercepte pas.
                if e.keyCode == 36 || e.keyCode == 76 { return e }

                guard self.actif else { return e }

                let flags = e.modifierFlags.intersection(.deviceIndependentFlagsMask)
                if flags.contains(.control) || flags.contains(.option) || flags.contains(.command) { return e }

                let caracteres = e.characters ?? ""
                let caracteresSansModificateur = e.charactersIgnoringModifiers ?? ""

                // Même gestion des touches mortes ^ et ¨ que dans La Grande Roue.
                // La touche morte seule n'est jamais considérée comme une erreur.
                if caracteres.isEmpty {
                    let estToucheAccent =
                        e.keyCode == 33
                        || caracteresSansModificateur == "^"
                        || caracteresSansModificateur == "¨"

                    if estToucheAccent {
                        if e.modifierFlags.contains(.shift)
                            || caracteresSansModificateur == "¨" {
                            self.diacritiqueEnAttente = "\u{0308}"
                        } else {
                            self.diacritiqueEnAttente = "\u{0302}"
                        }
                        return nil
                    }
                    return e
                }

                guard let premier = caracteres.first else { return e }
                var texteSaisi = String(premier)

                if let diacritique = self.diacritiqueEnAttente {
                    let normalise = texteSaisi.precomposedStringWithCanonicalMapping
                    let contientDejaDiacritique =
                        normalise != normalise.folding(
                            options: .diacriticInsensitive,
                            locale: Locale(identifier: "fr_FR")
                        )

                    if !contientDejaDiacritique {
                        texteSaisi =
                            (texteSaisi + diacritique)
                            .precomposedStringWithCanonicalMapping
                    } else {
                        texteSaisi = normalise
                    }
                    self.diacritiqueEnAttente = nil
                } else {
                    texteSaisi = texteSaisi.precomposedStringWithCanonicalMapping
                }

                self.texte?(texteSaisi)
                return nil
            }
        }
        if flagsMonitor == nil {
            flagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] e in
                guard let self else { return e }
                let enfoncee = e.modifierFlags.contains(.command)
                if enfoncee && !self.commandeEtaitEnfoncee && self.actif { self.commande?() }
                self.commandeEtaitEnfoncee = enfoncee
                return e
            }
        }
    }
    deinit {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        if let flagsMonitor { NSEvent.removeMonitor(flagsMonitor) }
    }
}
