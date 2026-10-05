# Troubleshooting de la démo

## Control-plane NotReady après CRC -> Kind

Vérifier les IP Docker. Le mapping retenu est :

    control-plane = 172.18.0.2
    worker2       = 172.18.0.3
    worker        = 172.18.0.4

Utiliser `demo/scripts/01-switch-crc-to-kind.sh`. Ne jamais supprimer le cluster pour corriger ce cas.

## Calico 0/1 ou CrashLoop

    kubectl -n kube-system wait       --for=condition=Ready       pod       -l k8s-app=calico-node       --timeout=300s

Si les IP Docker sont fausses, corriger d'abord le mapping.

## Trino : Cannot obtain metadata

Polaris in-memory a probablement perdu le catalogue :

    CONFIRM_DEMO_RECOVERY=yes bash demo/scripts/03-restore-i12.sh

## FileNotFoundError dans restore-polaris-i12.py

Le pointeur `.audit/kind/evidence-dir` peut viser un répertoire récent sans I12. Le script de récupération le repositionne sur `evidence/kind-edl-lab/20260928T112119Z` après vérification des fichiers.

## Git Bash se ferme après source common.sh

Ne pas sourcer `scripts/kind/common.sh` dans un shell interactif. Il active `set -euo pipefail`.

## Metrics API not available

`kubectl top` peut être indisponible sans invalider Prometheus. Vérifier les pods `edl-observability` et l'interface Prometheus.

## kind-s3-reader Unknown

C'est un pod diagnostic stateless. Le script de bascule peut le recréer sans toucher aux données.

## Port local déjà utilisé

    bash demo/scripts/06-stop-interfaces.sh
    ps -W | grep kubectl

Puis relancer les interfaces.

## Argo CD non Synced/Healthy

    kubectl -n argocd get applications
    kubectl -n argocd get pods
    kubectl -n argocd logs deploy/argocd-repo-server --tail=100

Ne pas provoquer de drift pendant l'entretien.

## Commandes à éviter pendant la démo

- chaos pod deletion ;
- réinstallation d'Operator ;
- E2E complet ;
- suppression namespace/PVC ;
- rebuild images ;
- `kind delete cluster` ;
- `crc delete`.
