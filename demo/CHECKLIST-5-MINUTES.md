# Checklist — 5 minutes avant la démo

## Runtime

    crc status
    kubectl config current-context
    kubectl get nodes

Attendu : CRC arrêté, contexte `kind-edl-lab`, 3 nœuds Ready.

## Santé globale

    bash demo/scripts/02-preflight.sh

Attendu : `[PASS] DEMO PREFLIGHT READY`.

## Données

Si Polaris vient d'être redémarré :

    CONFIRM_DEMO_RECOVERY=yes bash demo/scripts/03-restore-i12.sh

Sinon vérifier simplement :

    kubectl -n edl-data exec deployment/edl-trino-coordinator --       trino --server http://localhost:8080 --user edl       --execute 'SELECT count(*) FROM polaris.analytics.transactions'

Attendu : 6.

## Interfaces

    bash demo/scripts/04-start-interfaces.sh

Ouvrir avant partage d'écran :

1. Argo CD ;
2. Grafana ;
3. Prometheus Targets ;
4. Jupyter ;
5. VS Code sur `demo/RUNBOOK-A-Z.md`.

Préparer les authentifications selon `ACCESS.md`, puis nettoyer le terminal qui a affiché d'éventuels secrets.

## Ordre de présentation

1. Architecture.
2. 3 nœuds Kubernetes.
3. Argo Synced/Healthy.
4. Trino : six transactions.
5. Jupyter : même jeu de données.
6. Grafana.
7. Prometheus Targets.
8. RBAC / NetworkPolicy / Kyverno.
9. N3 / Day-2.
10. Limites du POC.

## Ce qu'il ne faut pas faire

- pas de chaos live ;
- pas de suppression de pod ;
- pas de nouvel E2E ;
- pas de rebuild ;
- pas de réinstallation Operator ;
- pas de `kind delete cluster` ;
- pas de `crc delete`.

## Fin

    bash demo/scripts/06-stop-interfaces.sh


## Visualisation enrichie

Vérifier les workloads :

    kubectl -n edl-data get deploy       edl-kafka-console       edl-spark-history       edl-polaris-console

Vérifier RustFS :

    kubectl -n edl-data get svc edl-s3
    kubectl -n edl-data get pvc spark-event-logs

Démarrer les tunnels :

    bash demo/scripts/04-start-interfaces.sh

Ouvrir les onglets :

1. Argo CD — https://127.0.0.1:18081
2. Kafka / Redpanda Console — http://127.0.0.1:18082
3. Spark History Server — http://127.0.0.1:18083
4. Grafana — http://127.0.0.1:13001
5. Prometheus — http://127.0.0.1:19090
6. Jupyter — http://127.0.0.1:18888
7. Trino — http://127.0.0.1:18080
8. Polaris Console — http://127.0.0.1:18182
9. RustFS Console — http://127.0.0.1:19001

Dans Jupyter, ouvrir `ICEBERG_EXPLORER.ipynb`.
