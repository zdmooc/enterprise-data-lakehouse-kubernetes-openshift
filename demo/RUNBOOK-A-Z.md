# Runbook A à Z — Démo Enterprise Data Lakehouse

## A. Synchroniser Git

    cd /c/workspaces/enterprise-data-lakehouse-kubernetes-openshift
    git fetch origin
    git checkout runtime/kind-edl-lab
    git pull --ff-only origin runtime/kind-edl-lab
    git status --short --branch

Attendu : ni `ahead`, ni `behind`, ni fichier modifié.

## B. Identifier le runtime actif

    crc status
    kubectl config current-context
    kind get clusters
    docker ps -a --filter "label=io.x-k8s.kind.cluster=edl-lab"

CRC et Kind sont conservés mais ne doivent pas être exploités simultanément sur cette workstation.

## C. Basculer CRC -> Kind

    CONFIRM_DEMO_SWITCH=yes bash demo/scripts/01-switch-crc-to-kind.sh

Le mapping retenu et validé est :

    edl-lab-control-plane = 172.18.0.2
    edl-lab-worker2       = 172.18.0.3
    edl-lab-worker        = 172.18.0.4

L'ordre est important avec Docker Desktop. Ne pas utiliser `kind delete cluster` ou `crc delete`.

## D. Contrôle plateforme

    bash demo/scripts/02-preflight.sh

Le contrôle vérifie contexte, CRC arrêté, trois conteneurs, trois nœuds Ready, IP Docker, Calico, pods, PVC, Argo CD, Kafka, composants Data et observabilité.

Ne pas faire `source scripts/kind/common.sh` dans un Git Bash interactif : ce fichier active `set -euo pipefail`. Les scripts de `demo/` l'utilisent dans leur propre processus.

## E. Restaurer Polaris

Le snapshot canonique est :

    evidence/kind-edl-lab/20260928T112119Z

Commande :

    CONFIRM_DEMO_RECOVERY=yes bash demo/scripts/03-restore-i12.sh

Attendu :

    POLARIS_RECOVERY=NOT_REQUIRED

ou :

    POLARIS_RECOVERY=REGISTER_EXISTING_METADATA

La deuxième voie est metadata-only.

## F. Vérifier les six transactions

    kubectl -n edl-data exec deployment/edl-trino-coordinator --       trino       --server http://localhost:8080       --user edl       --execute       'SELECT eventId, transactionId, amount, status
       FROM polaris.analytics.transactions
       ORDER BY eventId'

Le résultat validé contient l'événement I12 plus `evt-0001` à `evt-0005`.

## G. Ouvrir les interfaces

    bash demo/scripts/04-start-interfaces.sh

| Interface | URL | Utilité |
|---|---|---|
| Argo CD | https://127.0.0.1:18081 | GitOps |
| Grafana | http://127.0.0.1:13000 | dashboards |
| Prometheus | http://127.0.0.1:19090 | targets / métriques |
| Jupyter | http://127.0.0.1:18888 | Data UX |
| Trino | http://127.0.0.1:18080 | SQL / Web UI selon configuration |
| Polaris | http://127.0.0.1:18181 | API REST Catalog |
| S3 health | http://127.0.0.1:19000/health | santé S3 |

Préparer les sessions authentifiées avant le partage d'écran. Ne jamais afficher de secrets.

## H. Démo 12–15 minutes

### 0–2 min — Architecture

Message : ce POC montre une équipe Platform Engineering fournissant un Kubernetes gouverné pour des Data Products.

### 2–4 min — Kubernetes

    kubectl get nodes -o wide
    kubectl -n edl-data get pods
    kubectl -n edl-data get pvc

Préciser : preuve locale multi-node, pas HA production.

### 4–6 min — GitOps

    kubectl -n argocd get applications

Attendu : `kind-edl-baseline` et `kind-edl-networking` en `Synced/Healthy`. Ne pas provoquer de drift live.

### 6–9 min — Data Product

Montrer les six lignes Trino puis les mêmes données via Jupyter.

Message : Kafka -> Spark -> Iceberg/S3 -> Polaris -> Trino -> Jupyter.

### 9–11 min — Observabilité

Montrer Grafana puis Prometheus Targets. Le snapshot historique validait 21 targets UP ; pendant la démo, annoncer la valeur live.

### 11–13 min — Sécurité

    kubectl get clusterpolicy
    kubectl -n edl-data get networkpolicy
    kubectl -n edl-data get role,rolebinding

