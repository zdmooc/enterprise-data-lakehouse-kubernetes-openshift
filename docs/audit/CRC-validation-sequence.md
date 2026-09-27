# Commandes différées — CRC, I1 à I12

Ces commandes sont destinées à une fenêtre ultérieure choisie par le propriétaire
du CRC. **Aucune n'a été exécutée pendant l'audit.** Lancer une section à la fois,
arrêter au premier échec, conserver les preuves et vérifier les ressources libres
avant de poursuivre. Ne pas lancer `cleanup-baseline.sh` pour remettre le labo à zéro.

Les BuildConfigs et Applications pointent encore sur `main`. Exécuter cette
séquence seulement après intégration des correctifs sur `main`, ou après avoir
aligné explicitement toutes leurs références Git sur le commit audité. Un checkout
local corrigé ne change pas la source distante consommée par OpenShift/Argo CD.

Depuis Bash, à la racine du dépôt :

```bash
set -euo pipefail
git status --short --branch
git rev-parse HEAD
oc whoami
oc config current-context
oc get nodes
oc -n edl-data get resourcequota,limitrange  # si le namespace existe déjà
```

## I1 — Contrat cluster

```bash
bash tests/i1/run-all.sh
bash tests/i1/cleanup.sh
```

La suite crée `edl-i1-contract-test`; la sonde réseau crée puis supprime
`data-platform-preflight`. Si ce dernier existe déjà, elle s'arrête sans le
supprimer. L'exposition vérifie l'API Route et l'allocation du host uniquement.
Une requête HTTP vers une vraie application via Route reste nécessaire.

## I2 — Baseline

```bash
oc apply -k platform/baseline/overlays/openshift-crc
bash scripts/verify-baseline.sh
bash scripts/apply-data-networking.sh
oc -n edl-data get resourcequota,limitrange,networkpolicy
```

Vérifier également DNS depuis un workload EDL sous deny-egress : le test I1 seul
ne prouve pas cette configuration. Relever SCC sélectionnée, UID et accès PVC des
workloads de chaque étape ; ne pas attribuer une SCC privilégiée pour contourner
un échec d'admission.

## I3 — GitOps

Réutiliser le service GitOps existant. L'installation d'un Operator et ses CRD
est une opération transverse : ne pas relancer un installateur par réflexe.
Si GitOps est absent, étudier `scripts/install-openshift-gitops.sh` dans une fenêtre
spécifique avant de poursuivre. Vérifier les droits du controller pour les trois
namespaces EDL et les Namespace cluster-scoped.

```bash
oc get crd applications.argoproj.io appprojects.argoproj.io
bash scripts/bootstrap-gitops.sh
bash scripts/gitops-status.sh
```

Exécuter ensuite le laboratoire `docs/labs/I3-gitops-drift-rollback.md` pour prouver
drift, self-heal et revert. L'Application baseline doit être Synced **et** Healthy.
Ne pas activer l'Application Trino optionnelle si la voie Helm ci-dessous est
retenue. Pour une voie entièrement GitOps, ajouter `values-lakehouse.yaml` à ses
`valueFiles`, fournir les Secrets prérequis et laisser Argo réconcilier.

## I4 — S3

Employer un bucket et des credentials dédiés au POC. Le profil intégré corrigé
attend HTTPS/443 et un certificat reconnu par toutes les images. Ne pas utiliser
`localhost` comme endpoint destiné aux pods. Saisir les secrets hors capture :

```bash
read -r -p 'S3 endpoint HTTPS: ' S3_ENDPOINT
read -r -p 'EDL bucket: ' S3_BUCKET
read -r -p 'S3 region: ' S3_REGION
read -r -s -p 'Access key: ' AWS_ACCESS_KEY_ID; printf '\n'
read -r -s -p 'Secret key: ' AWS_SECRET_ACCESS_KEY; printf '\n'
export S3_ENDPOINT S3_BUCKET S3_REGION AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
export S3_ENDPOINT_INTERNAL="$S3_ENDPOINT"
bash scripts/bootstrap-s3-layout.sh
bash scripts/verify-s3-layout.sh
```

`bootstrap-s3-layout.sh` crée seulement les marqueurs dans un bucket existant par
défaut. La création du bucket exige explicitement `S3_CREATE_BUCKET=yes`.

## I5 — Kafka

Vérifier quel Operator Strimzi surveille `edl-data`. S'il est absent, examiner
`scripts/install-strimzi.sh` et ses modifications CRD/ClusterRole avant installation
dans une fenêtre dédiée. Ne pas remplacer un Operator utilisé par un autre POC.

```bash
oc get crd kafkas.kafka.strimzi.io kafkanodepools.kafka.strimzi.io
bash scripts/deploy-kafka-crc.sh
oc -n edl-data wait kafkatopic/edl.smoke --for=condition=Ready --timeout=180s
oc -n edl-data wait kafkatopic/transactions.raw --for=condition=Ready --timeout=180s
bash scripts/test-kafka.sh
bash scripts/produce-synthetic-transactions.sh
```

