# Rapport de validation Kind — en cours

Les preuves se trouvent dans `evidence/kind-edl-lab/20260928T112119Z/`.
Le tableau `SUMMARY.md` de ce dossier fait foi pour les statuts de chaque itération.
Une configuration présente dans Git ne constitue pas une preuve d'exécution.

| Point demandé | Résultat et preuve |
| --- | --- |
| 1. État Git initial | `main` à `80c2014c939c783593e6f9a825640f4fb6257089`, antérieur aux corrections d'audit. La branche d'audit et sa PR #2 ont été conservées sans fusion. |
| 2. Source utilisée | Branche `runtime/kind-edl-lab`, issue de `ccbb114fb219a4d58d668be3717116670c4bc081` sur `codex/static-audit-lakehouse`. |
| 3. Fichiers | Profils Kind dédiés, scripts protégés par le contexte, applications GitOps, observabilité Kind, documentation et preuves. Deux corrections portables : appels `python3` dans le build lakehouse et comptage de zéro contrôleur ingress dans le test I1. |
| 4. Architecture | Événements synthétiques → Kafka → Spark → Iceberg/S3 → Polaris → Trino → Jupyter. Argo CD gère la baseline et les règles réseau ; les autres composants sont installés par les scripts Helm/Kustomize. |
| 5. Nœuds | Un control-plane et deux workers Kind, Kubernetes 1.33.1, Calico 3.30.3, même poste physique. Trois nœuds Ready vérifiés. |
| 6. Composants | Argo CD 3.5.3/chart 10.9.2 ; RustFS 1.0.0 ; Strimzi 1.2.0/Kafka 4.3.1 ; Spark 4.1.3/Iceberg 1.11.0 ; Polaris 1.7.0 ; Trino 480/chart 1.42.2 ; Jupyter scipy-notebook 2026-07-28/client Trino 0.340.0 ; Kyverno 1.19.1/chart 3.9.1. Observabilité en cours de validation. |
| 7. Namespaces | `edl-data`, `edl-platform`, `edl-observability`, `argocd`, `kyverno` et namespaces système Kind. Aucun déploiement sur CRC. |
| 8. Pods | Les contrôles intermédiaires ont vérifié les pods Running/Ready ou Succeeded. Inventaire final à collecter après les dernières étapes. |
| 9. Stockage | PVC locaux pour S3, Kafka, test de persistance, Jupyter, Grafana et Prometheus. Provisionnement local-path ; les données dépendent du stockage du nœud Kind et du poste. |
| 10. Kafka | Topic réel, publication puis consommation du même marqueur à son offset ; producteur synthétique existant exécuté. `11-kafka.txt`. Un broker/controller, réplication 1. |
| 11. Spark/Iceberg | Smoke Pi réussi ; traitement de cinq événements Kafka dans la table Iceberg via Polaris et S3. `spark-smoke.txt`, `spark-lakehouse.txt`. |
| 12. Polaris | Authentification, contrat de stockage du catalogue et droits validés, puis utilisation réelle par Spark et Trino. `13-polaris.txt`. Catalogue en mémoire, non durable. |
| 13. Trino | `SELECT 1`, 25 nations TPCH et lecture des cinq transactions réelles réussis. `14-trino.txt`. |
| 14. Jupyter | HTTP authentifié 200, cinq groupes de transactions lus via Trino et écriture du PVC réussis. `15-jupyter.txt`. |
| 15. Sécurité | Cinq refus contrôlés réussis, ressources des pods vérifiées, politiques Kyverno actives. Trivy exécuté sur le dépôt et trois images construites localement. Des vulnérabilités restent présentes : voir le rapport de sécurité. |
| 16. Observabilité | `RUNTIME_VALIDATED` : 21/21 cibles UP, quatre règles chargées/saines, quatre pods d'observabilité Ready, API Grafana authentifiée, source Prometheus saine et deux tableaux de bord disponibles. Preuve : `18-prometheus-targets.txt`. Séries de lag consommateur et capacité PVC absentes ; alertes dépendantes non validées fonctionnellement. |
| 17. Résilience | `NOT_TESTED` : scénarios de remplacement préparés. Aucune affirmation de HA multi-hôte. |
| 18. E2E | `NOT_TESTED` : la chaîne intermédiaire fonctionne ; le test avec un nouvel événement et sa lecture exacte dans Trino/Jupyter reste à exécuter. |
| 19. Ressources | Snapshots Docker après les composants dans `20-resource-usage.txt`. `kubectl top` indisponible car metrics-server n'est pas installé. Snapshot final à collecter. |
| 20. Anomalies | Vulnérabilités d'images ; systèmes de fichiers racine inscriptibles ; pertes temporaires de bail du control-plane pendant des périodes de lenteur API/etcd. Reprises observées et documentées, sans preuve d'une cause matérielle unique. |
| 21. Kind/OpenShift | Docker/Kind remplace les BuildConfig pour ce profil ; port-forward remplace les Routes ; PSS remplace les contraintes SCC ; Prometheus upstream remplace UWM. Les fichiers de profils OpenShift existants sont inchangés. Leur redéploiement fonctionnel sur CRC est `NOT_TESTED`. |
| 22. Preuves | Dossier daté, logs de tests, synthèse des scans sans extraits de secrets, identifiants d'images et procédure de reprise. Collecte finale et contrôles Git encore à terminer. |
| 23. I1–I12 | I1–I10 et Polaris : `RUNTIME_VALIDATED` dans le périmètre décrit. I11–I12 : `NOT_TESTED`. La bascule finale CRC ↔ Kind reste à exécuter. Le checkpoint I10 ne poursuit aucune de ces étapes. |

## Limites de sécurité

Les scans comptent 10 occurrences critiques sur Spark et 7 sur Jupyter, ainsi que
des occurrences élevées sur les trois images analysées. Les tests d'admission ne
corrigent pas ces dépendances. Le rapport détaillé est
`evidence/kind-edl-lab/20260928T112119Z/SECURITY_FINDINGS.md` ; les scans des autres
images upstream sont `NOT_TESTED`. Ce lab n'est pas une validation de sécurité de
production, de durabilité du catalogue ou de PRA.

## Commandes d'exploitation

Dans Git Bash, depuis la racine du dépôt :

```bash
# A. Arrêter le lab sans supprimer ses données
bash scripts/kind/stop-edl-lab.sh

# B. Redémarrer le lab et reconstruire son catalogue/table de démonstration
bash scripts/kind/start-edl-lab.sh

# C. Basculer de Kind vers CRC
bash scripts/kind/stop-edl-lab.sh
crc start
kubectl config use-context crc-admin

# D. Revenir de CRC vers Kind
crc stop
bash scripts/kind/start-edl-lab.sh

# E. Supprimer uniquement edl-lab, si tu le décides ultérieurement
CONFIRM_DELETE_EDL_LAB=yes bash scripts/kind/delete-edl-lab.sh
```

L'arrêt conserve les conteneurs, images et volumes. La suppression détruit le
stockage local du lab ; elle ne fait pas partie de cette validation. Le guide
`KIND_EDL_LAB.md` donne l'ordre de déploiement, les accès et le dépannage.
