# Scénario 2 — Simulateur aides (Lead magnet gratuit)

**Objectif** : quand un prospect laisse son email sur le simulateur, il reçoit automatiquement un PDF détaillé de ses aides, et tu récupères le lead dans ton CRM Google Sheets.

---

## 🏗 Architecture du scénario

```
[Email Watcher: "[Simulateur aides]"]
     ↓
[Parse JSON du body]
     ↓
[Filter: _formType = simulateur_gratuit]
     ↓
[PDF.co: générer le rapport PDF aides]
     ↓
[Gmail: envoyer au prospect avec PDF]
     ↓
[Google Sheets: ajouter le lead au CRM]
```

---

## 📝 Étape 1 — Préparation : Google Sheet CRM

### 1.1 Créer la feuille de tracking des leads

1. Google Sheets → **"ADORA — Leads Simulateur"**
2. En-tête ligne 1 :

```
Date | Prenom | Email | Localisation | Profil_Anah | Menage | RFR | Type_logement | Age_logement | DPE | Parcours | Travaux | Budget_Travaux | MPR | CEE_min | CEE_max | Eco_PTZ | Aides_finales | RAC | Status | Note_Aymeric
```

3. Noter l'URL de la feuille.

---

## 📝 Étape 2 — Créer le scénario Make

### 2.1 Module 1 — Watch Gmail

1. Make → **Create a new scenario**
2. Ajouter `Gmail → Watch emails`
3. Connection : aymericdussauze@gmail.com
4. Folder : `INBOX`
5. Filters :
   - Subject contains : `[Simulateur aides]`
   - From email address contains : `formspree.io`
6. Max results : 10
7. Mark message as read : **No** (garder trace pour debug)

**Scheduling** : toutes les 5 min.

### 2.2 Module 2 — Extract JSON du body email

Formspree envoie un email avec les données au format variable (selon plan). Il y a 2 cas :

**Cas A — Formspree Free** : email HTML avec tableau de champs
→ utiliser `Text parser → Match pattern`

**Cas B — Formspree Gold** : body en JSON
→ utiliser `JSON → Parse JSON`

Je traite le **Cas A** (free) en priorité, car c'est ton cas actuel :

1. Ajouter `Text parser → Match pattern`
2. Pattern : `(?ms)<td.*?>(.*?)<\/td>\s*<td.*?>(.*?)<\/td>`
3. Source : `{{1.text}}` ou `{{1.html}}`
4. Global match : Yes

**Alternative plus simple** : Formspree peut être configuré pour envoyer l'email au format "plain text" avec `Key: Value` par ligne.

Va dans Formspree dashboard → Settings → **Plain text email format : ON**.

Alors chaque ligne est du format :
```
prenom: Marie
email: marie@example.com
_formType: simulateur_gratuit
profil_anah: Jaune
aides_finales: 9 890 €
...
```

Avec ce format, tu peux utiliser `Text parser → Match pattern` avec le pattern :
```
(?m)^(\w+):\s*(.+)$
```

Pour chaque match, tu obtiens un `{key: value}` que tu mappes ensuite.

**Méthode recommandée — Iterator** :
- Module `Flow control → Iterator` sur l'output du parser
- Puis `Tools → Set multiple variables` pour stocker chaque key/value

### 2.3 Module 3 — Filter "simulateur_gratuit"

1. Label : `Type = simulateur_gratuit`
2. Condition : `{{_formType}}` equal to `simulateur_gratuit`

### 2.4 Module 4 — PDF.co : générer le rapport

1. `PDF.co → Convert HTML to PDF`
2. Connection : celle créée au scénario 1 (réutilisable)
3. HTML : coller le contenu de `/templates/pdf_simulateur.html`
4. **Mapping des variables** :

| Variable template | Source Make |
|---|---|
| `{{prenom}}` | `{{prenom}}` |
| `{{profil_anah}}` | `{{profil_anah}}` |
| `{{profil_color}}` | à calculer : "Bleu" → "bleu", "Jaune" → "jaune", etc. (lowercase) |
| `{{profil_desc}}` | à mapper (voir table ci-dessous) |
| `{{localisation}}` | `{{localisation}}` |
| `{{type_logement}}` | `{{type_logement}}` |
| `{{age_logement}}` | `{{age_logement}}` |
| `{{statut}}` | `{{statut}}` |
| `{{menage}}` | `{{menage}}` |
| `{{revenu_fiscal}}` | `{{revenu_fiscal}}` |
| `{{dpe}}` | `{{dpe}}` |
| `{{parcours}}` | `{{parcours}}` |
| `{{travaux_envisages}}` | `{{travaux_envisages}}` |
| `{{budget_travaux}}` | `{{budget_travaux}}` |
| `{{mpr_estimee}}` | `{{mpr_estimee}}` |
| `{{cee_min}}` | `{{cee_min}}` |
| `{{cee_max}}` | `{{cee_max}}` |
| `{{eco_ptz_max}}` | `{{eco_ptz_max}}` |
| `{{tva_economie}}` | `{{tva_economie}}` |
| `{{aides_finales}}` | `{{aides_finales}}` |
| `{{reste_a_charge}}` | `{{reste_a_charge}}` |
| `{{total_aides_directes}}` | à calculer = MPR + CEE_moy + TVA |
| `{{alertes_html}}` | HTML à générer dynamiquement |
| `{{today}}` | `{{formatDate(now; "DD/MM/YYYY")}}` |

