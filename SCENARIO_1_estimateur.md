# Scénario 1 — Estimateur 49 € (Stripe Paywall)

**Objectif** : quand un client paie 49 € sur Stripe, il reçoit automatiquement son rapport PDF d'estimation par email, et tu reçois une notification de vente.

---

## 🏗 Architecture du scénario

```
[Webhook Stripe]
     ↓
[Filter: paiement = 49€ validé]
     ↓
[Google Sheets: retrouver les données projet par email]
     ↓
[PDF.co: générer le rapport PDF]
     ↓
[Gmail: envoyer au client avec PDF]
     ↓
[Gmail: notif interne]
```

---

## 📝 Étape 1 — Préparation : Google Sheet tampon

Make a besoin de récupérer les données de l'estimation au moment du webhook Stripe. Stripe ne contient que l'email et le montant, pas les détails du projet. Il faut donc un **tampon** où ces données sont stockées avant le paiement.

**Pourquoi ?** Quand le client clique "Obtenir mon rapport 49 €", le site envoie les données à Formspree, puis redirige vers Stripe. On doit stocker ces données quelque part pour les retrouver après le paiement.

### 1.1 Créer la Google Sheet

1. Aller sur [Google Sheets](https://sheets.google.com)
2. Créer une nouvelle feuille : **"ADORA — Estimations en attente"**
3. Copier-coller cet en-tête en ligne 1 :

```
Date | Email | Prenom | Projet | Type_bien | Surface | Dept | Dept_nom | Annee | Etat | Gamme | Amiante | Plomb | Acces_difficile | Estimation_low | Estimation_mid | Estimation_high | GO_total | SO_total | TE_total | Lots_detail | Status_paiement | PDF_url
```

4. Noter l'URL de la feuille (on en a besoin).

### 1.2 Scénario pré-paiement (AVANT le scénario principal)

Il faut créer **un mini-scénario qui capture l'email envoyé par Formspree au moment de "proceedToPayment"** et l'ajoute dans la Google Sheet.

**Module 1 — Email Watcher**
- `Email → Watch emails`
- Folder : INBOX
- Filter :
  - Subject contains : `[Estimateur Pro]`
  - From : `no-reply@formspree.io`

**Module 2 — Parse JSON depuis le body**
Formspree envoie un email avec le JSON des données. Il faut l'extraire.

- `Tools → Run JavaScript` (ou `Text parser → Match pattern`)
- Extraire tous les champs : `prenom`, `email`, `projet`, `type_bien`, `surface`, etc.

**Module 3 — Google Sheets**
- `Google Sheets → Add a row`
- Spreadsheet : "ADORA — Estimations en attente"
- Mapper toutes les colonnes
- `Status_paiement` = "En attente"

**Exécution** : toutes les 15 minutes.

> 💡 **Astuce** : si Formspree envoie directement en JSON dans le body, utilise `JSON → Parse JSON`. Sinon, c'est du HTML parsé par `Text parser`.

---

## 📝 Étape 2 — Scénario principal : Webhook Stripe

### 2.1 Créer le scénario

1. Make → **Create a new scenario**
2. Cliquer sur le gros **+** central
3. Chercher **"Webhooks"** → sélectionner **"Custom webhook"**

### 2.2 Configurer le webhook

1. Cliquer **Add**
2. Webhook name : `Stripe - Paiement estimateur`
3. Cliquer **Save**
4. Make affiche une URL du type : `https://hook.eu2.make.com/abc123xyz`
5. **Copier cette URL** — elle va dans Stripe

### 2.3 Connecter Stripe au webhook Make

1. Dashboard Stripe → **Developers** → **Webhooks**
2. **Add endpoint**
3. Endpoint URL : coller l'URL Make
4. Description : `Make - ADORA - Post-paiement estimateur`
5. Events to send : cocher uniquement **`checkout.session.completed`**
6. **Add endpoint**

### 2.4 Tester la réception

1. Dans Stripe → onglet du webhook créé → **Send test webhook**
2. Sélectionner `checkout.session.completed`
3. Cliquer **Send test webhook**
4. Retour dans Make : le module devrait afficher "Successfully determined" avec les données

### 2.5 Module 2 — Filter "paiement validé 49€"

1. Cliquer entre le module 1 et le suivant
2. **Set up a filter**
3. Label : `Paiement valide 49€`
4. Condition :
   ```
   type [equal to (case sensitive)] checkout.session.completed
   AND
   data.object.payment_status [equal to] paid
   AND
   data.object.amount_total [numeric: equal to] 4900
   ```
   (4900 = 49,00 € en centimes)

### 2.6 Module 3 — Google Sheets : Search Rows

On cherche l'entrée correspondante dans la Google Sheet tampon.

1. Ajouter `Google Sheets → Search rows`
2. Connection : autoriser ton compte Google
3. Spreadsheet : "ADORA — Estimations en attente"
4. Sheet : Sheet1
5. Filter :
   - Column : `Email`
   - Operator : `Text: Equal to`
   - Value : `{{1.data.object.customer_details.email}}`
6. Max returned : 1 (le plus récent)
7. Order by : Date DESC

### 2.7 Module 4 — PDF.co : génération du PDF

1. Ajouter `PDF.co → Convert HTML to PDF`
2. Connection :
   - Connection name : `PDF.co ADORA`
   - API Key : coller la clé récupérée sur pdf.co
3. HTML template : coller le contenu de `/templates/pdf_estimation.html`

**IMPORTANT — Mapping des variables Mustache**

Remplace chaque `{{variable}}` du template par le mapping Make correspondant :

| Variable template | Source Make |
|---|---|
| `{{prenom}}` | `{{3.Prenom}}` (Google Sheets) |
| `{{estimation_low}}` | `{{3.Estimation_low}}` |
| `{{estimation_high}}` | `{{3.Estimation_high}}` |
| `{{surface}}` | `{{3.Surface}}` |
| `{{dept_nom}}` | `{{3.Dept_nom}}` |
| `{{dept}}` | `{{3.Dept}}` |
| `{{gamme_label}}` | `{{3.Gamme}}` (à formater : eco → Économique, etc.) |
| `{{today}}` | `{{formatDate(now; "DD/MM/YYYY")}}` |
| `{{lots_rows}}` | HTML des 15 lignes du tableau — voir ci-dessous |
| `{{alertes_html}}` | HTML des 3 alertes — voir ci-dessous |

**Pour `{{lots_rows}}`** : dans la Google Sheet, la colonne `Lots_detail` contient un JSON stringifié. Il faut le parser et générer les lignes HTML.

**Ajouter un module avant PDF.co** :
- `Tools → Set variable`
- Variable name : `lotsHtml`
- Value : utiliser une fonction JavaScript ou `map()` Make pour transformer le JSON en HTML

**Exemple de rendu attendu** (à générer via un module intermédiaire) :
```html
<tr><td><span class="lot-id">01</span></td><td>Démolition / Curage</td><td>1 275 €</td><td>1 725 €</td></tr>
<tr><td><span class="lot-id">02</span></td><td>Gros-œuvre</td><td>6 800 €</td><td>9 200 €</td></tr>
...
```

4. PDF settings :
   - Page size : A4
   - Orientation : Portrait
   - Margins : already in template CSS
5. Output name : `ADORA_Estimation_{{3.Prenom}}_{{formatDate(now; "YYYYMMDD")}}.pdf`

### 2.8 Module 5 — Gmail : envoi au client

1. Ajouter `Gmail → Send an email`
2. Connection : autoriser aymericdussauze@gmail.com
3. Config :
   - **To** : `{{1.data.object.customer_details.email}}`
   - **Subject** : `Votre rapport d'estimation ADORA — {{3.Prenom}}`
   - **Content type** : HTML
   - **Content** : coller le contenu de `/templates/email_estimation.html` avec les variables mappées
   - **Attachments** :
     - File name : `{{4.name}}`
     - Data : `{{4.url}}` (URL générée par PDF.co) — utiliser le module `HTTP → Get a file` d'abord si besoin

### 2.9 Module 6 — Gmail : notification interne

1. Ajouter `Gmail → Send an email`
2. Config :
   - **To** : `aymericdussauze@gmail.com`
   - **Subject** : `🎉 Vente 49€ — {{3.Prenom}} ({{3.Email}}) · {{3.Estimation_low}}-{{3.Estimation_high}}`
   - **Content** :
     ```html
     <h3>Nouvelle vente estimateur 49€</h3>
     <p><strong>Client</strong> : {{3.Prenom}} - {{3.Email}}</p>
     <p><strong>Projet</strong> : {{3.Projet}} · {{3.Type_bien}} · {{3.Surface}} m²</p>
     <p><strong>Localisation</strong> : {{3.Dept_nom}} ({{3.Dept}})</p>
     <p><strong>Estimation</strong> : {{3.Estimation_low}} — {{3.Estimation_high}}</p>
     <p><strong>Stripe session</strong> : {{1.data.object.id}}</p>
     <p><strong>Montant reçu</strong> : 49 €</p>
     <hr>
     <p>⏰ <strong>À faire dans 48h</strong> : appeler le client pour débriefer son estimation.</p>
     ```

### 2.10 Module 7 (optionnel) — Mise à jour Google Sheet

Pour garder une trace que le PDF a été envoyé :

1. `Google Sheets → Update a row`
2. Row number : `{{3.__ROW_NUMBER__}}`
3. Update :
   - `Status_paiement` → "Payé et PDF envoyé"
   - `PDF_url` → `{{4.url}}`

---

## 🧪 Étape 3 — Tester le scénario complet

### Test A — Flow complet en sandbox Stripe

1. Sur le site staging (adora-staging), remplir l'estimateur
2. Arriver à la page checkout avec prénom + email de test
3. Cliquer "Obtenir mon rapport"
4. Payer avec la carte de test Stripe : `4242 4242 4242 4242` (CVV : 123, date : n'importe)
5. Attendre la redirection vers `paiement-reussi.html`
6. Vérifier dans Make → **History** que le scénario s'est exécuté
7. Vérifier l'email de test → tu dois avoir reçu le PDF

### Test B — Debug si ça ne marche pas

**Pas de déclenchement ?**
- Vérifier Stripe → Webhooks → clique sur ton endpoint → onglet "Recent deliveries"
- Si 200 OK → Make a bien reçu, vérifier les filters
- Si 4xx/5xx → problème URL webhook

**Données projet non trouvées ?**
- Vérifier la Google Sheet tampon → l'entrée doit exister
- Vérifier que le champ email Stripe = email Formspree

**PDF illisible ?**
- Tester le HTML template dans PDF.co Playground : https://app.pdf.co/playground
- Ajuster les variables mal mappées

---

## 🎛 Paramètres du scénario

- **Scheduling** : Immediately (webhook = temps réel)
- **Max errors** : 3
- **Sequential processing** : Yes (éviter doublons)
- **Allow storing incomplete executions** : Yes (pour debug)

---

## 📊 Mesure de succès

Dans Make, chaque exécution consomme des "operations" :
- 1 webhook reçu = 1 op
- 1 filter = 0 op
- 1 Google Sheets search = 1 op
- 1 PDF.co = 1 op Make + 1 page PDF.co
- 2 Gmail = 2 ops

**Total par vente** : ~5 opérations Make + 1 page PDF.co

Avec plan gratuit Make (1 000 ops/mois) : tu peux gérer ~200 ventes/mois.
Avec plan gratuit PDF.co (100 pages/mois) : tu peux générer 100 PDF/mois.

Si tu dépasses : passer Make Pro (9 €/mois, 10 000 ops) + PDF.co Starter (15 $/mois, 1 000 pages) = ~23 €/mois pour ~1 000 ventes.
