#!/bin/bash
# ═══════════════════════════════════════════════════════════
# ADORA — Injection meta noindex sur toutes les pages staging
# Usage : ./inject-noindex.sh [répertoire]
# Défaut : répertoire courant
# ═══════════════════════════════════════════════════════════

DIR="${1:-.}"
COUNT=0
SKIP=0

echo "🔒 ADORA — Injection meta noindex/nofollow"
echo "   Répertoire : $DIR"
echo "   ─────────────────────────────────────────"

for file in "$DIR"/*.html; do
  [ -f "$file" ] || continue
  filename=$(basename "$file")

  # Vérifier si la balise existe déjà
  if grep -q 'name="robots"' "$file"; then
    echo "   ⏭  $filename (déjà présent)"
    SKIP=$((SKIP + 1))
    continue
  fi

  # Injecter après <head> ou après la première ligne contenant <head
  if grep -q '<head>' "$file"; then
    sed -i 's|<head>|<head>\n    <meta name="robots" content="noindex, nofollow">|' "$file"
    echo "   ✅ $filename"
    COUNT=$((COUNT + 1))
  elif grep -q '<head ' "$file"; then
    sed -i '/<head /a\    <meta name="robots" content="noindex, nofollow">' "$file"
    echo "   ✅ $filename"
    COUNT=$((COUNT + 1))
  else
    echo "   ⚠️  $filename (pas de <head> trouvé)"
  fi
done

echo "   ─────────────────────────────────────────"
echo "   ✅ $COUNT fichiers modifiés | ⏭ $SKIP déjà à jour"
echo ""
echo "   Vérification rapide :"
grep -rl 'name="robots"' "$DIR"/*.html 2>/dev/null | wc -l
echo "   fichiers contiennent la balise noindex"
