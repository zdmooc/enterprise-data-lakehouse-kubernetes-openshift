# Demo Enterprise Data Lakehouse — Kind / Kubernetes

Ce répertoire contient la démarche complète de démonstration du POC `kind-edl-lab`, depuis un poste où CRC/OpenShift Local peut être actif jusqu'à la démonstration finale Data Platform puis le retour éventuel vers CRC.

## Périmètre démontré

Chaîne fonctionnelle validée :

    Kafka
      |
      v
    Spark
      |
      v
    Iceberg / S3 compatible
      |
      v
    Polaris
      |
      v
    Trino
      |
      v
    Jupyter

Autour de cette chaîne : Kubernetes Kind 3 nœuds, Calico, Argo CD/GitOps, Kyverno, RBAC, NetworkPolicy, Prometheus, Grafana et Strimzi.

## Vérité technique

Cette démo prouve une intégration fonctionnelle locale sur une seule workstation. Elle ne constitue pas une preuve de HA multi-hôte, DR, catalogue Polaris durable, exactly-once streaming ou readiness de production.

Le snapshot I12 retenu contient six transactions, dont `E2E-I12-20260930T051236Z-a0adb24c8c95`.

Polaris est volontairement in-memory. Après restart, la récupération réenregistre uniquement les métadonnées Iceberg existantes : aucun replay Kafka, aucune relance Spark, aucune réécriture S3/Iceberg.

## Parcours recommandé

1. Synchroniser la branche `runtime/kind-edl-lab`.
2. Si CRC est actif, lancer `CONFIRM_DEMO_SWITCH=yes bash demo/scripts/01-switch-crc-to-kind.sh`.
3. Vérifier avec `bash demo/scripts/02-preflight.sh`.
4. Si nécessaire, restaurer Polaris avec `CONFIRM_DEMO_RECOVERY=yes bash demo/scripts/03-restore-i12.sh`.
5. Ouvrir les interfaces avec `bash demo/scripts/04-start-interfaces.sh`.
6. Exécuter la preuve read-only avec `bash demo/scripts/05-demo-readonly.sh`.
7. Suivre `TALK-TRACK.md` pendant l'entretien.
8. Fermer les port-forwards avec `bash demo/scripts/06-stop-interfaces.sh`.
9. Pour revenir à CRC, suivre `RUNBOOK-A-Z.md`.

## D-098 — bascule vers CRC pour les preuves OpenShift

Pour le programme SQY/D-098, le Lakehouse reste sur Kind mais la workstation peut être laissée sur CRC afin d'enchaîner les preuves OpenShift.

Depuis Kind actif :

    CONFIRM_DEMO_SWITCH=yes bash demo/scripts/00-switch-kind-to-crc.sh

Le script :
- vérifie le cluster Kind retenu ;
- ferme les port-forwards de démo ;
- arrête les trois conteneurs Kind sans les supprimer ;
- démarre CRC ;
- laisse le contexte `crc-admin` actif ;
- ne modifie aucun workload CRC.

Après les preuves SQY, retour vers Kind :

    CONFIRM_DEMO_SWITCH=yes bash demo/scripts/01-switch-crc-to-kind.sh

Puis :

    bash demo/scripts/02-preflight.sh

Cette bascule conserve les limites H2 : workstation locale, aucune preuve HA/DR/production.

## Démarrage rapide

    git fetch origin
    git pull --ff-only origin runtime/kind-edl-lab
    bash demo/scripts/02-preflight.sh
    bash demo/scripts/04-start-interfaces.sh
    bash demo/scripts/05-demo-readonly.sh

## Règle d'or

Pendant un entretien, ne pas lancer de chaos, de suppression de pods, de réinstallation d'Operator ou d'E2E complet. La démonstration doit rester read-only et s'appuyer sur l'état validé.


## Préparation avant entretien

- `CHECKLIST-5-MINUTES.md` : contrôle rapide juste avant l'appel.
- `ACCESS.md` : accès aux interfaces et récupération privée des identifiants sans exposer de secrets.


## Couche de visualisation complète

La couche de démonstration ajoute quatre surfaces visuelles sans changer la vérité métier du POC :

- **Redpanda Console** pour Kafka / Strimzi : topics, partitions, messages et consumer groups ;
- **Spark History Server** pour les jobs, stages, tasks et executors terminés ;
- **Apache Polaris Console** construit depuis le source officiel `apache/polaris-tools` au commit épinglé `9e6870075dce0cfe4da73f87d61a034545bbea19` ;
- **RustFS Console** pour les buckets et objets S3 ;
- **ICEBERG_EXPLORER.ipynb** dans Jupyter pour les snapshots, l'historique et les fichiers Parquet Iceberg.

Installation locale contrôlée :

    CONFIRM_VISUALIZATION=yes bash scripts/kind/visualization.sh

Cette commande active la console RustFS, applique le CORS local Polaris, restaure le catalogue I12 par enregistrement metadata-only si nécessaire, déploie les trois UIs supplémentaires, copie le notebook Iceberg dans Jupyter et lance un job Spark smoke/Pi non destructif afin d'alimenter le History Server.

Sous Windows/Git Bash, l'ouverture durable des tunnels se fait ensuite avec :

    bash demo/scripts/04-start-interfaces.sh

Le script délègue automatiquement à PowerShell pour éviter la disparition des `kubectl port-forward` observée avec les processus Git Bash détachés.

### URLs de démonstration

| Brique | URL locale |
|---|---|
| Argo CD | https://127.0.0.1:18081 |
| Kafka / Redpanda Console | http://127.0.0.1:18082 |
| Spark History Server | http://127.0.0.1:18083 |
| Grafana | http://127.0.0.1:13001 |
| Prometheus | http://127.0.0.1:19090 |
| Jupyter | http://127.0.0.1:18888 |
| Trino | http://127.0.0.1:18080 |
| Polaris Console | http://127.0.0.1:18182 |
| Polaris API | http://127.0.0.1:18181 |
| RustFS Console | http://127.0.0.1:19001 |
| RustFS / S3 API | http://127.0.0.1:19000 |

La console Polaris est construite localement depuis le source Apache officiel car l'upstream ne publie pas encore une image officielle stable à consommer directement.
