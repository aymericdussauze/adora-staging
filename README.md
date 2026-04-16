# ADORA — Staging

**Environnement de staging** pour le site [adora-economie.fr](https://adora-economie.fr)

🔗 **Preview** : [aymericdussauze.github.io/adora-staging](https://aymericdussauze.github.io/adora-staging/)

---

## À propos

Site vitrine et outils en ligne d'**ADORA — Économiste de la construction**, cabinet indépendant en Normandie (27/76) et Île-de-France.

- Estimations TCE, CCTP/DPGF, AMO pour particuliers et professionnels
- Outils en ligne : simulateur d'aides rénovation, estimateur de travaux, audit avant achat
- **Tunnel de conversion PropTech** : Gratuit (lead) → 49 € (rapport PDF) → 499 € (audit) → AMO sur mesure (2 200–3 900 €)

## Pages

| Fichier | Page | Type | Conversion |
|---|---|---|---|
| `index.html` | Homepage | Landing principale | → outils |
| `simulateur.html` | Simulateur aides | **Outil Typeform** (10 écrans) | **Lead magnet** (email) |
| `estimateur.html` | Estimateur (landing) | Présentation | → outil |
| `estimateur-outil.html` | Estimateur (outil) | **Outil Typeform** (8 écrans) | **Paywall Stripe 49 €** |
| `paiement-reussi.html` | Confirmation paiement | Success page post-Stripe | → rapport email |
| `audit-avant-achat.html` | Audit achat (landing) | Présentation | → formulaire |
| `audit-formulaire.html` | Audit achat (formulaire) | **Formulaire Typeform** (10 écrans) | **Lead qualifié** → paiement manuel |
| `sur-mesure.html` | Sur mesure | Prestations, packs AMO | → contact direct |

## Design System — Indigo Aurora (PropTech B2C v3)

Refonte avril 2026 inspirée des codes PropTech/FinTech (Airbnb, Alan, Stripe, Matera).

### Principes
- **Typeform UX** : une question par écran, auto-advance au clic, progress bar proéminente
- **Paywall cognitif** : résultat visible + blocs floutés + formulaire de déblocage
- **Micro-copy rassurante** : "Je ne sais pas", "Passer cette étape", explications contextuelles (Pourquoi cette question ?)
- **Écrans de chargement** : spinner + messages qui défilent (2,8 sec) pour donner de la valeur perçue
- **Mobile-first** : slider big-number, cartes tactiles, nav burger

### Typographie
- **Headings** : Montserrat 700/800/900 (Google Fonts)
- **Body** : Plus Jakarta Sans 400–800 (Google Fonts)

### Palette Indigo Aurora

| Token | Hex | Usage |
|---|---|---|
| `--navy` | `#0D1025` Nightfall | Headings, nav, hero background |
| `--surface` | `#1A1F3D` Indigo | CTA bands, surface sombre |
| `--deep` | `#080B1C` | Footer |
| `--accent` | `#22D3EE` Aqua | CTAs, accent principal |
| `--accent-hover` | `#06B6D4` | Hover CTA |
| `--accent-deep` | `#0E7490` Deep aqua | Liens texte, prix sur fond clair |
| `--iris` | `#A78BFA` Iris violet | Badges, accents secondaires |
| `--light` | `#EDE9FE` Lavender | Texte clair sur fond sombre |
| `--pale` | `#FAFAFC` Canvas | Sections alternées |
| `--txt` | `#1E1B4B` | Texte principal |
| `--muted` | `#64748B` | Texte secondaire |
| `--border` | `#E5E7F2` | Bordures |

**Règle de contraste** : le texte sur fond aqua est toujours en Nightfall (`--navy`), jamais en blanc (l'aqua est trop clair pour respecter WCAG AA).

### Composants unifiés
- **Nav** : sticky, backdrop-blur 12px, fond `rgba(13,16,37,.97)`, burger mobile
- **Footer** : 3 colonnes, fond Deep Night (`#080B1C`)
- **Cards** : border-radius 16px, shadow-on-hover + lift `translateY(-2px)`, check aqua au state selected
- **Slider big-number** : valeur en Montserrat 56px + input range avec thumb aqua
- **Paywall cards** : contenu flouté (`filter: blur(5px)`) + badge "Verrouillé" navy
- **Hero results** : dégradé navy/indigo + barre de confiance iris→aqua

## Outils interactifs — Architecture

### Estimateur (`estimateur-outil.html`) — Freemium Stripe

**Flow utilisateur** (8 écrans Typeform) :
1. Type de projet (Rénovation globale / Énergétique / Achat / Rafraîchissement)
2. Type de bien (Maison / Appart / Immeuble)
3. Surface (slider 20–400 m²)
4. Code postal (détection département live + variance régionale)
5. Année de construction (6 cartes + micro-copy amiante/plomb)
6. État général (4 cartes)
7. Gamme de finitions (4 cartes)
8. Contraintes (toggles amiante / plomb / accès)

**Écran de chargement** 2,8 sec avec 5 messages qui défilent.

**Résultats** :
- Hero dégradé navy + fourchette + indice de précision 80%
- 3 summary cards gratuites (Gros œuvre / Second œuvre / Équipements)
- 3 lock cards floutées (Détail par lot / Aides / Vigilance)
- **Bloc checkout 49 €** : Prénom + Email → Stripe Payment Link
- Ligne de trust : Paiement sécurisé Stripe · CB · Apple Pay · Google Pay
- Stepper 3 étapes post-paiement (Paiement → Email → Débrief)

**Calcul préservé** : 15 lots TCE, 101 départements, 6 coefficients correcteurs, scale factor surface.

**Configuration Stripe requise** (ligne ~1042) :
```javascript
const STRIPE_PAYMENT_LINK = "https://buy.stripe.com/REMPLACER_PAR_TON_LIEN_STRIPE";
```
Success URL à configurer dans Stripe : `https://adora-economie.fr/paiement-reussi.html`

### Simulateur d'aides (`simulateur.html`) — Lead Magnet email

**Flow utilisateur** (10 écrans Typeform) :
1. Localisation (IDF / Hors IDF)
2. Type de bien (Maison / Appartement)
3. Âge logement (+15 / -15 / NSP)
4. Statut (Occupant / Bailleur)
5. Composition foyer (slider 1–8+)
6. Revenu fiscal de référence (input + helper "où le trouver")
7. DPE (pills A-G avec code couleur + inconnu)
8. Parcours (Monogeste / Ampleur)
9. Travaux (multi-select groupé par catégorie)
10. Budget travaux (slider 5–150k€)

**Résultats** :
- Hero avec dégradé dynamique selon profil Anah (Bleu / Jaune / Violet / Rose)
- Good news banner personnalisée par profil
- Aperçu gratuit : cards MPR + CEE
- 3 lock cards floutées (Tableau détaillé / Alertes 2026 / Plan financement)
- **Bloc capture email** : Prénom + Email → Formspree → unlock direct
- Tableau déverrouillé : 6 lignes (MPR, CEE, éco-PTZ, TVA, Écrêtement, RAC)
- Alertes personnalisées (warn orange / info aqua)

**Calcul préservé** : `PLAFONDS_IDF/HDF`, `EXTRA_IDF/HDF`, `GESTES` (17 travaux), `AMPLEUR`, `ECRETEMENT_GESTE/ACCOMP`, `PLAFOND_GESTE_5ANS`, barèmes Anah 2026.

### Formulaire audit achat (`audit-formulaire.html`) — Lead qualifié

**Flow utilisateur** (10 écrans Typeform) :
1. Type de bien (4 cartes)
2. **Lien de l'annonce** + bouton "📋 Coller depuis presse-papier" + skip
3. Adresse complète (validation)
4. Surface (slider)
5. Prix demandé (formatage auto avec espaces)
6. Année de construction (6 cartes dont "Je ne sais pas")
7. Documents (4 uploads : DDT / DPE / photos ext / photos int) + skip
8. Contexte (textarea) + skip
9. Coordonnées (Prénom / Nom / Email / Téléphone)
10. **Récapitulatif éditable** + price block 499 € + submit

**Submission** : Formspree `xzdjopya` avec `multipart/form-data` (uploads).

**Paiement différé** : le lien Stripe est envoyé manuellement par email après validation de la demande (pas de paiement direct sur le site).

### Page de remerciement (`paiement-reussi.html`)

Redirect post-Stripe pour l'estimateur 49 €.
- Hero dégradé + check mark aqua animé (popIn + drawCheck)
- Personnalisation "Merci [prénom]" via localStorage (défini par estimateur avant redirect)
- Timeline 3 étapes (Dans 5 min PDF / Sous 48h appel / Quand vous voulez accompagnement)
- Card support (tel + mailto pré-rempli)
- GA4 event `purchase` (value: 49 €)

## Stack technique

- **Hébergement** : GitHub Pages (ce repo = staging)
- **Production** : [aymericdussauze/adora](https://github.com/aymericdussauze/adora) → adora-economie.fr
- **DNS** : OVH (4× A records → GitHub + CNAME www)
- **Analytics** : GA4 (`G-M0LENY960B`)
  - Événements : `begin_checkout`, `purchase`, `generate_lead`, `audit_request`, `estimator_unlock`
- **Paiement** : Stripe Payment Links (pas de backend, no-code)
- **Formulaires** : Formspree (`xzdjopya`) — endpoint unique pour toutes les soumissions
- **Automatisation post-paiement** : Make/Zapier (webhook Stripe → génération PDF → email)
- **Pas de framework** : HTML/CSS/JS vanilla, single-file par page, Google Fonts uniquement

## Configuration requise en production

### Stripe
1. Créer produit "Rapport d'estimation ADORA - 49 €" dans le dashboard
2. Créer un Payment Link associé
3. Configurer `success_url` → `https://adora-economie.fr/paiement-reussi.html`
4. Remplacer `STRIPE_PAYMENT_LINK` ligne ~1042 de `estimateur-outil.html`

### Make (ou Zapier)
Scénario : `Stripe — New payment succeeded` → `Gmail — Send email with attachment`
- Récupérer `customer_email` + `client_reference_id` (format : `prenom_timestamp`)
- Matcher avec la soumission Formspree correspondante (par email)
- Générer le PDF (module PDF Monkey / Google Docs / API)
- Envoyer par email

### Formspree
Endpoint commun `xzdjopya` pour tous les formulaires :
- Simulateur : lead capture avec tout le contexte simulation
- Estimateur : pré-envoi avant Stripe (données projet + estimation)
- Audit : demande qualifiée avec pièces jointes (multipart)

## Déploiement en production

Quand le staging est validé :

1. Remplacer `<base href="https://aymericdussauze.github.io/adora-staging/">` par `<base href="https://adora-economie.fr/">` dans les **8 fichiers HTML**
2. Copier les fichiers dans le repo `aymericdussauze/adora` (branche `main`)
3. Vérifier que `STRIPE_PAYMENT_LINK` pointe vers le vrai Payment Link Stripe
4. Push → GitHub Pages redéploie automatiquement sous 1-2 min

## Fichiers du repo

```
adora-staging/
├── index.html                          # Homepage
├── simulateur.html                     # Simulateur aides (Typeform + lead magnet)
├── estimateur.html                     # Landing estimateur
├── estimateur-outil.html               # Estimateur (Typeform + Stripe paywall)
├── paiement-reussi.html                # Post-Stripe confirmation
├── audit-avant-achat.html              # Landing audit achat
├── audit-formulaire.html               # Formulaire audit (Typeform + uploads)
├── sur-mesure.html                     # Prestations sur mesure
└── README.md                           # Ce fichier
```

## Contact

**ADORA** — Aymeric Dussauze
Économiste de la construction · EI · SIRET 532 886 918 00020
TVA non applicable, art. 293B du CGI
06 60 21 55 09 · aymericdussauze@gmail.com