**Table de correspondance Profil → Description** (à créer dans un module `Set variable`) :

```javascript
// Via Tools → Set variable
const descriptions = {
  "Bleu": "Revenus très modestes — aides maximales",
  "Jaune": "Revenus modestes — aides élevées",
  "Violet": "Revenus intermédiaires — aides classiques",
  "Rose": "Revenus supérieurs — aides réduites"
};
return descriptions[profil_anah] || "";
```

**Génération des alertes HTML** : dans un module `Set variable`, construire une chaîne HTML avec les alertes pertinentes selon le profil et les travaux.

5. Output filename : `ADORA_Simulation_Aides_{{prenom}}_{{formatDate(now; "YYYYMMDD")}}.pdf`

### 2.5 Module 5 — Gmail : envoi au prospect

1. `Gmail → Send an email`
2. To : `{{email}}`
3. Subject : `Votre simulation d'aides rénovation — {{prenom}}`
4. Content type : HTML
5. Content : coller `/templates/email_simulateur.html` avec variables mappées
6. Attachments :
   - Name : `{{4.name}}`
   - Data : download via `HTTP → Get a file` avec URL `{{4.url}}`

### 2.6 Module 6 — Google Sheets : ajout au CRM

1. `Google Sheets → Add a row`
2. Spreadsheet : "ADORA — Leads Simulateur"
3. Sheet : Sheet1
4. Mapper les colonnes avec les variables extraites :

```
Date            → {{formatDate(now; "DD/MM/YYYY HH:mm")}}
Prenom          → {{prenom}}
Email           → {{email}}
Localisation    → {{localisation}}
Profil_Anah     → {{profil_anah}}
Menage          → {{menage}}
RFR             → {{revenu_fiscal}}
Type_logement   → {{type_logement}}
Age_logement    → {{age_logement}}
DPE             → {{dpe}}
Parcours        → {{parcours}}
Travaux         → {{travaux_envisages}}
Budget_Travaux  → {{budget_travaux}}
MPR             → {{mpr_estimee}}
CEE_min         → {{cee_min}}
CEE_max         → {{cee_max}}
Eco_PTZ         → {{eco_ptz_max}}
Aides_finales   → {{aides_finales}}
RAC             → {{reste_a_charge}}
Status          → "Rapport envoyé"
Note_Aymeric    → (laisser vide)
```

### 2.7 Module 7 (optionnel) — Notif interne

Pour certains profils intéressants (gros budgets, zones privilégiées), tu peux te notifier :

1. Ajouter un `Filter` :
   - Budget_Travaux > 50000 € OU Localisation = "Île-de-France"
2. Si match → `Gmail → Send an email`
   - To : aymericdussauze@gmail.com
   - Subject : `💡 Nouveau lead qualifié — {{prenom}} ({{budget_travaux}})`

---

## 🧪 Étape 3 — Tester

### Test A — Remplir le simulateur

1. Site staging → simulateur.html
2. Remplir les 10 écrans jusqu'au résultat
3. Dans le paywall : prénom "Test" + email `ton-email-test@gmail.com`
4. Cliquer "Débloquer mon rapport"
5. Attendre max 5 min (cycle Watch Gmail)
6. Vérifier Make → History → exécution avec succès
7. Vérifier réception email avec PDF

### Test B — Debug si problème

**Watcher ne se déclenche pas ?**
- Vérifier que Formspree envoie bien les emails (dashboard Formspree → Submissions)
- Vérifier filter Subject sur `[Simulateur aides]`

**Parsing échoue ?**
- Regarder le body de l'email reçu → adapter le pattern Text parser
- Ou activer Plain Text format dans Formspree pour simplifier

**PDF ne se génère pas ?**
- Tester le template dans PDF.co Playground avec des valeurs hardcodées
- Vérifier que les variables Mustache sont bien remplacées

---

## 📊 Coût par lead

- 1 lead = ~7 opérations Make + 1 page PDF.co
- Avec plans gratuits : ~140 leads/mois possibles
- Si 2% des leads convertissent en audit (499 €) ou AMO (2 200 €), le ROI est immédiat

---

## 🚀 Optimisations possibles (v2)

1. **Notation des leads** : scoring automatique selon profil Anah + budget + zone
2. **Relance automatique** : si pas de retour sous 7 jours, envoyer un 2e email avec offre estimateur 49 €
3. **Segmentation** : leads IDF → email spécifique mentionnant Clichy
4. **Integration Notion CRM** : au lieu de Google Sheets, ajouter directement dans ton CRM Notion via leur API
