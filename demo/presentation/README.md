# Enterprise Data Lakehouse - Demo Pack

Pack de démonstration signé **Zidane Djamal - Architecte Solutions / Technique & Transverse**.

## Livrables générés

Le build GitHub Actions produit dans `demo/presentation/dist/` :

- `Enterprise_Data_Lakehouse_Runtime_Demo_Zidane_Djamal.pptx` - PowerPoint éditable.
- `Enterprise_Data_Lakehouse_Runtime_Demo_Zidane_Djamal.pdf` - version PDF envoyable.
- `Enterprise_Data_Lakehouse_Runtime_Demo_Zidane_Djamal.mp4` - montage vidéo silencieux basé sur les slides et captures runtime.

Le répertoire contient aussi :

- `VIDEO_STORYBOARD_5_MIN.md` - narration recommandée pour une vidéo commentée de 4 min 30 à 5 min.
- `index.html` - page portfolio locale reprenant le storytelling et les preuves runtime.
- `build_demo_pack.js` - générateur du PowerPoint.
- `assets/` - captures runtime et diagrammes utilisés dans les livrables.

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
