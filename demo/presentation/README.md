# Enterprise Data Lakehouse - Demo Pack

Pack de démonstration signé **Zidane Djamal - Architecte Solutions / Technique & Transverse**.

## Contenu du répertoire

Le dépôt conserve les éléments source et le storytelling :

- `VIDEO_STORYBOARD_5_MIN.md` - narration recommandée pour une vidéo commentée de 4 min 30 à 5 min ;
- `build_demo_pack.js` - générateur du PowerPoint ;
- `PUBLISH_FROM_LOCAL.md` - procédure de publication des binaires générés ;
- ce `README.md` - structure et vérité technique du support.

Le pack binaire correspondant est généré à partir des captures runtime réelles et contient :

- `Enterprise_Data_Lakehouse_Runtime_Demo_Zidane_Djamal.pptx` - PowerPoint éditable ;
- `Enterprise_Data_Lakehouse_Runtime_Demo_Zidane_Djamal.pdf` - version PDF envoyable ;
- `Enterprise_Data_Lakehouse_Runtime_Demo_Zidane_Djamal.mp4` - montage vidéo silencieux des slides ;
- `Enterprise_Data_Lakehouse_Runtime_Demo_Zidane_Djamal.html` - page portfolio autonome ;
- `VIDEO_STORYBOARD_5_MIN.md` - script de narration.

> Le connecteur GitHub utilisé pour cette session écrit les fichiers texte mais ne permet pas de pousser directement les binaires PPTX/PDF/MP4 depuis le runtime de génération. Les binaires sont donc livrés séparément et `PUBLISH_FROM_LOCAL.md` donne la publication Git locale en quelques commandes.

## Storytelling

1. Architecture globale : GitHub -> Argo CD -> Kubernetes et chaîne Data.
2. Kafka / Strimzi puis Spark History Server.
3. RustFS / S3 et fichiers Parquet / metadata Iceberg.
4. Jupyter / Iceberg Explorer.
5. Polaris Catalog puis Trino SQL.
6. Diagramme de séquence écriture / lecture.
7. Prometheus / Grafana.
8. Argo CD, RBAC, NetworkPolicy, Kyverno.
9. Preuve runtime et limites.

## Vérité technique

Les captures proviennent du runtime local `kind-edl-lab` et illustrent des interfaces réellement ouvertes pendant la validation.

Preuve finale retenue :

- 3 nœuds Kubernetes Ready ;
- 45 pods healthy / completed ;
- 7 PVC Bound ;
- 2 applications Argo CD Healthy / Synced ;
- 6 transactions I12 relues depuis `polaris.analytics.transactions`.

Limites explicites : lab local, Kafka RF=1, Polaris in-memory, pas de claim HA multi-hôte / DR, pas de production readiness.

## Signature

**Zidane Djamal**  
Architecte Solutions / Technique & Transverse  
Kubernetes • OpenShift • Data Platform • GitOps • Cloud Native
