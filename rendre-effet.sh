#!/usr/bin/env bash
# Applique un effet de la bibliothèque effets/ à n'importe quel clip (commande /effets).
#
#   outils/rendre-effet.sh <effet> <clip> [options]
#
#   --debut <s>        début de l'extrait dans le clip (défaut 0)
#   --duree <s>        durée de l'effet, 2 à 8 s (défaut : celle de effet.json, 2,5 s)
#   --x <0..1>         clip horizontal : où centrer le cadre 9:16 (0 = gauche, 0,5 = centre, défaut 0,5)
#   --y <0..1>         clip plus haut que 9:16 : où centrer le cadre (défaut 0,4, un peu au-dessus du milieu)
#   --variables <f>    fichier JSON des textes (clés de effet.json → "variables")
#   --cartes <dossier> images ou vidéos pour les cartes (effet orbite), 7 au plus
#   --sortie <dossier> dossier de rendu (défaut : projets/effets-rendus/… dans le studio, sinon ./effets-rendus/…)
#   --draft            rendu brouillon, plus rapide
#
#   ex. outils/rendre-effet.sh neon A_MONTER/rush.mp4 --debut 12.4 --variables mes-textes.json
#
# Le script recadre le clip en 1080×1920 et fait le détourage, le flou, les cartes et les vignettes selon
# les « besoins » de l'effet (voir effets/CONTRAT.md). Il copie l'effet sans jamais modifier la bibliothèque,
# puis rend <sortie>/render.mp4 (muet).
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"

# La bibliothèque est à côté du script (dépôt partagé) ou un dossier au-dessus (studio : outils/ et effets/).
ICI="$(cd "$(dirname "$0")" && pwd)"
if [ -d "$ICI/effets" ]; then LIB="$ICI/effets"; else LIB="$(cd "$ICI/.." && pwd)/effets"; fi
NOM="${1:?effet manquant (ls effets/)}"
CLIP="${2:?clip manquant}"
shift 2

DEBUT=0; DUREE=""; X=0.5; Y=0.4; VARS=""; CARTES=""; SORTIE=""; QUALITE=looks
while [ $# -gt 0 ]; do
  case "$1" in
    --debut) DEBUT="$2"; shift 2 ;;
    --duree) DUREE="$2"; shift 2 ;;
    --x) X="$2"; shift 2 ;;
    --y) Y="$2"; shift 2 ;;
    --variables) VARS="$2"; shift 2 ;;
    --cartes) CARTES="$2"; shift 2 ;;
    --sortie) SORTIE="$2"; shift 2 ;;
    --draft) QUALITE=draft; shift ;;
    *) echo "Option inconnue : $1" >&2; exit 1 ;;
  esac
done

SRC="$LIB/$NOM"
[ -f "$SRC/effet.json" ] || { echo "Effet introuvable : $SRC (effets disponibles : $(ls "$LIB" | grep -v '\.md$' | tr '\n' ' '))" >&2; exit 1; }
[ -f "$CLIP" ] || { echo "Clip introuvable : $CLIP" >&2; exit 1; }
CLIP="$(cd "$(dirname "$CLIP")" && pwd)/$(basename "$CLIP")"
[ -z "$VARS" ] || VARS="$(cd "$(dirname "$VARS")" && pwd)/$(basename "$VARS")"
[ -z "$CARTES" ] || CARTES="$(cd "$CARTES" && pwd)"

lire() { python3 -I -c "import json,sys; v=json.load(open(sys.argv[1])).get(sys.argv[2]); print(' '.join(v) if isinstance(v,list) else v)" "$SRC/effet.json" "$1"; }
BESOINS="$(lire besoins)"
[ -n "$DUREE" ] || DUREE="$(lire duree)"
python3 -I -c "import sys; d=float(sys.argv[1]); sys.exit(0 if 2 <= d <= 8 else 1)" "$DUREE" || { echo "--duree doit être entre 2 et 8 s" >&2; exit 1; }

