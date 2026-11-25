# CourseIQ pour iPhone — guide d'installation (débutant)

Ce dossier contient le code complet de l'appli iPhone CourseIQ.
Tu n'as pas besoin de Mac : l'appli est compilée en ligne par GitHub, puis installée
depuis ton PC Windows avec Sideloadly. Compte environ 30 minutes la première fois.

## Ce que fait l'appli

- Quand une offre Uber apparaît (Accepter / Refuser) : capture d'écran de l'offre,
  puis Partager > CourseIQ. Le verdict s'affiche directement : temps de trajet en
  premier, puis RENTABLE / À ÉVALUER / PERTE avec tes coûts déduits.
- La lecture de la capture se fait sur ton iPhone (Apple Vision). Rien n'est envoyé en ligne.
- L'app elle-même garde le calculateur complet avec tes réglages (conso, charges,
  commission, objectif €/h), qui sont sauvegardés sur le téléphone.

## Étape 1 — Compiler en ligne (GitHub)

1. Crée un compte gratuit sur https://github.com (avec ton adresse e-mail).
2. Une fois connecté, clique sur le **+** en haut à droite > **New repository**.
   - Name : `courseiq`
   - Coche **Public** (gratuit et illimité pour la compilation)
   - Coche **Add a README file**
   - Clique **Create repository**.
3. Sur la page du projet, clique **Add file** > **Upload files**.
4. Glisse TOUT le contenu de ce dossier (les dossiers `CourseIQ`, `CourseIQShare`,
   `.github` et le fichier `project.yml`). Attention : le dossier `.github` est
   peut-être invisible sur Windows ; affiche les éléments masqués ou utilise
   "choose your files" et sélectionne tout.
5. Clique **Commit changes**.
6. Va dans l'onglet **Actions**. Si GitHub demande, clique
   **I understand my workflows, go ahead and enable them**.
7. Clique sur **Build IPA** à gauche, puis sur **Run workflow** à droite,
   puis sur le bouton vert **Run workflow**.
8. Attends 5 à 10 minutes. Si tout va bien, une coche verte apparaît.
   Clique dessus, descends en bas de la page, et télécharge **CourseIQ-ipa**
   (un fichier zip). Dézippe-le : il contient `CourseIQ.ipa`.
   Si la compilation échoue (croix rouge), ouvre le log et envoie-moi une capture
   de l'erreur : je corrige le code et tu relances l'étape 7.

## Étape 2 — Installer sur l'iPhone (Sideloadly)

1. Sur ton PC, télécharge Sideloadly : https://sideloadly.io (version Windows).
2. Installe aussi iTunes et iCloud (versions "classiques", pas celles du Microsoft
   Store) si Sideloadly les demande.
3. Branche ton iPhone au PC avec le câble. Sur l'iPhone, touche **Se fier** à
   cet ordinateur.
4. Ouvre Sideloadly. En haut, entre ton adresse e-mail Apple ID (celle de ton iPhone).
5. Glisse le fichier `CourseIQ.ipa` dans Sideloadly, puis clique **Start**.
6. Entre ton mot de passe Apple ID quand il le demande, et le code de vérification
   si tu as la double authentification.
7. Quand c'est fini, sur l'iPhone : **Réglages > Général > VPN et gestion des
   appareils** > touche ton adresse e-mail > **Faire confiance**.
8. L'icône CourseIQ apparaît sur ton écran d'accueil.

## Limites à connaître

- **7 jours** : avec un compte Apple gratuit, l'appli expire au bout de 7 jours
  (règle d'Apple). Sideloadly peut la re-signer automatiquement si le PC et
  l'iPhone sont sur le même Wi-Fi (laisse le service Sideloadly tourner), sinon
  refais l'étape 2, points 4 à 6. Tes réglages sont conservés.
- **Pas de bulle automatique par-dessus Uber** : iOS l'interdit à toute appli.
  Même Ride_IQ fonctionne par capture d'écran. Le réflexe : capture > Partager > CourseIQ.
- **Réglages par défaut dans le verdict de partage** : la feuille de partage ne lit
  pas les réglages de l'app (compte Apple gratuit = pas de partage de données entre
  les deux). Vérifie que les réglages de l'app correspondent à ton véhicule ;
  le détail complet se fait dans l'app.
- Compte développeur Apple payant (99 €/an) : supprime la limite des 7 jours
  (1 an). Pas nécessaire pour commencer.
