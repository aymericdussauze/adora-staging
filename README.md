# ADORA — Préprod / Staging

> **Ce repo est un environnement de recette.** Ne pas diffuser l'URL.

## URL de prévisualisation

🔗 `https://aymericdussauze.github.io/adora-staging/`

## Pages à tester

| Page | URL | Statut |
|------|-----|--------|
| Homepage | `/index.html` | Refaite |
| Simulateur aides | `/simulateur.html` | Nav + CTA mis à jour |
| Estimateur (landing) | `/estimateur.html` | Nouvelle page |
| Estimateur (formulaire) | `/estimateur-outil.html` | Nav mise à jour |
| Audit avant achat (landing) | `/audit-avant-achat.html` | Nouvelle page |
| Audit (formulaire) | `/audit-formulaire.html` | Nouvelle page |
| Sur mesure / AMO | `/sur-mesure.html` | Nouvelle page |

## Bloquants avant mise en production

- [ ] Brancher Stripe (checkout 49 €)
- [ ] Acheter + calibrer référentiel Batichiffrage (538 € HT)
- [ ] Retravailler formulaire audit
- [ ] Recette complète (55 points de contrôle)

## Déploiement en production

Une fois la recette validée :
1. Copier les fichiers vers le repo `adora` (branche `main`)
2. Retirer la bannière PREPROD
3. Reconvertir les chemins relatifs en absolus (`/simulateur.html`)
4. Push + vérifier GitHub Pages
5. Soumettre nouvelles URLs dans Search Console
