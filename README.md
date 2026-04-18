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
| `simulateur.html` | Simulateur aides | **Outil Typeform** (10 écrans) | **Lead magnet** (email → PDF) |
| `estimateur.html` | Estimateur (landing) | Présentation freemium vs 49 € | → outil |
| `estimateur-outil.html` | Estimateur (outil) | **Outil Typeform** (8 écrans) | **Paywall Stripe 49 €** |
| `paiement-reussi.html` | Confirmation paiement | Success page post-Stripe | → rapport email |
| `audit-avant-achat.html` | Audit achat (landing) | Présentation 499 € | → formulaire |
| `audit-formulaire.html` | Audit achat (formulaire) | **Formulaire Typeform** (10 écrans) | **Lead qualifié** |
| `sur-mesure.html` | Sur mesure | Estimation détaillée + packs AMO | → contact direct |
| `a-propos.html` | À propos | Parcours, philosophie, références | Crédibilité |
| `professionnels.html` | Professionnels | Offre freelance + TJM affichés | → contact email/tél |
| `blog.html` | Blog | *(à créer)* | SEO |

## Navigation unifiée

Toutes les pages partagent la même nav et le même footer.

### Nav (sticky, identique partout)

```
[Logo ADORA]   Simulateur   Estimateur   Audit achat   Sur mesure   [Estimer mes travaux →]
```

- CTA → `estimateur-outil.html`
- Lien actif surligné (classe `.active`) selon la page courante
- Pages secondaires (à-propos, professionnels) : pas de lien actif dans la nav

### Footer (4 colonnes, identique partout)

| Marque | Outils | ADORA | Contact |
|---|---|---|---|
| ADORA · Éco construction · Normandie & IDF | Simulateur · Estimateur · Audit achat · Sur mesure | À propos · Professionnels · Blog | Tél · Email · Site |

Ligne légale : © 2026 ADORA · EI · SIRET 532 886 918 00020 · TVA art. 293B

## Design System — Indigo Aurora (PropTech B2C v3)

Refonte avril 2026 inspirée des codes PropTech/FinTech (Airbnb, Alan, Stripe, Matera).

### Typographie

- **Headings** : Montserrat 700/800/900 (Google Fonts)
- **Body** : Plus Jakarta Sans 400–800 (Google Fonts)

### Palette Indigo Aurora

| Token | Hex | Usage |
|---|---|---|
| `--navy` | `#0D1025` Nightfall | Headings, nav, hero background |
| `--accent` | `#22D3EE` Aqua | CTAs, accent principal |
| `--accent-hover` | `#06B6D4` | Hover CTA |
| `--blue` | `#0E7490` Deep aqua | Liens texte, prix sur fond clair |
| `--green` | `#A78BFA` Iris violet | Badges, accents secondaires |
| `--pale` | `#FAFAFC` Canvas | Sections alternées |
| `--txt` | `#1E1B4B` | Texte principal |
| `--muted` | `#64748B` | Texte secondaire |
| `--border` | `#E5E7F2` | Bordures |

**Règle WCAG** : texte sur fond aqua toujours en `--navy`, jamais en blanc.

### Composants

- **Nav** : sticky, backdrop-blur 12px, fond navy translucide, burger mobile
- **Footer** : 4 colonnes, fond navy, responsive 2→1 col mobile
- **Cards** : border-radius 16px, shadow-on-hover + lift
- **Slider big-number** : valeur en Montserrat 56px + thumb aqua
- **Portrait photo** : 300×300 JPEG base64 (13 Ko), rond 180px, intégré dans a-propos / sur-mesure / professionnels

## Architecture PDF — PDFShift + Cloudflare Worker

Le simulateur d'aides génère un PDF 5 pages côté serveur via un Worker Cloudflare.

### Flow

```
Simulateur (navigateur client)
  ↓ POST JSON (données simulation)
Cloudflare Worker (adora-pdf.aymericdussauze.workers.dev)
  ↓ Génère le HTML 5 pages (template intégré dans le Worker)
PDFShift API
  ↓ Convertit HTML → PDF vectoriel (Chromium headless)
Worker retourne le PDF binaire
  ↓
Nouvel onglet navigateur (blob URL)
```

### Design du PDF — Tech Moderne + détail serif

- **Polices** : Inter Tight (body/display) + Instrument Serif (italiques, symbole €) + JetBrains Mono (data/labels)
- **Palette** : encre `#0F0F11` + papier `#FAFAF7` + accent unique `#2A5CFF` (bleu électrique)
- **5 pages** : Couverture (métriques dashboard) → Situation (data grid + chips travaux) → Aides (table + RAC card) → Alertes + Étapes → Closing (plan cards + contact)

### Configuration Worker

- **Worker URL** : `https://adora-pdf.aymericdussauze.workers.dev`
- **Secret Cloudflare** : `PDFSHIFT_API_KEY` (clé PDFShift, stockée chiffrée)
- **Quota** : 50 PDFs/mois gratuit (PDFShift Sandbox)
- **Rate limiting** : 1 PDF / 10s par IP
- **CORS** : `aymericdussauze.github.io` + `adora-economie.fr`
- **Templates** : simulateur (complet), estimateur (placeholder), audit (placeholder)

