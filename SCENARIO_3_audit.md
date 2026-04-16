# Scénario 3 — Audit achat 499 € (demande qualifiée)

**Objectif** : quand un prospect dépose une demande d'audit avec pièces jointes, tu reçois une notification structurée et lisible, et tu gardes une trace dans ton CRM.

**Note** : pas de génération de PDF ni d'envoi client automatique — tu valides manuellement la demande avant de déclencher le paiement Stripe.

---

## 🏗 Architecture du scénario

```
[Email Watcher: "[AUDIT 499€]"]
     ↓
[Parse du body + extraction des pièces jointes]
     ↓
[Filter: _formType = audit_499]
     ↓
[Gmail: notif interne structurée]
     ↓
[Google Sheets: ajout au CRM audits]
     ↓
[Gmail: email automatique de confirmation au client]
```

---

## 📝 Étape 1 — Préparation : Google Sheet CRM Audits

### 1.1 Créer la feuille

1. Google Sheets → **"ADORA — Demandes Audit"**
2. En-tête ligne 1 :

```
Date_reception | Prenom | Nom | Email | Telephone | Type_bien | Lien_annonce | Adresse | Surface | Prix | Annee | Contexte | Documents_joints | Status | Date_rappel | Date_paiement | Date_livraison
```

3. Créer une vue filtrée pour "Status = Nouveau" pour voir les demandes à traiter.

---

## 📝 Étape 2 — Créer le scénario Make

### 2.1 Module 1 — Watch Gmail

1. `Gmail → Watch emails`
2. Connection : aymericdussauze@gmail.com
3. Filters :
   - Subject contains : `[AUDIT 499€]`
   - From : `formspree.io`
4. Fetch attachments : **Yes** (important pour récupérer les DDT, DPE, photos)
5. Max results : 5

**Scheduling** : toutes les 10 minutes.

### 2.2 Module 2 — Extract données

Identique au scénario 2 : parser le body Formspree en mode Plain Text.

Fields extraits :
- `prenom`, `nom`, `email`, `telephone`
- `type_bien`, `lien_annonce`, `adresse`, `surface`, `prix`, `annee`
- `contexte`
- Liste des attachments via `{{1.attachments}}`

### 2.3 Module 3 — Filter "audit_499"

- Condition : `{{_formType}}` equal to `audit_499`

### 2.4 Module 4 — Notification interne détaillée

1. `Gmail → Send an email`
2. To : `aymericdussauze@gmail.com`
3. Priority : High
4. Subject : `🚨 NOUVELLE DEMANDE AUDIT 499€ — {{prenom}} {{nom}} ({{type_bien}})`
5. Content type : HTML
6. Content : coller `/templates/email_audit_notif.html` avec mapping :

| Variable | Source |
|---|---|
| `{{prenom}}` | `{{prenom}}` |
| `{{nom}}` | `{{nom}}` |
| `{{email}}` | `{{email}}` |
| `{{telephone}}` | `{{telephone}}` |
| `{{type_bien}}` | `{{type_bien}}` |
| `{{adresse}}` | `{{adresse}}` |
| `{{surface}}` | `{{surface}}` |
| `{{prix}}` | `{{prix}}` |
| `{{annee_label}}` | `{{annee_label}}` |
| `{{lien_annonce}}` | `{{lien_annonce}}` |
| `{{contexte}}` | `{{contexte}}` |
| `{{documents_list}}` | list générée |
| `{{today}}` | `{{formatDate(now; "DD/MM/YYYY HH:mm")}}` |

**Génération de `{{documents_list}}`** :

Utiliser un module `Tools → Set variable` avant l'envoi de l'email :

```javascript
// Concaténer les noms des attachments
const docs = attachments.map(a => `<li>${a.name} (${a.size})</li>`).join('');
return `<ul>${docs}</ul>`;
```

Ou, si la structure du body Formspree contient les noms de fichiers séparément :
- DDT : `{{ddt_filename}}`
- DPE : `{{dpe_filename}}`
- Photos ext : `{{photos_ext_count}} fichiers`
- Photos int : `{{photos_int_count}} fichiers`

7. **Attachments** : attacher tous les fichiers reçus via `{{1.attachments}}`

### 2.5 Module 5 — Google Drive : archivage des pièces jointes (optionnel mais recommandé)

Pour garder une trace des documents sans saturer ta boîte email :

1. `Google Drive → Upload a file`
2. Pour chaque attachment (via `Iterator`) :
   - Destination folder : créer un dossier `ADORA — Demandes Audit / {{prenom}}_{{nom}}_{{today}}`
   - File name : `{{attachment.name}}`
   - File data : `{{attachment.data}}`

### 2.6 Module 6 — Google Sheets : ajout au CRM

1. `Google Sheets → Add a row`
2. Spreadsheet : "ADORA — Demandes Audit"
3. Mapping :

