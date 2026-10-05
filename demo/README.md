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
