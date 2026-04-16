# Configuration Make pour ADORA — Guide complet

Ce document détaille la configuration des 3 scénarios Make nécessaires au fonctionnement du site.

## 🎯 Prérequis

- [ ] **Compte Make** — https://www.make.com (plan Core gratuit : 1 000 ops/mois)
- [ ] **Compte PDF.co** — https://pdf.co (100 pages PDF/mois gratuit)
- [ ] **Compte Formspree** actif (déjà fait : `xzdjopya`)
- [ ] **Compte Stripe** actif avec Payment Link créé (déjà fait)
- [ ] **Gmail** (aymericdussauze@gmail.com) pour connexion à Make

---

## 🔧 Étape 1 — Configuration PDF.co

1. Aller sur https://app.pdf.co/dashboard
2. Créer un compte (email + password)
3. Dans le dashboard, aller dans **API Key** → copier la clé (format `xxx@xxx.com_xxxxxxx`)
4. **Conserver cette clé** — elle sera collée dans Make

---

## 🔧 Étape 2 — Configuration Stripe Webhook

Make va recevoir les événements Stripe via un webhook. Il faut donc créer ce webhook côté Stripe.

1. Dashboard Stripe → **Developers** → **Webhooks** → **Add endpoint**
2. **URL à renseigner** : celle générée par Make (on la créera à l'étape 4)
3. **Events to listen for** : cocher uniquement `checkout.session.completed`
4. **NE PAS CRÉER MAINTENANT** — on reviendra ici après avoir créé le scénario Make

---

## 🔧 Étape 3 — Formspree : activer le webhook vers Make

Formspree doit envoyer les soumissions vers Make.

1. Dashboard Formspree → Forms → cliquer sur ton form `xzdjopya`
2. Aller dans **Plugins** → **Webhooks** (peut nécessiter plan Gold à 10$/mois)
3. **Alternative gratuite** : utiliser le module Formspree natif dans Make (connexion API)
4. Ou **solution la plus simple** : utiliser **Email Parser** de Make — Make reçoit les emails envoyés par Formspree à ton adresse et parse leur contenu

**Je recommande l'option Email Parser** : gratuite, fiable, déjà en place sans rien modifier côté Formspree.

---

## 📦 Scénario 1 — Estimateur 49 € (Stripe paywall)

### Déclencheur
**Module** : `Webhooks → Custom webhook`

### Flow

```
[1] Webhook Stripe (checkout.session.completed)
    ↓
[2] Filter : ne traiter que les paiements réussis + produit estimateur
    ↓
[3] Email Parser / Formspree API : retrouver les données projet du client
    ↓
[4] PDF.co : Générer le PDF depuis template HTML
    ↓
[5] Gmail : Envoyer email au client avec PDF en pièce jointe
    ↓
[6] Gmail : Notif interne à aymericdussauze@gmail.com
```

### Configuration pas à pas

**Module 1 — Webhook Stripe**
- Type : `Custom webhook`
- Nom : `Stripe - Paiement estimateur`
- Cliquer **Add** → copier l'URL générée (format `https://hook.eu2.make.com/xxxxx`)
- Cette URL va dans le webhook Stripe (Étape 2 ci-dessus)

**Module 2 — Filter**
- Condition 1 : `type` → `text equal to` → `checkout.session.completed`
- Condition 2 : `data.object.payment_status` → `text equal to` → `paid`
- Condition 3 : `data.object.amount_total` → `numeric equal to` → `4900` (= 49,00 €)

**Module 3 — Récupération des données projet**

Deux options selon ce que tu as mis en place :

*Option A : si tu utilises Email Parser pour Formspree*
- Module : `Email → Watch emails`
- Filtrer sur `_formType: estimateur_payant`
- Matcher par email avec `customer_email` de Stripe

*Option B : Google Sheets en tampon (plus fiable)*
- Ajouter un module avant Stripe : quand Formspree envoie (via Email Parser), stocker dans Google Sheet
- Au webhook Stripe : module `Google Sheets → Search rows` pour retrouver l'entrée par email
- Récupérer toutes les données de la simulation

**Module 4 — PDF.co : génération du PDF**
- Module : `PDF.co → Convert HTML to PDF`
- API Key : celle de l'étape 1
- HTML : coller le template (fichier `/templates/pdf_estimation.html` fourni)
- Utiliser les variables `{{prenom}}`, `{{surface}}`, `{{dept_nom}}`, `{{estimation_low}}`, etc.
- Output name : `ADORA_Estimation_{{prenom}}_{{today}}.pdf`

**Module 5 — Gmail : envoi au client**
- Module : `Gmail → Send an email`
- To : `{{customer_email}}` (depuis Stripe)
- Subject : `Votre rapport d'estimation ADORA — {{prenom}}`
- Body : HTML (template fourni dans `/templates/email_estimation.html`)
- Attachments : le PDF généré au module 4
- From : aymericdussauze@gmail.com

**Module 6 — Notification interne**
- Module : `Gmail → Send an email`
- To : `aymericdussauze@gmail.com`
- Subject : `🎉 Vente estimateur 49€ — {{prenom}} ({{customer_email}})`
- Body : résumé de la vente avec lien vers le PDF

---

## 📦 Scénario 2 — Simulateur aides (Lead magnet gratuit)

### Déclencheur
**Module** : `Email → Watch emails` (via Gmail connecté à Make)

### Flow

```
[1] Watch Gmail (filtre sur subject [Simulateur aides])
    ↓
[2] Parse email content → extraire les variables
    ↓
[3] Filter : _formType = simulateur_gratuit
    ↓
[4] PDF.co : Générer le rapport PDF aides
    ↓
[5] Gmail : Envoyer au prospect avec PDF
    ↓
[6] Google Sheets : Ajouter le lead dans un tableau CRM
```

### Configuration pas à pas

**Module 1 — Watch Gmail**
- Module : `Gmail → Watch emails`
- Folder : `INBOX`
- Filter : `Subject contains: [Simulateur aides]` ET `From: no-reply@formspree.io`
- Max emails : 10 par exécution
- Interval : 15 minutes

**Module 2 — Text parser**
- Module : `Text parser → Match pattern`
- Pattern : extraire les champs du body de l'email Formspree
- Formspree envoie un email formaté : parser pour récupérer `prenom`, `email`, `profil_anah`, etc.

**Alternative plus simple : JSON parse**
Si Formspree envoie bien le JSON dans le body (à vérifier), utiliser `JSON → Parse JSON`

**Module 3 — Filter**
- Condition : `_formType` → `text equal to` → `simulateur_gratuit`

**Module 4 — PDF.co**
- Template : `/templates/pdf_simulateur.html`
- Variables : `{{prenom}}`, `{{profil_anah}}`, `{{mpr_estimee}}`, `{{cee_min}}`, `{{cee_max}}`, `{{eco_ptz_max}}`, `{{aides_finales}}`, `{{reste_a_charge}}`, `{{travaux_envisages}}`

**Module 5 — Gmail envoi prospect**
- To : `{{email}}`
- Subject : `Votre simulation d'aides rénovation — {{prenom}}`
- Body : template email simulateur (dans `/templates/email_simulateur.html`)
- Attachment : PDF généré

**Module 6 — Google Sheets (CRM leads)**
- Créer d'abord une Google Sheet "ADORA — Leads Simulateur" avec colonnes :
  - Date / Prénom / Email / Localisation / Profil Anah / Budget / Aides estimées / Statut
- Module Make : `Google Sheets → Add a row`
- Mapper les variables

---

## 📦 Scénario 3 — Audit achat 499 € (demande qualifiée)

### Déclencheur
**Module** : `Email → Watch emails` (filtre sur `[AUDIT 499€]`)

### Flow

```
[1] Watch Gmail (filtre [AUDIT 499€])
    ↓
[2] Parse content → extraire données
    ↓
[3] Filter : _formType = audit_499
    ↓
[4] Gmail : Notif interne à Aymeric (URGENT)
    ↓
[5] Stripe : Créer un Payment Link personnalisé 499 €
    ↓
[6] (Manuel) Aymeric valide la demande et envoie le lien Stripe
```

### Configuration pas à pas

**Module 1-3** : identique au scénario 2 mais avec filter `_formType = audit_499`

**Module 4 — Notification interne prioritaire**
- Module : `Gmail → Send an email`
- To : `aymericdussauze@gmail.com`
- Priority : High
- Subject : `🚨 NOUVELLE DEMANDE AUDIT 499€ — {{prenom}} {{nom}}`
- Body : toutes les infos du bien + lien vers le bien s'il y a une URL d'annonce + pièces jointes
- Si uploads présents, lister les fichiers

**Module 5 — Stripe Payment Link (optionnel, à valider)**
- Module : `Stripe → Create a Payment Link`
- Product : Audit avant achat 499 €
- Metadata : `{prenom, email, telephone, adresse_bien}`
- Success URL : `https://adora-economie.fr/paiement-reussi.html`

**Module 6 — Manuel**
Après examen des documents, tu envoies manuellement le Payment Link créé au client.

---

## 🎨 Templates PDF et Email

Les templates sont fournis dans le dossier `/templates/` :

```
make/
├── README.md                      # Ce fichier
└── templates/
    ├── pdf_estimation.html        # Template PDF rapport 49€
    ├── pdf_simulateur.html        # Template PDF aides gratuit
    ├── email_estimation.html      # Email client estimateur payant
    ├── email_simulateur.html      # Email prospect simulateur
    └── email_audit_notif.html     # Email notif interne audit
```

Chaque template utilise la syntaxe `{{variable}}` de Make (Mustache-like).

---

## 🧪 Tests recommandés

### Test 1 — Estimateur end-to-end
1. Sur le site staging, remplir l'estimateur jusqu'au bout
2. Cliquer "Obtenir mon rapport 49 €"
3. Faire un paiement test Stripe (carte `4242 4242 4242 4242`)
4. Vérifier que le scénario Make se déclenche (dashboard Make)
5. Vérifier réception PDF à l'email de test
6. Vérifier réception notif interne

### Test 2 — Simulateur
1. Remplir le simulateur jusqu'à unlock
2. Saisir email de test
3. Attendre 15 min (cycle Watch Gmail)
4. Vérifier réception du PDF aides à l'email

### Test 3 — Audit
1. Remplir le formulaire audit
2. Joindre un fichier PDF test
3. Soumettre
4. Vérifier notif interne avec tous les détails

---

## 💰 Coûts estimés

| Service | Plan | Prix/mois | Limite |
|---|---|---|---|
| Make | Core | **Gratuit** | 1 000 ops/mois |
| Make | Pro | 9 €/mois | 10 000 ops/mois |
| PDF.co | Free | **Gratuit** | 100 pages/mois |
| PDF.co | Starter | 15 $/mois | 1 000 pages/mois |
| Formspree | Basic | **Gratuit** | 50 soumissions/mois |
| Formspree | Gold | 10 $/mois | Illimité + webhooks |

**Coût au démarrage : 0 €/mois** si trafic limité.
**Dès que tu dépasses** : passer à Make Pro (9 €) + PDF.co Starter (15 $) = ~23 €/mois.

Pour un estimateur à 49 €/vente et une marge de ~95% sur le flow no-code, 1 vente/mois suffit à rentabiliser.

---

## 📞 Si tu bloques

1. Documentation Make : https://www.make.com/en/help
2. Documentation PDF.co : https://developer.pdf.co/
3. Communauté Make (française) : https://www.make.com/en/community
