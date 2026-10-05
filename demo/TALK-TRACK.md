# Talk track — 12 à 15 minutes

## Introduction

> J'ai construit ce POC comme une plateforme Data d'entreprise, pas comme un catalogue d'outils. L'objectif est de montrer le rôle d'une équipe Platform Engineering qui fournit un Kubernetes gouverné, industrialisé et observable pour des Data Products.

## Architecture

> Le flux part de Kafka. Spark transforme les événements vers Iceberg sur un stockage S3-compatible. Polaris fournit le catalogue Iceberg REST, Trino expose la couche SQL et Jupyter représente l'expérience Data utilisateur. Autour, Argo CD apporte GitOps, Kyverno/RBAC/NetworkPolicy la gouvernance sécurité, et Prometheus/Grafana l'observabilité.

## Kubernetes

> Le runtime de démo est un cluster Kind trois nœuds. C'est une preuve locale multi-node, pas une preuve HA de production. Le but est de valider les contrats de plateforme, l'intégration et les procédures Day-2.

À montrer : `kubectl get nodes -o wide`.

## GitOps

> Les applications Argo sont Synced et Healthy. Git représente l'état désiré, Argo détecte le drift et réconcilie. Les scénarios de drift/self-heal ont été validés auparavant ; pendant l'entretien je reste read-only.

## Data Product

> Ici on voit les six transactions retenues dans la table Iceberg. Une transaction I12 supplémentaire est conservée avec les cinq événements historiques.

Montrer Trino puis Jupyter.

## Polaris

> Le stockage des données est persistant dans S3/Iceberg. Polaris est volontairement in-memory dans ce lab. Après restart, je ne rejoue pas Kafka et je ne relance pas Spark : je réenregistre uniquement le metadata file Iceberg existant.

## Observabilité

> Prometheus collecte les métriques plateforme et Data. Grafana expose les vues de santé. Le snapshot validé avait 21 targets UP ; pendant une démo je présente la valeur live.

## Sécurité

> La sécurité repose sur RBAC, service accounts, NetworkPolicy deny-by-default, politiques Kyverno, securityContext, root filesystem read-only sur les workloads durcis et scans Trivy. Les tests négatifs existent mais je ne les rejoue pas live.

## N3

> Ma méthode N3 sépare l'incident en couches : scheduling/ressources, réseau/DNS, identité/TLS/secrets, stockage, dépendances, puis logs/métriques. Cela permet de déterminer rapidement si le problème appartient à la plateforme ou au workload.

Pour Spark OOM : events, OOMKilled, requests/limits, mémoire node, driver/executor, parallélisme, shuffle, quotas.

Pour Kafka : Pod, Service/DNS, NetworkPolicy, TLS/ACL, broker, consumer group, lag, ressources, stockage.

## Conclusion

> Ce POC démontre architecture, plateforme, Data, GitOps, sécurité, observabilité et Day-2. Les limites sont explicites : workstation unique, pas de DR multi-site, Polaris non durable et pas de claim production HA.