# HyperFrames : $HYPERFRAMES_BIN, sinon la version testée (HF_VERSION) déjà en cache npx, sinon npx l'installe.
HF_VERSION="0.8.204"
hf() {
  if [ -n "${HYPERFRAMES_BIN:-}" ]; then "$HYPERFRAMES_BIN" "$@"; return; fi
  for b in "$HOME"/.npm/_npx/*/node_modules/.bin/hyperframes; do
    [ -x "$b" ] || continue
    if [ "$(node -p "require('$(dirname "$(dirname "$b")")/hyperframes/package.json').version" 2>/dev/null)" = "$HF_VERSION" ]; then
      "$b" "$@"; return
    fi
  done
  npx --yes "hyperframes@$HF_VERSION" "$@"
}

# Le clip doit couvrir l'extrait demandé.
LONGUEUR="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$CLIP")"
python3 -I -c "import sys; a,b,c=map(float,sys.argv[1:]); sys.exit(0 if a+b <= c+0.01 else 1)" "$DEBUT" "$DUREE" "$LONGUEUR" \
  || { echo "Le clip dure ${LONGUEUR}s : impossible d'en tirer ${DUREE}s à partir de ${DEBUT}s" >&2; exit 1; }

BASE="$(basename "${CLIP%.*}")"
if [ -z "$SORTIE" ]; then
  if [ -d "$(dirname "$LIB")/projets" ]; then SORTIE="$(dirname "$LIB")/projets/effets-rendus/${NOM}_${BASE}_${DEBUT}s"
  else SORTIE="$PWD/effets-rendus/${NOM}_${BASE}_${DEBUT}s"; fi
fi
mkdir -p "$SORTIE"
SORTIE="$(cd "$SORTIE" && pwd)"

rsync -aL --delete --exclude ".hyperframes" --exclude "demo" --exclude "renders" --exclude "assets/media" \
  --exclude "render.mp4" --exclude "variables.json" --exclude "verif" --exclude ".transcode-cache" "$SRC/" "$SORTIE/"
M="$SORTIE/assets/media"
mkdir -p "$M"

# 1. Le clip, recadré en 1080×1920 (couvert), 30 i/s, muet.
IFS=x read -r W H < <(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0:s=x "$CLIP")
CADRE="$(python3 -I -c "
import sys
w,h,x,y=int(sys.argv[1]),int(sys.argv[2]),float(sys.argv[3]),float(sys.argv[4])
if w*16 > h*9: print(f'scale=-2:1920,crop=1080:1920:(iw-1080)*{x}:0')
else: print(f'scale=1080:-2,crop=1080:1920:0:(ih-1920)*{y}')
" "$W" "$H" "$X" "$Y")"
ffmpeg -v error -y -ss "$DEBUT" -t "$DUREE" -i "$CLIP" -an -sn -vf "fps=30,$CADRE,setsar=1" \
  -c:v libx264 -crf 16 -preset medium -pix_fmt yuv420p "$M/clip.mp4"

a_besoin() { case " $BESOINS " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }

# 2. Détourage (et sa version noir et blanc).
if a_besoin detoure || a_besoin detoure-nb; then
  hf remove-background "$M/clip.mp4" -o "$M/detoure.webm" --quality best >/dev/null
fi
if a_besoin detoure-nb; then
  ffmpeg -v error -y -c:v libvpx-vp9 -i "$M/detoure.webm" -vf "format=yuva420p,hue=s=0,eq=contrast=1.12" \
    -c:v libvpx-vp9 -pix_fmt yuva420p -b:v 4M -auto-alt-ref 0 "$M/detoure-nb.webm"
fi

# 3. Verre dépoli : le clip très flou, en copies identiques (une par widget).
if a_besoin flou; then
  ffmpeg -v error -y -i "$M/clip.mp4" -vf "boxblur=30:2" -c:v libx264 -crf 20 -pix_fmt yuv420p "$M/flou.mp4"
  for l in a b c d e; do cp "$M/flou.mp4" "$M/flou-$l.mp4"; done
fi

# 4. Cartes (orbite) : 7 vignettes 480×660 de la durée de l'effet.
if a_besoin cartes; then
  CARTE_VF="scale=480:660:force_original_aspect_ratio=increase,crop=480:660,fps=30,setsar=1"
  SOURCES=()
  if [ -n "$CARTES" ]; then
    while IFS= read -r f; do SOURCES+=("$f"); done < <(find "$CARTES" -maxdepth 1 -type f \
      \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.mp4' -o -iname '*.mov' \) | sort | head -7)
  fi
  for i in 1 2 3 4 5 6 7; do
    if [ ${#SOURCES[@]} -gt 0 ]; then
      f="${SOURCES[$(( (i - 1) % ${#SOURCES[@]} ))]}"
      case "$(printf '%s' "$f" | tr '[:upper:]' '[:lower:]')" in
        *.mp4|*.mov) ffmpeg -v error -y -stream_loop -1 -i "$f" -t "$DUREE" -an -vf "$CARTE_VF" -c:v libx264 -crf 20 -pix_fmt yuv420p "$M/carte$i.mp4" ;;
        *) ffmpeg -v error -y -loop 1 -i "$f" -t "$DUREE" -vf "$CARTE_VF" -c:v libx264 -crf 20 -pix_fmt yuv420p "$M/carte$i.mp4" ;;
      esac
    else
      # Sans cartes fournies : des images du clip lui-même, à des instants différents.
      T="$(python3 -I -c "import sys; print(round(float(sys.argv[1]) * ($i - 0.5) / 7, 2))" "$DUREE")"
      ffmpeg -v error -y -ss "$T" -i "$M/clip.mp4" -frames:v 1 -q:v 2 "$M/_carte$i.jpg"
      ffmpeg -v error -y -loop 1 -i "$M/_carte$i.jpg" -t "$DUREE" -vf "$CARTE_VF" -c:v libx264 -crf 20 -pix_fmt yuv420p "$M/carte$i.mp4"
      rm -f "$M/_carte$i.jpg"
    fi
  done
fi

# 5. Vignettes (rendu) : début, milieu, fin du clip.
if a_besoin vignettes; then
  n=0
  for T in 0.1 "$(python3 -I -c "import sys; print(float(sys.argv[1]) / 2)" "$DUREE")" "$(python3 -I -c "import sys; print(float(sys.argv[1]) - 0.15)" "$DUREE")"; do
    ffmpeg -v error -y -ss "$T" -i "$M/clip.mp4" -frames:v 1 -vf "scale=480:-2" -q:v 3 "$M/vignette$n.jpg"
    n=$((n + 1))
  done
fi

# 6. Durée : toutes les valeurs data-duration="2.5" de la copie.
if [ "$DUREE" != "2.5" ]; then
  find "$SORTIE" -name '*.html' -not -path '*/.hyperframes/*' -exec sed -i.bak "s/data-duration=\"2\.5\"/data-duration=\"$DUREE\"/g" {} +
  find "$SORTIE" -name '*.html.bak' -delete
fi

# 7. Textes et rendu.
if [ -n "$VARS" ]; then cp "$VARS" "$SORTIE/variables.json"; else echo '{}' > "$SORTIE/variables.json"; fi
cd "$SORTIE"
hf render . --variables-file variables.json --strict-variables -q "$QUALITE" -o "$SORTIE/render.mp4" --quiet >/dev/null
echo "OK $SORTIE/render.mp4 ($(ffprobe -v error -show_entries format=duration -of csv=p=0 "$SORTIE/render.mp4") s)"
