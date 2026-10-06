# Publier les binaires du Demo Pack depuis le poste Windows

Le connecteur GitHub de cette session sait écrire les fichiers texte du dépôt mais ne sait pas transférer directement les binaires PPTX/PDF/MP4 depuis le runtime de génération.

Après téléchargement du pack livré dans la conversation, publier les fichiers dans la branche `runtime/kind-edl-lab` prend quelques commandes.

## Option A - depuis le ZIP livré

Dans Git Bash :

```bash
cd /c/workspaces/enterprise-data-lakehouse-kubernetes-openshift

git pull --ff-only origin runtime/kind-edl-lab

mkdir -p demo/presentation/dist

# Adapter SRC au dossier où le ZIP a été téléchargé.
SRC="/c/Users/HP 17 G3 Win 11 23H2/Downloads"

unzip -j \
  "$SRC/Enterprise_Data_Lakehouse_Demo_Pack_Zidane_Djamal.zip" \
  'Enterprise_Data_Lakehouse_Runtime_Demo_Zidane_Djamal.pptx' \
  'Enterprise_Data_Lakehouse_Runtime_Demo_Zidane_Djamal.pdf' \
  'Enterprise_Data_Lakehouse_Runtime_Demo_Zidane_Djamal.mp4' \
  'Enterprise_Data_Lakehouse_Runtime_Demo_Zidane_Djamal.html' \
  -d demo/presentation/dist

git add demo/presentation/dist

git commit -m "docs(demo): publish Enterprise Data Lakehouse presentation pack"

git push origin runtime/kind-edl-lab
```

## Option B - vérifier avant commit

```bash
ls -lh demo/presentation/dist

git status --short
```

Attendu :

- PowerPoint éditable ;
- PDF ;
- vidéo MP4 ;
- page HTML autonome.

## Vérité technique

La vidéo est un montage de présentation basé sur les captures runtime ; ce n’est pas un enregistrement continu d’une session live.
