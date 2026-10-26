# Effets : la bibliothèque de `/effets`

7 effets visuels de 2 à 8 s, applicables à n'importe quel clip (1080×1920, muet). Tape `/effets <nom>` ou
« mets l'effet néon sur ce clip ».

| Effet | Ce que ça fait | Aperçu |
|---|---|---|
| `verre` | Widgets en verre dépoli autour du visage (chiffre, barre, anneau, rendu, pastille) | `verre/demo/apercu.jpg` |
| `documentaire` | Affiche documentaire : détourée en N&B, anneau orange, titre en 3 lignes, bouton Suivre | `documentaire/demo/apercu.jpg` |
| `orbite` | 7 cartes qui tournent autour de la personne, devant et derrière | `orbite/demo/apercu.jpg` |
| `graphique` | Graphique en barres animé en haut, visage en bas (moyenne calculée) | `graphique/demo/apercu.jpg` |
| `neon` | Un mot en néon orange derrière la tête | `neon/demo/apercu.jpg` |
| `checklist` | Panneau de 2 à 5 étapes qui se cochent | `checklist/demo/apercu.jpg` |
| `rendu` | Fausse fenêtre de rendu ninon.ia au-dessus du visage | `rendu/demo/apercu.jpg` |

- **Textes et réglages par défaut** : `<nom>/effet.json`.
- **Règles pour créer un effet** : `CONTRAT.md`.
- **Commande** : `rendre-effet.sh <nom> <clip> --debut <s> [--duree <s>] [--variables textes.json] [--cartes <dossier>]`.
- **Origine** : les effets ont été créés pour le reel un reel de démonstration (26/10/2026). On a repris des
  techniques vues dans une inspiration, mais le design, les textes et la marque sont ceux de ninon.ia.
