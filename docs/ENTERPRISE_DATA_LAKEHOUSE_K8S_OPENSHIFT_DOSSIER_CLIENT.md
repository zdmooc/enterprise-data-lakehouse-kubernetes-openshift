# Enterprise Data Lakehouse on Kubernetes / OpenShift

**Zidane Djamal**  
**Architecte Solutions / Technique & Transverse**  
Dossier d'architecture, de démonstration runtime et d'exploitation Day-2 / N3  
Périmètre : Data Platform, Kubernetes, OpenShift, GitOps, sécurité, observabilité et résilience

## 1. Objet

Ce dossier présente une plateforme Data Lakehouse d'entreprise conçue comme un Data Product gouverné sur Kubernetes et transposable vers OpenShift.

La preuve runtime principale est le cluster local multi-noeuds `kind-edl-lab`. OpenShift Local / CRC 4.22.7 est utilisé comme cible OpenShift distincte pour valider les mécanismes spécifiques OpenShift et la bascule opérationnelle locale. Les workloads Lakehouse ne sont pas présentés comme déployés sur CRC dans la preuve actuelle.

## 2. Architecture fonctionnelle

Flux de données validé :

Synthetic transaction -> Kafka -> Spark -> Iceberg / S3 -> Polaris -> Trino -> Jupyter.

Rôles :
- Kafka transporte les événements.
- Spark traite et transforme les données.
- S3-compatible / RustFS stocke les objets.
- Iceberg fournit le format de table, les snapshots et la metadata.
- Polaris fournit le REST Catalog.
- Trino fournit la couche SQL.
- Jupyter fournit l'expérience Data Engineer / Analyst.
- Argo CD réconcilie l'état GitOps.
- Prometheus et Grafana portent l'observabilité.
- Kyverno, RBAC, NetworkPolicy et securityContext contribuent à la sécurité de plateforme.

## 3. Topologie runtime validée

Cluster `kind-edl-lab` :
- 1 control-plane ;
- 2 workers ;
- Kubernetes v1.33.1 ;
- Calico 3.30.3 ;
- stockage local-path ;
- même poste physique pour les trois noeuds.

Namespaces principaux :
- `edl-platform` ;
- `edl-data` ;
- `edl-observability` ;
- `argocd` ;
- `kyverno`.

La preuve est multi-node au niveau Kubernetes mais ne constitue pas une HA multi-host ni une preuve de DR.

## 4. Statut des itérations

I1 à I12 sont RUNTIME_VALIDATED dans le périmètre local :
- I1 : cluster contract ;
- I2 : baseline plateforme ;
- I3 : GitOps / Argo CD ;
- I4 : stockage objet S3-compatible ;
- I5 : Kafka / Strimzi ;
- I6 : Spark ;
- I7 : Trino ;
- I8 : Jupyter ;
- I9 : sécurité ;
- I10 : observabilité ;
- I11 : résilience fonctionnelle / N3 ;
- I12 : Data Product E2E.

H1 : sécurité renforcée, COMPLETED_WITH_REMAINING_FINDINGS.

H2 : bascule locale Kind -> CRC -> Kind validée sans suppression du cluster Kind.

H3 : couche de visualisation browser RUNTIME_VALIDATED.

## 5. Preuve I12 de bout en bout

Événement retenu :
`E2E-I12-20260930T051236Z-a0adb24c8c95`.

Transaction :
- 17.42 EUR ;
- ACCEPTED ;
- channel E2E ;
- country FR ;
- latency 7 ms.

Résultat :
- publication unique dans Kafka ;
- relecture du payload exact, partition 1, offset 0 ;
- traitement Spark réussi ;
- écriture Iceberg / S3 ;
- catalogue Polaris accessible ;
- snapshot final `3607998935123899351` ;
- UUID de table `8894029f-a135-4248-9464-8af1cd2f8966` ;
- six lignes finales conservées ;
- lecture exacte depuis Trino ;
- lecture exacte depuis le client Trino exécuté dans le Pod Jupyter ;
- 21/21 targets Prometheus UP ;
- 3 noeuds Ready ;
- 6 PVC Bound ;
- 2 applications Argo CD Synced/Healthy.

## 6. GitOps

Le modèle GitOps repose sur Argo CD, Helm et Kustomize.

La preuve inclut :
- AppProject / Application ;
- deux applications `kind-edl-baseline` et `kind-edl-networking` Synced/Healthy ;
- drift contrôlé ;
- self-heal ;
- rollback par état déclaré.

I11 a validé un self-heal réel : un quota CPU a été modifié de 6 à 7, Argo CD a observé OutOfSync/Healthy puis restauré automatiquement la valeur 6 et l'état Synced/Healthy en 10.2 secondes.

## 7. Sécurité