Présenter RBAC, deny-by-default, Kyverno, securityContext et scans. Ne pas rejouer les tests négatifs live.

### 13–15 min — N3

Méthode : events -> ressources/scheduling -> DNS/Service/NetworkPolicy -> TLS/secrets -> stockage/PVC -> dépendances -> logs/métriques -> RCA.

## I. Preuve read-only

    bash demo/scripts/05-demo-readonly.sh

## J. Fin

    bash demo/scripts/06-stop-interfaces.sh

## K. Retour Kind -> CRC

    bash scripts/kind/stop-edl-lab.sh
    crc start
    crc status

Ne jamais supprimer le cluster pour une simple bascule.

## L. Checklist finale

- Git synchronisé ;
- CRC arrêté ;
- contexte `kind-edl-lab` ;
- 3 nœuds Ready ;
- Calico Ready ;
- 6 PVC Bound ;
- Argo Synced/Healthy ;
- Kafka Ready ;
- S3, Polaris, Trino, Jupyter Running ;
- 6 transactions I12 visibles ;
- interfaces préparées ;
- aucune commande destructive prévue.


## M. Installer la couche de visualisation

À exécuter une fois après synchronisation Git :

    CONFIRM_VISUALIZATION=yes bash scripts/kind/visualization.sh

Effets attendus :

1. RustFS redémarre sur le même PVC avec la Console activée sur 9001.
2. Polaris est réappliqué avec le CORS nécessaire au navigateur local.
3. Le catalogue I12 est réenregistré à partir de la metadata Iceberg existante, sans replay Kafka/Spark et sans réécriture S3.
4. Redpanda Console est connecté au bootstrap Kafka Strimzi.
5. Polaris Console est construit depuis le source Apache officiel épinglé puis chargé dans Kind.
6. Spark History Server est déployé avec un PVC `spark-event-logs`.
7. Un job Spark smoke/Pi crée une première trace History Server sans modifier les données Lakehouse.
8. Le notebook `ICEBERG_EXPLORER.ipynb` est copié dans le workspace Jupyter.

## N. Parcours visuel composant par composant

### Kafka / Strimzi — Redpanda Console

    http://127.0.0.1:18082

À montrer :

- `edl.smoke` ;
- `transactions.raw` ;
- `transactions.curated` ;
- partitions ;
- messages ;
- consumer groups / offsets lorsqu'ils existent.

### Spark — Spark History Server

    http://127.0.0.1:18083

À montrer :

- application `kind-spark-smoke` ;
- Jobs ;
- Stages ;
- Tasks ;
- Executors ;
- durée et métriques de l'application.

Pour créer une nouvelle entrée sans toucher aux données métier :

    bash demo/scripts/07-populate-spark-history.sh

### RustFS / S3

    http://127.0.0.1:19001

La Console permet de voir physiquement le bucket et les objets. La couche S3 stocke les fichiers ; elle ne connaît pas à elle seule la sémantique de table Iceberg.

### Iceberg — Jupyter

Ouvrir :

    http://127.0.0.1:18888

puis le notebook :

    /home/jovyan/work/ICEBERG_EXPLORER.ipynb

Le notebook affiche :

- les six lignes métier ;
- `transactions$snapshots` ;
- `transactions$history` ;
- `transactions$files` ;
- une vue des tailles de fichiers physiques.

### Polaris — Polaris Console

    http://127.0.0.1:18182

Utiliser les credentials du secret `polaris-client` avec le realm `POLARIS`. Montrer :

    quickstart_catalog
      -> analytics
         -> transactions

La Console est une vue du catalogue ; les fichiers restent dans RustFS/S3.

### Trino

    http://127.0.0.1:18080

Lancer une requête depuis un terminal pour voir `RUNNING QUERIES`, workers, drivers et mémoire évoluer.

### Observabilité

    Grafana    http://127.0.0.1:13001
    Prometheus http://127.0.0.1:19090

Grafana présente la vue synthétique. Prometheus permet d'aller jusqu'aux targets et au PromQL.

## O. Lecture pédagogique finale

    Kafka            = transporte les événements
    Spark            = transforme / calcule
    RustFS / S3      = stocke les fichiers
    Iceberg          = structure la table et ses snapshots
    Polaris          = catalogue la table
    Trino            = exécute les requêtes SQL
    Jupyter          = permet l'exploration Data
    Prometheus       = collecte les métriques
    Grafana          = visualise les métriques
    Argo CD          = visualise l'état GitOps