Si l'ancienne version a écrit `edl-smoke-*` dans `transactions.raw`, attendre leur
expiration ou préparer une migration explicite. Ne pas supprimer le topic à
l'aveugle. La correction ne modifie pas les données historiques.

## I6 — Spark

```bash
bash scripts/test-spark-crc.sh
bash scripts/test-spark-transform-crc.sh
oc -n edl-data get pods -l spark-role=driver -o wide
```

Conserver les logs Pi et agrégation, la fin du Job, les limites mémoire effectives
driver/executor et les annotations SCC. Contrôler séparément la construction de
l'image OpenShift, son contexte source et l'accès aux dépendances externes.

## I7 — Trino

```bash
bash scripts/install-trino-crc.sh
bash scripts/test-trino.sh
oc -n edl-data get service edl-trino
```

La requête TPCH attend 1500 clients. Relever aussi la présence du worker ; une
réponse SQL seule ne prouve pas tous les chemins d'exécution distribuée.

## I8 — Jupyter

```bash
bash scripts/deploy-jupyter-crc.sh
bash scripts/test-jupyter-trino.sh
CONFIRM_JUPYTER_RESTART=yes bash scripts/test-jupyter-pvc-restart.sh
oc -n edl-data get route edl-jupyter
```

Récupérer le token du Secret `jupyter-auth` dans une session privée hors logs de
preuve, puis vérifier la connexion HTTPS dans un navigateur. Aucun token n'est
désormais imprimé par le déploiement E2E.

## I9 — Sécurité

Réutiliser Kyverno s'il est déjà présent et compatible. L'installation globale
via `scripts/install-kyverno.sh` nécessite une fenêtre dédiée sur ce CRC partagé.

```bash
oc get crd namespacedvalidatingpolicies.policies.kyverno.io
bash scripts/apply-security-policies.sh
bash scripts/test-security-policies.sh
bash scripts/test-security-negative-suite.sh
```

En dehors du cluster, avec un exécutable Trivy disponible :

```bash
trivy config --severity HIGH,CRITICAL --exit-code 1 .
```

Vault, OIDC/Keycloak et signatures Cosign restent des patterns/documentations ;
leurs preuves nécessitent une identité, un registry et des intégrations dédiés.

## I10 — Observabilité

Réutiliser User Workload Monitoring. Si désactivé, organiser son activation avec
le propriétaire du CRC ; les scripts ne l'activent pas automatiquement.

```bash
bash scripts/check-openshift-user-workload-monitoring.sh
bash scripts/apply-observability-openshift.sh
bash scripts/test-observability-openshift.sh
oc -n edl-data get podmonitor,servicemonitor,prometheusrule
```

Dans la console Monitoring, contrôler les targets UP, les séries utilisées par
chaque règle et dashboard, puis un cycle déclenchement/résolution avec réception
d'alerte. Les scripts ne certifient pas ces trois étapes.

## I11 — Reprise et N3

Dans une fenêtre explicitement réservée à la perturbation du POC EDL :

```bash
bash scripts/n3-diagnostics.sh
CONFIRM_CHAOS=yes NAMESPACE=edl-data SELECTOR='app=edl-jupyter' bash scripts/chaos-delete-pod.sh
CONFIRM_JUPYTER_RESTART=yes bash scripts/test-jupyter-pvc-restart.sh
bash scripts/collect-runtime-evidence.sh
```

Suivre les autres scénarios de `docs/11-resilience-test-matrix.md` un par un.
Ne pas supprimer Polaris in-memory pour prétendre démontrer une reprise des
métadonnées. Perte de worker, réplication, zones et contrôle-plane attendent une
cible multi-node distincte et un plan de test dédié.

## I12 — Chaîne intégrée

Réexporter les variables S3 de I4 dans la même session. Le script fait les builds
et déploiements EDL : le lancer seulement lorsque I1–I11 ont été traitées et la
capacité disponible est confirmée.

```bash
CONFIRM_EDL_E2E=yes bash scripts/e2e-lakehouse-crc.sh
```

Il installe/configure Polaris, utilise le topic JSON, construit Spark/Iceberg,
requête `polaris.analytics.transactions` via Trino puis Jupyter, et collecte les
preuves. L'échec I3/I10 reste signalé séparément : succès du chemin Data ne vaut
pas acceptation de ces itérations. Comparer eventId et agrégats, pas seulement le
nombre de lignes. Copier une synthèse expurgée vers `evidence/templates/I12-e2e.md`.

Ordre recommandé : **I1 → I2 → I3 → I4 → I5 → I6 → I7 → I8 → I9 → I10 → I11 → I12**.
Répéter ensuite les scénarios distribués sur un cluster multi-node ; aucune
capacité multi-node n'est démontrée par ce document.