### Fichiers Worker (hors repo, déployés sur Cloudflare)

```
pdf-worker/
├── worker.js          # 778 lignes — code complet, copier-coller dans Cloudflare
├── DEPLOIEMENT.md     # Guide pas à pas sans CLI
└── INTEGRATION.md     # Comment connecter simulateur.html au Worker
```

## Détail des pages

### Simulateur d'aides (`simulateur.html`)

**Hero** : "Simulateur d'aides à la rénovation énergétique — Barèmes 2026"

**10 écrans Typeform** : Localisation → Type bien → Âge → Statut → Foyer → RFR → DPE → Parcours → Travaux → Budget

**Résultats** :
- Hero dégradé dynamique selon profil Anah (Bleu / Jaune / Violet / Rose)
- Aperçu gratuit : cards MPR + CEE
- **Bloc capture** : "Téléchargez votre rapport d'aides personnalisé" → Prénom + Email → PDF 5 pages via Worker
- Tableau déverrouillé : MPR, CEE, éco-PTZ, TVA, Écrêtement, RAC
- Alertes personnalisées

**Double envoi** : Formspree (lead CRM) + Worker PDF (téléchargement immédiat)

### Estimateur (`estimateur-outil.html`)

**8 écrans Typeform** → fourchette gratuite → paywall 49 € (Stripe Payment Link)

**Stripe à configurer** (ligne ~1042) :
```javascript
const STRIPE_PAYMENT_LINK = "https://buy.stripe.com/REMPLACER";
```
Success URL : `https://adora-economie.fr/paiement-reussi.html`

### Audit achat (`audit-formulaire.html`)

**10 écrans Typeform** incluant 4 uploads (DDT, DPE, photos) → récapitulatif 499 € → paiement différé par email

### Sur mesure (`sur-mesure.html`)

1. **Estimation détaillée** : périmètre, process 4 étapes, 6 livrables, prix "à partir de 990 € TTC", CTA contact
2. **Packs Accompagnement** : Essentiel 2 200 € / Confort 3 900 € / Sérénité 5-8%
3. **Bloc Pro** : bandeau navy simplifié → renvoi `professionnels.html`
4. **Qui suis-je** : portrait photo + parcours + stats
5. **Formulaire contact** : Formspree `maqaewbn` (staging)

### Professionnels (`professionnels.html`)

TJM affichés : Métrés 380 € · CCTP/DPGF 380 € · OPC 420-450 € · AMO 450 € · Mission longue 360 €

Outils maîtrisés (8 chips), livrables types (8 chips), process 3 étapes, portrait CTA.

### À propos (`a-propos.html`)

Timeline parcours (2009→2026), 3 valeurs (transparence, digital, indépendance), 4 stats, référence 136 m² (-12%), portrait photo.

## Stack technique

| Composant | Outil | Détails |
|---|---|---|
| Hébergement | GitHub Pages | staging = ce repo, prod = `aymericdussauze/adora` |
| DNS | OVH | 4× A records → GitHub + CNAME www |
| Analytics | GA4 | `G-M0LENY960B` |
| Paiement | Stripe Payment Links | No-code, pas de backend |
| Formulaires staging | Formspree | `maqaewbn` |
| Formulaires prod | Formspree | `xzdjopya` |
| PDF | Cloudflare Worker + PDFShift | `adora-pdf.aymericdussauze.workers.dev` |
| Code | HTML/CSS/JS vanilla | Single-file par page, Google Fonts |

## Déploiement en production

1. Remplacer `<base href="...adora-staging/">` par `<base href="https://adora-economie.fr/">` dans les **11 fichiers HTML**
2. Remplacer Formspree `maqaewbn` par `xzdjopya`
3. Configurer Stripe Payment Link (estimateur-outil.html)
4. Copier tous les fichiers dans `aymericdussauze/adora` (branche `main`)
5. Push → GitHub Pages déploie sous 1-2 min

## Arborescence

```
adora-staging/
├── index.html                  # Homepage
├── simulateur.html             # Simulateur aides → PDF Worker
├── estimateur.html             # Landing estimateur
├── estimateur-outil.html       # Estimateur → Stripe 49 €
├── paiement-reussi.html        # Confirmation post-Stripe
├── audit-avant-achat.html      # Landing audit
├── audit-formulaire.html       # Formulaire audit
├── sur-mesure.html             # Estimation détaillée + packs
├── a-propos.html               # Parcours & philosophie
├── professionnels.html         # Offre freelance + TJM
├── blog.html                   # (à créer)
└── README.md                   # Ce fichier
```

## Contact

**ADORA** — Aymeric Dussauze
Économiste de la construction · EI · SIRET 532 886 918 00020
TVA non applicable, art. 293B du CGI
06 60 21 55 09 · aymericdussauze@gmail.com
