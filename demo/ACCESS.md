# Accès aux interfaces — préparation privée

Ce document est destiné à la préparation avant partage d'écran. Ne jamais afficher les secrets pendant l'entretien.

## Démarrer les port-forwards

    bash demo/scripts/04-start-interfaces.sh

## Jupyter

URL :

    http://127.0.0.1:18888

Le secret utilisé par le lab est `jupyter-auth`, clé `token`.

Récupération privée :

    kubectl -n edl-data get secret jupyter-auth       -o jsonpath='{.data.token}' | base64 -d
    echo

Ouvrir Jupyter avant le partage d'écran puis effacer le terminal contenant le token.

## Grafana

URL :

    http://127.0.0.1:13000

Le secret est `kind-grafana-admin`.

Récupération privée :

    echo -n "user="
    kubectl -n edl-observability get secret kind-grafana-admin       -o jsonpath='{.data.username}' | base64 -d
    echo

    echo -n "password="
    kubectl -n edl-observability get secret kind-grafana-admin       -o jsonpath='{.data.password}' | base64 -d
    echo

Se connecter avant le partage d'écran.

## Prometheus

URL :

    http://127.0.0.1:19090

Vue utile :

    Status -> Targets

La valeur live prévaut sur la preuve historique. Le snapshot retenu avait 21 targets UP.

## Argo CD

URL :

    https://127.0.0.1:18081

Le compte initial Helm est généralement `admin`. Vérifier d'abord si le secret initial existe :

    kubectl -n argocd get secret argocd-initial-admin-secret

S'il existe et que le mot de passe initial est encore utilisé :

    kubectl -n argocd get secret argocd-initial-admin-secret       -o jsonpath='{.data.password}' | base64 -d
    echo

S'il n'existe plus, utiliser les identifiants déjà configurés. Ne pas recréer ou réinitialiser le mot de passe pendant une démo.

## Trino

URL locale :

    http://127.0.0.1:18080

La preuve principale reste la requête CLI exécutée dans le coordinator :

    kubectl -n edl-data exec deployment/edl-trino-coordinator --       trino --server http://localhost:8080 --user edl       --execute 'SELECT eventId, transactionId, amount, status FROM polaris.analytics.transactions ORDER BY eventId'

## Polaris

API :

    http://127.0.0.1:18181

Polaris n'est pas utilisé comme écran principal de la démo. Il sert à expliquer le rôle du catalogue Iceberg REST.

## S3 compatible

Health endpoint :

    http://127.0.0.1:19000/health

Le provider Kind actuel expose le contrat S3 compatible. Ne pas afficher les credentials S3.

## Nettoyage

    bash demo/scripts/06-stop-interfaces.sh


## Visual demo endpoints

After installing the visualization layer and starting the port-forwards:

    Kafka / Redpanda Console  http://127.0.0.1:18082
    Spark History Server      http://127.0.0.1:18083
    Polaris Console           http://127.0.0.1:18182
    RustFS Console            http://127.0.0.1:19001

The existing access rules still apply:

- Kafka Console: no additional login in the local Kind profile.
- Spark History Server: no additional login in the local Kind profile.
- Polaris Console: use the Polaris client credentials already stored in Kubernetes and realm `POLARIS`.
- RustFS Console: use the S3 access key / secret key already stored in Kubernetes.

Do not expose credentials in screenshots or screen sharing.
