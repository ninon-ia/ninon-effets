---
name: effets
description: Applique un des 7 effets visuels ninon.ia (verre, documentaire, orbite, graphique, néon, checklist, rendu) à n'importe quel clip — extrait choisi, recadrage 1080×1920, détourage si besoin, textes personnalisés, rendu muet de 2 à 8 s prêt pour un Reel. À utiliser quand on tape « /effets », « /effets néon », « mets l'effet verre sur ce clip », « fais-moi l'affiche documentaire », « applique un effet », ou quand on donne un clip en demandant un effet.
---

# /effets : un effet visuel sur n'importe quel clip

Ce skill contient tout ce dont il a besoin, rangé dans son propre dossier (le « dossier de ce skill ») :
- `effets/<nom>/` : un mini-projet HyperFrames par effet ;
- `effets/CONTRAT.md` : les règles communes ;
- `rendre-effet.sh` : le script qui prépare le clip et rend l'effet.

Réponds dans la langue de la personne, en phrases courtes.

| Effet | Ce que ça fait | Besoins |
|---|---|---|
| `verre` | Widgets en verre dépoli autour du visage : grand chiffre, barre, anneau, rendu, pastille | flou |
| `documentaire` | Affiche documentaire : personne détourée en N&B, anneau orange, titre en 3 lignes, bandeau nom, bouton Suivre | détourage N&B |
| `orbite` | 7 cartes (images ou vidéos) qui tournent autour de la personne, devant et derrière | détourage, cartes |
| `graphique` | Écran partagé : graphique en barres animé en haut, visage en bas | — |
| `neon` | Un mot en néon orange derrière la tête | détourage |
| `checklist` | Panneau d'étapes qui se cochent, de 2 à 5 | — |
| `rendu` | Fausse fenêtre de rendu (pistes, tête de lecture, pourcentage) au-dessus du visage | vignettes |

Les textes par défaut et les conseils de chaque effet sont dans `effets/<nom>/effet.json`. L'aperçu est dans `effets/<nom>/demo/apercu.jpg`.

## 0. Prérequis (une fois)

- `ffmpeg` et `ffprobe` dans le PATH ;
- Node.js 18 ou plus, pour `npx hyperframes`, qui fait le rendu et le détourage (son modèle se télécharge au premier détourage) ;
- `python3`.

Si un outil manque, dis-le et donne la commande d'installation : `brew install ffmpeg node` sur Mac.

## 1. Comprendre la demande

- **Le clip** : son chemin. Fais un `ffprobe` pour la taille et la durée.
- **L'effet** : son nom. S'il manque, montre le tableau ci-dessus et demande. « néon » s'écrit `neon` pour le script.
- **Le moment** : un temps de début. Sinon, propose-en un : une planche du clip
  (`ffmpeg -i clip -vf "fps=0.5,scale=120:-2,tile=10x5" -frames:v 1 planche.jpg`), visage de face, calme, mains loin de la bouche.
- **La durée** : 2,5 s par défaut, de 2 à 8 s.
- **Les textes** : lis `effet.json` → `variables`. Montre les textes par défaut en une liste courte et demande les siens.
  Pour `verre` et `graphique`, **jamais de chiffre inventé** : les nombres viennent d'une source ou des données de la personne.

## 2. Rendre

```bash
bash "<dossier de ce skill>/rendre-effet.sh" <effet> <clip> --debut <s> [--duree <s>] [--variables textes.json] \
  [--cartes <dossier>] [--x 0.5] [--y 0.4] [--sortie <dossier>] [--draft]
```

- **`textes.json`** : seulement les clés à changer, par exemple `{"mot": "enquête", "decalage": 430}`.
- **Sortie** : `./effets-rendus/<effet>_<clip>_<début>s/render.mp4` par défaut, dans le dossier courant.
- **Clip horizontal** : le cadre 9:16 se centre avec `--x` (0 = gauche, 1 = droite).
- **`orbite`** : `--cartes` prend un dossier de 7 images ou vidéos au plus, dans l'ordre alphabétique.
  Chaque source tierce reçoit son crédit (`credit1`…`credit7`). Sans `--cartes`, les cartes sont des images du clip.
- **`neon`** : si la tête cache trop le mot, ou pas assez, change `decalage` (en px, entre 0 et 800).
- **HyperFrames** : si `npx hyperframes` échoue, le script prend tout seul le binaire le plus récent du cache npx.
  On peut aussi forcer avec `HYPERFRAMES_BIN=<chemin>`.

## 3. Vérifier avant de montrer

- Regarde 3 images du rendu (0,3 s, 1,0 s et 2,0 s ; ajoute la fin si la durée dépasse 2,5 s).
- Vérifie :
  - visage dégagé, textes lisibles, rien de coupé dans la zone y 220–1500 ;
  - un détourage propre ;
  - les chiffres justes.
- Si ça ne va pas, corrige les textes ou le cadrage (`--x`, `--y`, `decalage`, autre `--debut`) et relance.
  Ne modifie pas `effets/<nom>/` pour un seul clip.

## 4. Livrer

Donne le chemin de `render.mp4` (muet, 1080×1920, 30 i/s). Dans un montage, il remplace l'image pendant sa durée, et le son du clip continue dessous.

## Ajouter un effet

Suis `effets/CONTRAT.md` :
- médias aux noms fixes ;
- textes en variables ;
- `data-duration="2.5"` partout ;
- un `effet.json` ;
- un aperçu dans `demo/`.

Teste-le sur deux clips différents.
