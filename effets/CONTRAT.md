# Contrat d'un effet `/effets`

Un effet est un mini-projet HyperFrames dans `effets/<nom>/`. On l'applique à n'importe quel clip avec
`rendre-effet.sh`. Ce script prépare les médias et rend l'effet. Les effets viennent du reel
un reel de démonstration (design ninon.ia) et ne contiennent aucun média de démonstration lourd.

## Format

- 1080×1920, 30 i/s, sans audio.
- Durée par défaut **2,5 s**. Le script peut la changer (`--duree`, de 2 à 8 s) en réécrivant **toutes** les
  valeurs `data-duration="2.5"` de la copie, y compris sur les `<video>`.
  Donc :
  - chaque durée liée à la longueur de l'effet s'écrit exactement `data-duration="2.5"` (index.html et compositions/) ;
  - le JS lit la durée sur la racine, jamais en dur :
    `const DUREE = parseFloat(document.querySelector('[data-composition-id]').dataset.duration);`
    Dans une sous-composition, il la lit sur sa propre racine.
- Les entrées se jouent entre 0 et environ 1,0 s, puis l'effet vit doucement (dérive, lueur, rotation…) jusqu'à `DUREE`.
  Les mouvements continus (rotation d'orbite, remplissage de jauge, barre de rendu) s'étalent sur `DUREE`.
- Zone utile : y 220–1500 (marge haute Instagram). Visage supposé centré, yeux vers y 450–700.

## Médias d'entrée

Le script les écrit dans `assets/media/`, avec toujours les mêmes noms :

| Fichier | Quand | Ce que c'est |
|---|---|---|
| `clip.mp4` | toujours | le clip recadré en 1080×1920 (couvert, centré), 30 i/s, muet, de la durée de l'effet |
| `detoure.webm` | `besoins` contient `detoure` | la personne détourée (VP9 avec alpha), alignée sur `clip.mp4` |
| `detoure-nb.webm` | `besoins` contient `detoure-nb` | la même, en noir et blanc |
| `flou.mp4`, `flou-a.mp4` … `flou-e.mp4` | `besoins` contient `flou` | le clip très flou (verre dépoli), en plusieurs copies identiques |
| `carte1.mp4` … `carte7.mp4` | `besoins` contient `cartes` | 7 vignettes 480×660 de la durée de l'effet, prises dans `--cartes <dossier>` (images ou vidéos) ou, sinon, dans le clip lui-même |
| `vignette0.jpg` … `vignette2.jpg` | `besoins` contient `vignettes` | 3 images tirées du clip (début, milieu, fin) |

Polices et images propres à l'effet (grain, etc.) : `assets/fonts/`, `assets/img/`. Le script ne touche jamais à ces dossiers.

## Textes : variables

- Tout texte visible est une variable déclarée dans `data-composition-variables` sur le `<html>` de `index.html`.
  Le texte par défaut est celui de la démo.
- On lie chaque variable par `data-var-text` ou par `window.__hyperframes.getVariables()` à l'initialisation.
  Un compteur animé lit sa valeur cible dans une variable `number`.
- Une sous-composition reçoit ses valeurs par `data-variable-values` sur son hôte. L'hôte les relaie depuis la racine au démarrage.
  Sinon, on garde tout dans `index.html`.
- Le rendu se fait avec `--variables-file variables.json --strict-variables` : une clé inconnue fait échouer le rendu.

## `effet.json`

```json
{
  "nom": "verre",
  "titre": "Widgets en verre",
  "description": "Widgets en verre dépoli autour du visage : grand chiffre, barre, anneau, rendu, pastille.",
  "besoins": ["clip", "flou"],
  "duree": 2.5,
  "variables": { "chiffre": "65", "chiffre_legende": "logiciels de pub supprimés" },
  "conseils": "Visage centré, au moins 40 % de la largeur. Éviter les clips où les mains passent devant la bouche."
}
```

`variables` donne les valeurs par défaut, celles que `/effets` montre à Ninon pour qu'elle les change.

## Vérification

- `hyperframes check` : 0 erreur, à lancer sur un dossier rendu par le script (la démo ou un test), pas sur
  `effets/<nom>/`. Ce dossier n'a pas de médias, donc `missing_local_asset` y est normal. `effets/<nom>/demo/` ne garde
  que `render.mp4` et `apercu.jpg`.
- Un rendu sur un **autre** clip que celui d'origine, regardé à 0,3 s, 1,0 s et 2,0 s.