Contrôles validés ou démontrés :
- namespace-scoped RBAC ;
- deny-by-default NetworkPolicy ;
- flux explicites ;
- ResourceQuota et LimitRange ;
- Pod Security / securityContext ;
- Kyverno ;
- tests négatifs ;
- scans Trivy ;
- read-only root filesystem sur les composants durcis ;
- correction GitPython Jupyter.

H1 ne constitue pas une homologation de sécurité de production. Des vulnérabilités upstream HIGH/CRITICAL et des gaps d'observabilité restent documentés.

## 8. Stockage, Iceberg et Polaris

Le laboratoire utilise du stockage local-path.

Le Data Lakehouse sépare :
- le stockage physique S3-compatible ;
- les fichiers Parquet / Avro ;
- la metadata Iceberg ;
- le catalogue Polaris.

Polaris est en mémoire dans le laboratoire. Sa durabilité n'est pas validée. Lors d'un redémarrage, la preuve H2 autorise uniquement un réenregistrement metadata-only de la metadata Iceberg existante lorsque nécessaire, sans replay Kafka, sans rerun Spark et sans réécriture S3.

## 9. Résilience et N3

I11 a validé sept scénarios fonctionnels :
1. remplacement du Pod Jupyter : Ready en 17.0 s, PVC et marqueur conservés ;
2. remplacement d'un worker Trino : Ready en 64.9 s, coordinator maintenu Ready ;
3. remplacement Kafka broker/controller : Ready en 27.7 s, PVC et topic conservés ;
4. remplacement Polaris : Ready en 27.0 s mais perte réelle du catalogue in-memory, reconstruction nécessaire ;
5. remplacement RustFS : Ready en 9.0 s, objets conservés et contrat S3 revalidé ;
6. Argo CD self-heal : retour Synced/Healthy en 10.2 s ;
7. diagnostic N3 : nodes, pods, events, storage, network, Argo, DNS, PVC marker et SQL validés.

Ces temps sont des durées observées jusqu'à Ready, pas des RTO de production.

## 10. Observabilité

I10 / I12 :
- 21 targets Prometheus UP ;
- quatre règles chargées et saines ;
- Grafana authentifié, datasource Prometheus saine ;
- dashboards disponibles.

Gaps explicitement conservés :
- Metrics API absente dans le profil local ;
- consumer lag non totalement couvert ;
- métriques capacité PVC non totalement couvertes.

## 11. Couche de visualisation

H3 ajoute :
- Redpanda Console ;
- Spark History Server ;
- Apache Polaris Console ;
- RustFS Console ;
- Jupyter Iceberg Explorer ;
- Trino UI ;
- Grafana ;
- Prometheus ;
- Argo CD.

Résultat H3 :
- 3 noeuds Ready ;
- 45 pods sains / Completed ;
- 7 PVC Bound ;
- 2 applications Argo Synced/Healthy ;
- déploiements Kafka Console, Spark History et Polaris Console à 1/1.

## 12. Bascule Kind / OpenShift Local

H2 valide une bascule locale contrôlée :
Kind actif -> arrêt des mêmes conteneurs Kind sans suppression -> démarrage CRC -> inspection OpenShift read-only -> arrêt CRC -> redémarrage des mêmes conteneurs Kind -> validation des données et de la plateforme.

Après retour Kind :
- six transactions Iceberg conservées ;
- même snapshot et UUID de table ;
- persistance Jupyter conservée ;
- 21 targets Prometheus UP ;
- 3 noeuds Ready ;
- 6 PVC Bound ;
- Argo Synced/Healthy.

Cette preuve valide une discipline opérationnelle locale, pas une migration HA entre deux plateformes de production.

## 13. OpenShift Local / CRC

D-098 a validé :
- OpenShift 4.22.7 ;
- ClusterVersion Available=True, Progressing=False ;
- ClusterOperators Available=True, Progressing=False, Degraded=False ;
- node `crc` Ready ;
- Kubernetes v1.35.6 ;
- rôles control-plane/master/worker ;
- runtime CRI-O 1.35.5.

Le Lakehouse n'est pas présenté comme redéployé intégralement sur CRC dans ce dossier. CRC fournit la preuve OpenShift spécifique et le scénario de switch local.

## 14. Limites

Non démontré :
- HA multi-host ;
- multi-AZ ;
- DR ;
- durable Polaris catalog ;
- backup/restore et CSI snapshots ;
- exactly-once / continuous streaming ;
- Kafka multi-broker avec réplication de production ;
- OIDC / Vault runtime ;
- enforcement Cosign ;
- stockage enterprise Portworx / Trident / Longhorn ;
- performances ou SLA de production.

## 15. Auteur

**Zidane Djamal**  
**Architecte Solutions / Technique & Transverse**

Positionnement : architecture de solutions, architecture technique et transverse, Kubernetes / OpenShift, Data Platform, GitOps, sécurité, observabilité, résilience, exploitation Day-2 et support N3.
