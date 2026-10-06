# Storyboard vidéo - Enterprise Data Lakehouse Runtime Demo

**Auteur :** Zidane Djamal  
**Rôle :** Architecte Solutions / Technique & Transverse  
**Durée cible :** 4 min 30 à 5 min  
**Nature :** montage basé sur des captures runtime réelles du lab local Kind ; ce n’est pas un enregistrement live continu.

## 0:00 - 0:25 | Ouverture

« Je présente ici un lab personnel d’architecture Data Platform sur Kubernetes, conçu comme une démonstration de bout en bout. Le but n’est pas d’aligner des outils, mais de montrer comment GitOps, streaming, traitement, Lakehouse, SQL et observabilité s’articulent réellement. »

## 0:25 - 0:55 | Architecture globale

« Le contrôle de la plateforme part de GitHub, est réconcilié par Argo CD, puis appliqué au cluster Kubernetes Kind à trois nœuds. Le flux Data part d’un événement Kafka, passe par Spark, est matérialisé en table Iceberg sur stockage S3 compatible RustFS, référencé dans Polaris, interrogé par Trino et exploré dans Jupyter. Prometheus et Grafana assurent l’observabilité. »

## 0:55 - 1:25 | Kafka et Spark

« Redpanda Console visualise le Kafka géré par Strimzi : quatre topics et cinquante-sept partitions, dont les topics métier raw et curated. Le lab est volontairement en replication factor 1 : je ne le présente pas comme une preuve de haute disponibilité. Spark History Server montre ensuite un job terminé, son stage, ses dix tasks et son executor. »

## 1:25 - 2:00 | RustFS / S3 et Iceberg

« RustFS montre le stockage physique. Dans le bucket edl-lab, la table transactions possède des fichiers Parquet dans data et des fichiers metadata Iceberg. S3 stocke physiquement les objets ; Iceberg transforme cet ensemble en table versionnée avec snapshots et historique. »

## 2:00 - 2:35 | Jupyter, Polaris et Trino

« Dans Jupyter, la table polaris.analytics.transactions retourne six transactions. Polaris Console montre le catalogue quickstart_catalog, le namespace analytics, la table transactions, son UUID et sa metadata-location. Trino exécute ensuite le SELECT et retourne les mêmes six lignes. »

## 2:35 - 3:05 | Séquence E2E

« Le chemin d’écriture est : producteur, Kafka, Spark, Iceberg, fichiers Parquet dans RustFS et mise à jour du catalogue Polaris. Le chemin de lecture est différent : Jupyter envoie le SQL à Trino, Trino résout la table via Polaris, suit les métadonnées Iceberg et lit les fichiers Parquet dans S3. »

## 3:05 - 3:40 | Prometheus et Grafana

« Prometheus collecte les métriques Kafka, Trino et Kubernetes. Grafana les visualise. Le panneau Kafka Consumer Lag affichait No data car aucune série consumer-group correspondante n’était présente à cet instant ; en revanche la métrique under-replicated était bien disponible à zéro. Je distingue volontairement métrique absente et métrique égale à zéro. »

## 3:40 - 4:15 | Argo CD et sécurité

« Argo CD montre deux applications Healthy et Synced. Le baseline gère namespaces, quotas, LimitRanges, ServiceAccounts, RBAC et NetworkPolicy. Les namespaces appliquent Pod Security restricted et Kyverno participe à la conformité. Argo CD ne traite pas les transactions : il garantit que le socle déployé reste conforme à Git. »

## 4:15 - 4:50 | Conclusion

« La preuve runtime finale est de trois nœuds Ready, quarante-cinq pods healthy ou completed, sept PVC Bound, deux applications Argo Healthy et Synced et six transactions I12 relues depuis la table Iceberg. Les limites sont explicites : lab local, Kafka RF1, Polaris in-memory, pas de claim HA multi-hôte ni de production readiness. »

Écran final :

**Zidane Djamal**  
**Architecte Solutions / Technique & Transverse**  
Kubernetes • OpenShift • Data Platform • GitOps • Cloud Native
