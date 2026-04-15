# ADORA — Staging

**Environnement de staging** pour le site [adora-economie.fr](https://adora-economie.fr)

🔗 **Preview** : [aymericdussauze.github.io/adora-staging](https://aymericdussauze.github.io/adora-staging/)

---

## À propos

Site vitrine et outils en ligne d'**ADORA — Économiste de la construction**, cabinet indépendant en Normandie (27/76) et Île-de-France.

- Estimations TCE, CCTP/DPGF, AMO pour particuliers et professionnels
- Outils en ligne : simulateur d'aides rénovation, estimateur de travaux, audit avant achat
- Tunnel de conversion : gratuit → 49 € → 499 € → AMO sur mesure

## Pages

| Fichier | Page | Description |
|---|---|---|
| `index.html` | Homepage | Landing page principale — tunnel vers outils et prestations |
| `simulateur.html` | Simulateur aides | Outil interactif : MaPrimeRénov', CEE, éco-PTZ, TVA réduite (barèmes Anah 2026) |
| `estimateur.html` | Estimateur (landing) | Page de présentation de l'estimateur TCE — formules gratuit / 49 € |
| `estimateur-outil.html` | Estimateur (outil) | Outil interactif : estimation par 15 lots, coefficients régionaux, rapport PDF |
| `audit-avant-achat.html` | Audit achat (landing) | Page de présentation de l'audit avant achat — 499 € |
| `audit-formulaire.html` | Audit achat (formulaire) | Formulaire de demande avec upload de documents (Formspree) |
| `sur-mesure.html` | Sur mesure | Prestations, packs AMO, profil, formulaire de contact |

## Design System v2 — PropTech B2C

Refonte UI/UX d'avril 2026 appliquant les codes des startups PropTech/FinTech (Airbnb, Alan, Zillow, Matera).

### Principes
- **Problem-first** : le hero part du problème utilisateur, pas des services
- **Data-viz** : KPIs animés, count-up, comparaisons chiffrées contextualisées
- **Micro-interactions** : scroll reveal, hover lift, progress bar, transitions cubic-bezier
- **Mobile-first** : nav burger, sections responsive, CTA sticky

### Typographie
- **Headings** : Montserrat 700/800/900 (Google Fonts)
- **Body** : Plus Jakarta Sans 400–800 (Google Fonts)

### Couleurs
| Token | Hex | Usage |
|---|---|---|
| `--navy` | `#1B3A5C` | Headings, nav, hero background |
| `--blue` | `#2E75B6` | Liens, accents secondaires |
| `--accent` | `#D4740B` | CTAs, prix, highlights |
| `--green` | `#2D8B55` | Validations, simulateur CTA |
| `--light` | `#D6E4F0` | Texte clair sur fond sombre |
| `--pale` | `#F4F7FB` | Fond sections alternées |
| `--txt` | `#1E293B` | Texte principal |
| `--muted` | `#64748B` | Texte secondaire |

### Composants unifiés
- **Nav** : sticky, backdrop-blur, burger mobile, CTA accent, lien actif orange
- **Footer** : 3 colonnes (marque / liens / contact), fond `#0D1F33`
- **Cards** : border-radius 16px, shadow-on-hover, lift translateY(-4px)
- **Boutons** : radius 10px, shadow accent, hover lift
- **Scroll progress** : barre accent fixe en haut (3px)
- **Scroll reveal** : IntersectionObserver, fade-in + slide-up, single-fire

## Stack technique

- **Hébergement** : GitHub Pages (ce repo = staging)
- **Production** : [aymericdussauze/adora](https://github.com/aymericdussauze/adora) → adora-economie.fr
- **DNS** : OVH (4× A records → GitHub + CNAME www)
- **Analytics** : GA4 (`G-M0LENY960B`)
- **Formulaires** : Formspree (`xzdjopya`)
- **Pas de framework** : HTML/CSS/JS vanilla, single-file par page

## Déploiement en production

Quand le staging est validé :

1. Remplacer `<base href="https://aymericdussauze.github.io/adora-staging/">` par `<base href="https://adora-economie.fr/">` dans les 7 fichiers
2. Copier les fichiers dans le repo `aymericdussauze/adora` (branche `main`)
3. Push → GitHub Pages redéploie automatiquement sous 1-2 min

## Contact

**ADORA** — Aymeric Dussauze
Économiste de la construction · EI · SIRET 532 886 918 00020
06 60 21 55 09 · aymericdussauze@gmail.com