```
Date_reception    → {{formatDate(now; "DD/MM/YYYY HH:mm")}}
Prenom            → {{prenom}}
Nom               → {{nom}}
Email             → {{email}}
Telephone         → {{telephone}}
Type_bien         → {{type_bien}}
Lien_annonce      → {{lien_annonce}}
Adresse           → {{adresse}}
Surface           → {{surface}} m²
Prix              → {{prix}} €
Annee             → {{annee_label}}
Contexte          → {{contexte}}
Documents_joints  → {{documents_summary}}
Status            → "Nouveau"
Date_rappel       → (vide)
Date_paiement     → (vide)
Date_livraison    → (vide)
```

### 2.7 Module 7 — Email de confirmation au client

Le client doit savoir que sa demande a bien été reçue, même si tu la traites manuellement :

1. `Gmail → Send an email`
2. To : `{{email}}`
3. Subject : `Votre demande d'audit ADORA a bien été reçue`
4. Content : email simple et chaleureux

**Contenu suggéré** :

```html
<h2>Bonjour {{prenom}},</h2>

<p>J'ai bien reçu votre demande d'audit avant achat pour le bien situé <strong>{{adresse}}</strong>.</p>

<p><strong>Je vous recontacte sous 24h ouvrées</strong> pour confirmer les modalités et le calendrier de l'audit.</p>

<h3>Comment ça va se passer ?</h3>
<ol>
  <li>Examen de votre dossier (annonce + documents joints)</li>
  <li>Appel téléphonique pour affiner votre besoin</li>
  <li>Envoi d'un lien de paiement sécurisé Stripe pour les 499 € TTC</li>
  <li>Démarrage de l'audit dans les 48-72h après paiement</li>
  <li>Livraison du rapport PDF + appel téléphonique de 30 min de débrief</li>
</ol>

<p>Si vous avez une contrainte de calendrier (compromis bientôt signé, promesse d'achat en cours...), merci de me le signaler dès maintenant au <strong>06 60 21 55 09</strong>.</p>

<p>À très vite,<br>
<strong>Aymeric Dussauze</strong><br>
Économiste de la construction · ADORA</p>
```

---

## 🧪 Étape 3 — Tester

### Test A — Soumission test complète

1. Site staging → audit-formulaire.html
2. Remplir les 10 écrans avec des données de test
3. Ajouter au moins 1 fichier PDF test (peut être n'importe lequel)
4. Soumettre
5. Attendre max 10 min
6. Vérifier :
   - Email notif interne reçu avec toutes les infos
   - Pièces jointes bien transmises
   - Ligne ajoutée dans Google Sheets
   - Email de confirmation reçu par le client

### Test B — Debug

**Les pièces jointes ne sont pas transmises ?**
- Vérifier que `Fetch attachments = Yes` dans le Watcher Gmail
- Vérifier la taille des fichiers (limite Gmail : 25 Mo)

**Email notif mal formaté ?**
- Tester le HTML dans un preview email (ex: https://mailtrap.io)
- Vérifier que les `{{#if}}` Handlebars fonctionnent dans Make (sinon remplacer par logique Make)

**Doublons ?**
- Activer `Sequential processing` dans les paramètres du scénario
- Garder `Mark as read` pour éviter de re-traiter les mêmes emails

---

## 🎯 Workflow post-demande (manuel)

Après réception de la notification, ton workflow humain :

1. **Ouvrir l'email de notif** (prend 30 secondes à scanner)
2. **Cliquer sur le lien de l'annonce** → examen rapide
3. **Ouvrir les pièces jointes** → analyse préliminaire
4. **Décider** :
   - ✅ Demande valide → appeler le client pour validation
   - ⚠️ Demande incomplète → email pour demander compléments
   - ❌ Hors zone / non pertinent → refus poli

5. **Créer le Payment Link Stripe** :
   - Dashboard → Payment Links → Create
   - Produit : "Audit avant achat ADORA - 499€"
   - Metadata : prenom, email, adresse_bien
   - Copier URL
6. **Envoyer le lien au client** par email (modèle pré-rédigé conseillé)
7. **Mettre à jour Google Sheets** : Status → "Paiement demandé" + Date_rappel

---

## 📊 Indicateurs à suivre

Dans la Google Sheet, tu peux ajouter des formules pour tracker :

- **Taux de conversion** demande → paiement : `COUNTIF(Status,"Payé") / COUNTA(Date_reception)`
- **Temps moyen de traitement** : différence moyenne entre `Date_reception` et `Date_paiement`
- **Taux de signature du bien** (si tu demandes l'info après livraison) : indicateur de valeur réelle apportée

Ces indicateurs sont précieux pour ajuster ta prospection et ton pricing.

---

## 🚀 Optimisations possibles (v2)

1. **Création automatique du Stripe Payment Link** via API Stripe (module `Stripe → Create a Payment Link`)
2. **Intégration Notion CRM** : synchronisation directe avec ton CRM Notion (`collection://7447e146-d599-4575-b9bb-2ec0a5c5a391`)
3. **Slack/Discord notification** : au lieu d'email interne, envoyer dans un canal dédié
4. **Analyse auto de l'annonce** via un scraper (nécessite un module HTTP et du parsing)
