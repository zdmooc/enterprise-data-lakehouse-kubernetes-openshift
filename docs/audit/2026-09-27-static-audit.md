# Audit statique du POC — 27 septembre 2026

Base auditée : `80c2014c939c783593e6f9a825640f4fb6257089`, branche `main`, copie propre à la récupération. 194 fichiers suivis, 221 commits accessibles. Aucune commande runtime CRC, aucun pod/build/operator lancé, aucun autre POC modifié.

La CI initiale est verte : [run 36262684555](https://github.com/zdmooc/enterprise-data-lakehouse-kubernetes-openshift/actions/runs/36262684555). Elle vérifiait surtout syntaxe Shell, rendus Kustomize sélectionnés et JSON ; elle ne couvrait pas les contrats Helm/E2E.

## Diagnostic revalidé

| Priorité | Défaut | Localisation dans le commit initial |
|---|---|---|
| P0 | DNS OpenShift | [platform/baseline/base/networkpolicies.yaml:34](https://github.com/zdmooc/enterprise-data-lakehouse-kubernetes-openshift/blob/80c2014c939c783593e6f9a825640f4fb6257089/platform/baseline/base/networkpolicies.yaml#L34) |
| P0 | Build Spark I6 | [data-platform/spark/image/Dockerfile:5](https://github.com/zdmooc/enterprise-data-lakehouse-kubernetes-openshift/blob/80c2014c939c783593e6f9a825640f4fb6257089/data-platform/spark/image/Dockerfile#L5) |
| P0 | Producteur Kafka | [scripts/produce-synthetic-transactions.sh:21](https://github.com/zdmooc/enterprise-data-lakehouse-kubernetes-openshift/blob/80c2014c939c783593e6f9a825640f4fb6257089/scripts/produce-synthetic-transactions.sh#L21) |
| P0 | Contrat JSON Kafka | [scripts/test-kafka.sh:9](https://github.com/zdmooc/enterprise-data-lakehouse-kubernetes-openshift/blob/80c2014c939c783593e6f9a825640f4fb6257089/scripts/test-kafka.sh#L9) |
| P0 | Nom Trino | [data-platform/trino/values-crc.yaml:1](https://github.com/zdmooc/enterprise-data-lakehouse-kubernetes-openshift/blob/80c2014c939c783593e6f9a825640f4fb6257089/data-platform/trino/values-crc.yaml#L1) |
| P0 | Mémoire Trino | [data-platform/trino/values-crc.yaml:14](https://github.com/zdmooc/enterprise-data-lakehouse-kubernetes-openshift/blob/80c2014c939c783593e6f9a825640f4fb6257089/data-platform/trino/values-crc.yaml#L14) |
| P0 | Scripts Jupyter masqués | [data-platform/jupyter/image/Dockerfile:7](https://github.com/zdmooc/enterprise-data-lakehouse-kubernetes-openshift/blob/80c2014c939c783593e6f9a825640f4fb6257089/data-platform/jupyter/image/Dockerfile#L7) |
| P0 | Flux Spark incomplets | [data-platform/networking/base/data-product-flows.yaml:160](https://github.com/zdmooc/enterprise-data-lakehouse-kubernetes-openshift/blob/80c2014c939c783593e6f9a825640f4fb6257089/data-platform/networking/base/data-product-flows.yaml#L160) |
| P0 | API Strimzi sous deny egress | [data-platform/networking/base/data-product-flows.yaml:4](https://github.com/zdmooc/enterprise-data-lakehouse-kubernetes-openshift/blob/80c2014c939c783593e6f9a825640f4fb6257089/data-platform/networking/base/data-product-flows.yaml#L4) |
| P0 | S3 sans STS | [data-platform/trino/values-lakehouse.yaml:14](https://github.com/zdmooc/enterprise-data-lakehouse-kubernetes-openshift/blob/80c2014c939c783593e6f9a825640f4fb6257089/data-platform/trino/values-lakehouse.yaml#L14) |
| P0 | Exposition credentials Spark | [data-platform/lakehouse/openshift/spark-submit-job.yaml:36](https://github.com/zdmooc/enterprise-data-lakehouse-kubernetes-openshift/blob/80c2014c939c783593e6f9a825640f4fb6257089/data-platform/lakehouse/openshift/spark-submit-job.yaml#L36) |
| P0 | Nettoyage namespace préexistant | [scripts/test-networkpolicy.sh:8](https://github.com/zdmooc/enterprise-data-lakehouse-kubernetes-openshift/blob/80c2014c939c783593e6f9a825640f4fb6257089/scripts/test-networkpolicy.sh#L8) |
| P1 | Faux succès réseau | [scripts/test-networkpolicy.sh:52](https://github.com/zdmooc/enterprise-data-lakehouse-kubernetes-openshift/blob/80c2014c939c783593e6f9a825640f4fb6257089/scripts/test-networkpolicy.sh#L52) |
| P1 | RBAC et validateur tronqué | [scripts/test-rbac.sh:41](https://github.com/zdmooc/enterprise-data-lakehouse-kubernetes-openshift/blob/80c2014c939c783593e6f9a825640f4fb6257089/scripts/test-rbac.sh#L41) |
| P1 | Argo Missing accepté | [scripts/bootstrap-gitops.sh:34](https://github.com/zdmooc/enterprise-data-lakehouse-kubernetes-openshift/blob/80c2014c939c783593e6f9a825640f4fb6257089/scripts/bootstrap-gitops.sh#L34) |
| P1 | Faux refus admission | [scripts/test-security-policies.sh:7](https://github.com/zdmooc/enterprise-data-lakehouse-kubernetes-openshift/blob/80c2014c939c783593e6f9a825640f4fb6257089/scripts/test-security-policies.sh#L7) |
| P1 | Relance Secrets | [scripts/install-polaris-crc.sh:22](https://github.com/zdmooc/enterprise-data-lakehouse-kubernetes-openshift/blob/80c2014c939c783593e6f9a825640f4fb6257089/scripts/install-polaris-crc.sh#L22) |
| P1 | Conflit Argo/Helm Trino | [gitops/apps/openshift-crc/trino.yaml:15](https://github.com/zdmooc/enterprise-data-lakehouse-kubernetes-openshift/blob/80c2014c939c783593e6f9a825640f4fb6257089/gitops/apps/openshift-crc/trino.yaml#L15) |
| P1 | Monitoring inaccessible/incomplet | [observability/openshift/kafka-podmonitor.yaml:9](https://github.com/zdmooc/enterprise-data-lakehouse-kubernetes-openshift/blob/80c2014c939c783593e6f9a825640f4fb6257089/observability/openshift/kafka-podmonitor.yaml#L9) |
| P1 | Preuve de reprise | [scripts/chaos-delete-pod.sh:40](https://github.com/zdmooc/enterprise-data-lakehouse-kubernetes-openshift/blob/80c2014c939c783593e6f9a825640f4fb6257089/scripts/chaos-delete-pod.sh#L40) |
| P1 | Réplication multi-node | [data-platform/kafka/profiles/multinode/kustomization.yaml:5](https://github.com/zdmooc/enterprise-data-lakehouse-kubernetes-openshift/blob/80c2014c939c783593e6f9a825640f4fb6257089/data-platform/kafka/profiles/multinode/kustomization.yaml#L5) |

Chaque entrée ci-dessous est corrigée dans la branche locale ; « corrigée » décrit les fichiers, jamais une preuve cluster.

### P0 — DNS OpenShift

Risque/reproduction : DNS autorisé uniquement vers kube-system:53; OpenShift utilise openshift-dns et le port cible 5353.

Correction minimale : Overlay DNS OpenShift dédié, conservant la base Kubernetes.

Non-régression/limite : Modèle des politiques rendues: DNS UDP/5353.

### P0 — Build Spark I6

Risque/reproduction : COPY relatif à la racine du dépôt alors que contextDir=data-platform/spark; source absente du contexte.

Correction minimale : COPY jobs/. Le correctif précédent du BuildConfig I12 est bien présent.

Non-régression/limite : Résolution des sources COPY depuis chaque contexte BuildConfig.

### P0 — Producteur Kafka

Risque/reproduction : Le pod ne porte pas le label de la règle de sortie Kafka; deny egress empêche la production.

Correction minimale : Ajouter le label kafka-client.

Non-régression/limite : Sélecteur du producteur et modèle réseau 9092.

### P0 — Contrat JSON Kafka

Risque/reproduction : Le smoke test écrit edl-smoke-* dans transactions.raw; json.loads du consommateur E2E échoue dès ce message.

Correction minimale : Topic edl.smoke distinct et déclaré. Aucun effacement du topic existant.

Non-régression/limite : Contrôle de séparation des topics; les anciens messages doivent expirer ou être traités explicitement avant reprise.

### P0 — Nom Trino

Risque/reproduction : Le chart 1.42.2 rend edl-trino-trino; tous les clients utilisent edl-trino.

Correction minimale : fullnameOverride: edl-trino.

Non-régression/limite : helm template puis vérification du nom et du port du Service.

### P0 — Mémoire Trino

Risque/reproduction : Le défaut du chart produit query.max-memory-per-node=1GB pour un heap de 512M.

Correction minimale : Fixer le coordinateur à 256MB, comme le worker.

Non-régression/limite : Lecture des ConfigMaps Helm rendues.

### P0 — Scripts Jupyter masqués

Risque/reproduction : Le PVC monté sur /home/jovyan/work masque les samples COPY de l’image.

Correction minimale : Installer les samples sous /opt/edl-samples et aligner les deux sondes.

Non-régression/limite : Comparaison destination COPY / montage PVC.

### P0 — Flux Spark incomplets

Risque/reproduction : Driver vers executor bloqué, executor vers S3 bloqué; I12 n’applique pas la règle ingress Spark de I6. Port API cible 6443 non couvert.

Correction minimale : RPC fixé à 7078, block manager à 7079, règles explicites et labels API; scripts I5-I8 appliquent les prérequis réseau.

Non-régression/limite : Modèle bidirectionnel des politiques rendues, incluant un refus depuis un autre POC.

### P0 — API Strimzi sous deny egress

Risque/reproduction : Le Cluster Operator n’a pas de sortie API; les pods portant le label du cluster sont limités au namespace.

Correction minimale : Sortie API 443/6443 pour Cluster Operator et pods du cluster.

Non-régression/limite : Inspection des selectors; labels réellement générés et DNAT restent à observer sur CRC.

### P0 — S3 sans STS

Risque/reproduction : Le profil générique exige du vending mais ne fournit ni rôle STS ni contrat STS. Ce n’est pas un contrat fonctionnel pour un fournisseur sans STS.

Correction minimale : Profil CRC explicitement sans STS; Secrets S3 référencés par Polaris, Spark et Trino; stockage sous curated/.

Non-régression/limite : Assertions du contrat; API Polaris 1.7 consultée. HTTPS/443 requis. Authentification réelle et accès objets restent à exécuter.

### P0 — Exposition credentials Spark

Risque/reproduction : Interpolation du secret dans la commande spark-submit et l’environnement littéral du driver, visibles aux lecteurs de Pods.

Correction minimale : secretKeyRef Spark et redaction credential dans la configuration Spark.

Non-régression/limite : Absence de passage driverEnv littéral; inspection du Job.

### P0 — Nettoyage namespace préexistant

Risque/reproduction : Trap enregistré avant create ns; si le namespace existe déjà, l’échec déclenche sa suppression. Même défaut DNS/PVC/RBAC.

Correction minimale : Armer cleanup seulement après création réussie; borne stricte pour NS de la seconde suite I1.

Non-régression/limite : CLI simulée create en échec, journal de suppression obligatoirement vide.

### P1 — Faux succès réseau

Risque/reproduction : Création/attente du client refusé ignorées avec || true; succès possible sans refus observé.

Correction minimale : Baseline positive, curl timeout=28 avec exec réussi, contrôle de rétablissement; seconde entrée I1 déléguée.

Non-régression/limite : CLI simulée: connectivité encore ouverte, DNS, connexion refusée, HTTP et erreur API doivent échouer.

### P1 — RBAC et validateur tronqué

Risque/reproduction : can-i répond no avec exit 1; set -e quitte avant assertion. validate-baseline contient des fonctions/variables non définies.

Correction minimale : Accepter le code négatif puis vérifier exactement no; wrapper vers verify-baseline.

Non-régression/limite : CLI simulée renvoie no/1: les trois points d’entrée doivent terminer correctement.

### P1 — Argo Missing accepté

Risque/reproduction : Synced/Missing accepté malgré la documentation demandant Synced/Healthy. Aucun placeholder non substitué confirmé.

Correction minimale : Exiger Healthy.

Non-régression/limite : Simulation Missing échoue et Healthy réussit.

### P1 — Faux refus admission

Risque/reproduction : Toute erreur serveur était acceptée comme refus de latest; les fixtures ne satisfont pas le PSS restricted.

Correction minimale : Contrôle positif, raison nommant la policy attendue, contextes restricted; raisons SCC/PSS vérifiées dans la suite négative. CRD namespaced alignée.

Non-régression/limite : Simulation connexion refusée rejetée comme preuve; réponse attendue acceptée.

### P1 — Relance Secrets

Risque/reproduction : Secrets Polaris et Jupyter régénérés à chaque exécution sans garantie de redémarrage des consommateurs; désynchronisation possible.

Correction minimale : Réutiliser le secret existant; ne plus imprimer le token Jupyter.

Non-régression/limite : Inspection des références et branche de réutilisation; rotation effective reste une procédure distincte.

### P1 — Conflit Argo/Helm Trino

Risque/reproduction : Application auto selfHeal ne charge que values-crc; elle peut retirer le catalogue ajouté impérativement par Helm.

Correction minimale : Arrêt de enable-trino-lakehouse si edl-trino est une Application existante; documentation de la voie GitOps.

Non-régression/limite : Inspection du garde-fou; scénario de drift reste runtime.

### P1 — Monitoring inaccessible/incomplet

Risque/reproduction : Monitoring hors edl-data bloqué; Kafka Exporter n’a pas de PodMonitor spécifique. Le test passe avec workloads absents.

Correction minimale : Ingress depuis UWM, monitor Kafka Exporter, arrêt si Kafka/Trino absents et message limité aux objets/endpoint local.

Non-régression/limite : Modèle des flux 9404/8080, YAML; séries, alertes et targets UP restent à démontrer.

### P1 — Preuve de reprise

Risque/reproduction : Attente Ready ignorée; test Jupyter peut relire le pod en cours de suppression.

Correction minimale : Attente Ready impérative; suppression Jupyter attendue et vérification nom différent.

Non-régression/limite : Inspection des chemins déchec et syntaxe; aucune suppression réellement exécutée.

### P1 — Réplication multi-node

Risque/reproduction : Topics héritent replicas=1 malgré brokers=3 et min.insync.replicas=2.

Correction minimale : Patch topics à replicas=3.

Non-régression/limite : Rendu Kustomize multi-node; placement inter-nœuds reste à concevoir/prouver.

## Résultats antérieurs non confirmés

- Aucun jeton OAuth/Keycloak reconnaissable détecté par le scan par motifs des 218 blobs accessibles depuis les 221 commits. Ce scan recherche JWT, clés privées, jetons GitHub/OpenShift, clés AWS et affectations littérales de secrets. Ce n’est pas une preuve d’absence de tout secret, ni un audit des autres dépôts cités.
- Aucune Application enfant avec variable à substituer trouvée. `$values` est une référence Argo multi-source correcte vers `ref: values`, et non un placeholder shell.
- README principal distingue bien implementation et runtime en attente. La phrase I6 « proves » et « implementation-complete » étaient trop fortes : reformulées. Les patterns Vault/OIDC/Cosign ne sont pas des services déployés.

## Couverture et preuves statiques

- Tous les scripts Shell passent par `bash -n`; tous les YAML/YML par PyYAML; Python par AST; les deux dashboards par JSON.
- Tous les répertoires Kustomize sont rendus, y compris multi-node, bases et overlays; charts Trino 1.42.2 et Polaris 1.7.0 téléchargés et rendus localement.
- Contrats vérifiés : noms/services/ports, source COPY/BuildConfig, samples/PVC, topics JSON, Secrets, flux NetworkPolicy ingress **et** egress.
- Les tests de comportement utilisent des faux exécutables oc/kubectl dans un PATH isolé. Aucune sonde cluster ne se cache derrière ces tests.
- Rapport automatisé final et liste de fichiers : voir `static-results.txt` et `changed-files.txt` dans ce répertoire.
- CRD/admission réelles, signatures d’images, analyse complète Trivy, dépendances transitives et comportement SCC/CNI ne sont pas prouvés par ces vérifications.

## P2 et risques encore ouverts

- Polaris in-memory perd ses métadonnées au redémarrage. Le compte root reste partagé dans le profil CRC : séparation des identités, autorisations par catalogue, TLS applicatif et rotation à poursuivre avant usage durable.
- Le profil S3 est désormais explicite : HTTPS/443, certificat de confiance, bucket EDL dédié, credentials sans STS. Un fournisseur HTTP/9000 ou un endpoint spécifique nécessite son overlay réseau et son contrat TLS. Ne pas ouvrir un autre namespace de POC par défaut.
- Egress 0.0.0.0/0 sur 443/6443 et ingress Kafka intra-namespace restent larges, adaptés au labo; réduire les destinations après découverte des CIDR. DNS hostNetwork/DNAT et labels réels des Operators demandent les preuves CRC.
- RBAC Spark autorise la création de Pods : cela permet indirectement de monter des Secrets du namespace. Isolation par namespace et identités de travail nécessaires pour une vraie séparation des tenants.
- Argo CD/OpenShift GitOps existant : vérifier les droits de son controller sur les namespaces EDL et la création des Namespaces avant bootstrap. Installer des CRD/Operators reste une opération transverse, jamais anodine pour les autres POC.
- Quotas 4 CPU demandés/8 CPU limites et 8/16 Gi mémoire doivent être confrontés aux ressources **effectivement générées** par Strimzi/Spark/Helm et à la capacité CRC déjà utilisée. Les pods de build et leurs besoins SCC/egress sont une porte de validation spécifique.
- Jupyter et Spark doivent encore démontrer UID arbitraire, permissions PVC, droits des chemins internes de leurs images et admission restricted. La présence dun securityContext dans un chart ne prouve pas le démarrage.
- Traitement I12 batch borné par inactivité Kafka : charge tous les événements en mémoire, remplace la table, ne déduplique pas les eventId et ne démontre pas exactly-once. Les anciens messages non JSON ne sont pas supprimés automatiquement.
- Les applications Argo optionnelles Kafka/Trino ne sont pas bootstrappées par le script initial. Pour Trino choisir une autorité : Helm CRC ou Application enrichie des valeurs Lakehouse, sans concurrence.
- Métriques Kafka/Trino, noms de séries, disponibilité des métriques kubelet/kube-state dans l’évaluation UWM, routage Alertmanager et datasources Grafana restent à vérifier. Les dashboards JSON ne prouvent aucune série présente.
- Profil Kafka multi-node : RF=3 corrigé mais anti-affinité, topologySpread, PDB, capacités et scénarios perte de nœud restent à travailler. Aucun résultat de résilience multi-node.
- Fichiers historiques non référencés `platform/baseline/base/{namespace,limitrange,resourcequota}.yaml` concernent data-product-demo. Ne pas les appliquer récursivement; utiliser Kustomize. Nettoyage documentaire possible en P2.
- Tags d’images majoritairement mutables, téléchargements JAR sans vérification cryptographique et actions CI référencées par tags. Aucun nouveau digest nest inventé. La compatibilité binaire et le scan supply-chain restent à établir.

## Sources techniques primaires consultées

- [Trino chart 1.42.2](https://github.com/trinodb/charts/tree/trino-1.42.2/charts/trino) — nommage et paramètres mémoire; paquet réellement rendu.
- [Trino 480 FileSystemConfig](https://github.com/trinodb/trino/blob/480/lib/trino-filesystem-manager/src/main/java/io/trino/filesystem/manager/FileSystemConfig.java) — `fs.native-s3.enabled` conservé : le renommer selon une documentation plus récente aurait introduit une régression.
- [API Polaris 1.7.0](https://github.com/apache/polaris/blob/apache-polaris-1.7.0/spec/polaris-management-service.yml) — `stsUnavailable` désactive le vending.
- [Spark Kubernetes](https://spark.apache.org/docs/latest/running-on-kubernetes.html) — références Secret et configuration réseau à confronter aux versions 4.1/4.2 épinglées.
- [DNS OpenShift](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/networking_operators/dns-operator) — namespace DNS et opérateur.

## Livraison et suite

I0 COMPLETED ; I1–I12 IMPLEMENTED (code/manifests/scripts/docs ou patterns présents). CRC runtime : en attente pour I1–I12. Voir [commandes différées](CRC-validation-sequence.md). Les validations statiques ne changent aucun de ces statuts runtime.

## Tableau de livraison

« OK statique » signifie que les contrôles locaux applicables passent, pas que le
service a démarré. Les patterns non exécutables sont relus, sans preuve de déploiement.

| Iteration | Git | Static validation | CRC runtime | Remaining |
|-----------|-----|-------------------|-------------|-----------|
| I0 | COMPLETED | Architecture et périmètre relus | Sans objet | Conserver la distinction cible/preuve |
| I1 | IMPLEMENTED | Syntaxe et simulations des sondes | En attente | DNS, PVC, RBAC, réseau et exposition réels |
| I2 | IMPLEMENTED | YAML et overlays rendus | En attente | Admission, DNS EDL, quotas/capacité |
| I3 | IMPLEMENTED | Applications/projet et simulation Healthy/Missing | En attente | Droits controller, sync, drift, revert |
| I4 | IMPLEMENTED | Scripts et contrat S3 relus | En attente | PUT/GET/intégrité/DELETE, TLS, bucket dédié |
| I5 | IMPLEMENTED | Rendus CRC/multi-node, topics et flux | En attente | Operator, Kafka Ready, JSON, réplication réelle |
| I6 | IMPLEMENTED | Contextes COPY, Jobs, RBAC et flux | En attente | Build, SCC, Pi, agrégation |
| I7 | IMPLEMENTED | Rendu Helm, nom Service et mémoire | En attente | Démarrage, worker, TPCH puis Iceberg |
| I8 | IMPLEMENTED | Samples hors PVC, manifests et scripts | En attente | Build, Route/login, SQL et persistance |
| I9 | IMPLEMENTED | Policy YAML, fixtures et refus simulés | En attente | Admission réelle, Trivy, IAM/signatures séparés |
| I10 | IMPLEMENTED | JSON/YAML et flux monitoring | En attente | Targets UP, séries, alertes et dashboards |
| I11 | IMPLEMENTED | Runbooks et branches de reprise relus | En attente | Recréation, chronométrage, intégrité ; multi-node ultérieur |
| I12 | IMPLEMENTED | Contrats E2E et régressions hors cluster | En attente | S3/Polaris/Spark/Trino/Jupyter ensemble |
