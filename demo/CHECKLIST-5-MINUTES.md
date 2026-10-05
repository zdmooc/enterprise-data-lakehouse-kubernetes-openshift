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
