const pptxgen = require('pptxgenjs');
const fs = require('fs');
const path = require('path');
const sizeOf = require('image-size').imageSize;

const ROOT = process.cwd();
const ASSETS = path.join(ROOT, 'demo', 'presentation', 'assets');
const OUT = path.join(ROOT, 'demo', 'presentation', 'dist');
fs.mkdirSync(OUT, {recursive:true});
const pptxPath = path.join(OUT, 'Enterprise_Data_Lakehouse_Runtime_Demo_Zidane_Djamal.pptx');

const A = {
  arch: path.join(ASSETS,'architecture.jpg'), seq: path.join(ASSETS,'sequence.jpg'),
  kafka: path.join(ASSETS,'kafka.jpg'), sparkJobs: path.join(ASSETS,'spark_jobs.jpg'),
  sparkExec: path.join(ASSETS,'spark_exec.jpg'), rustRoot: path.join(ASSETS,'rust_root.jpg'),
  rustMeta: path.join(ASSETS,'rust_meta.jpg'), rustData: path.join(ASSETS,'rust_data.jpg'),
  jupyterRows: path.join(ASSETS,'jupyter_rows.jpg'), jupyterFiles: path.join(ASSETS,'jupyter_files.jpg'),
  jupyterChart: path.join(ASSETS,'jupyter_chart.jpg'), polaris: path.join(ASSETS,'polaris.jpg'),
  grafana: path.join(ASSETS,'grafana.jpg'), prometheus: path.join(ASSETS,'prometheus.jpg'),
  argoApps: path.join(ASSETS,'argo_apps.jpg'), argoTree: path.join(ASSETS,'argo_tree.jpg')
};

for (const p of Object.values(A)) if (!fs.existsSync(p)) throw new Error(`Missing asset: ${p}`);

const pptx = new pptxgen();
pptx.layout = 'LAYOUT_WIDE';
pptx.author = 'Zidane Djamal';
pptx.subject = 'Enterprise Data Lakehouse Runtime Demonstration';
pptx.title = 'Enterprise Data Lakehouse - Runtime Demo';
pptx.company = 'Personal Engineering Lab';
pptx.lang = 'fr-FR';
pptx.theme = {headFontFace:'Aptos Display', bodyFontFace:'Aptos', lang:'fr-FR'};

pptx.defineSlideMaster({
  title:'MASTER', background:{color:'F7FAFC'},
  objects:[
    {rect:{x:0,y:0,w:13.333,h:0.08,fill:{color:'0B5CAD'},line:{color:'0B5CAD'}}},
    {text:{text:'Enterprise Data Lakehouse - Runtime Demo',options:{x:0.42,y:7.12,w:5.5,h:0.2,fontFace:'Aptos',fontSize:8.5,color:'667085',margin:0}}},
    {text:{text:'Zidane Djamal - Architecte Solutions / Technique & Transverse',options:{x:7.05,y:7.12,w:5.85,h:0.2,fontFace:'Aptos',fontSize:8.5,color:'667085',align:'right',margin:0}}}
  ],
  slideNumber:{x:12.94,y:7.12,color:'667085',fontFace:'Aptos',fontSize:8.5}
});

const C={navy:'123B69',blue:'0B5CAD',teal:'0F766E',green:'2E7D32',paleBlue:'EAF3FB',paleGreen:'EAF7F0',paleCyan:'E8F7F8',paleAmber:'FFF7E0',ink:'172B4D',text:'344054',muted:'667085',white:'FFFFFF',amber:'B54708'};
function addTitle(s,t,sub=''){s.addText(t,{x:0.5,y:0.34,w:12.3,h:0.48,fontFace:'Aptos Display',fontSize:25,bold:true,color:C.navy,margin:0});if(sub)s.addText(sub,{x:0.5,y:0.84,w:12.2,h:0.34,fontFace:'Aptos',fontSize:11.8,color:C.muted,margin:0});}
function card(s,x,y,w,h,o={}){s.addShape(pptx.ShapeType.roundRect,{x,y,w,h,rectRadius:0.08,fill:{color:o.fill||C.white},line:{color:o.line||'DCE4EC',width:o.width||1},shadow:o.shadow===false?undefined:{type:'outer',color:'000000',opacity:0.10,blur:1.5,angle:45,distance:1}});}
function imgFit(s,p,x,y,w,h,b=true){const d=sizeOf(fs.readFileSync(p)),r=d.width/d.height,br=w/h;let iw=w,ih=h,ix=x,iy=y;if(r>br){ih=w/r;iy=y+(h-ih)/2}else{iw=h*r;ix=x+(w-iw)/2}if(b)card(s,x,y,w,h,{fill:'FFFFFF',line:'D5DEE8',shadow:false});s.addImage({path:p,x:ix,y:iy,w:iw,h:ih});}
function pill(s,text,x,y,w,fill=C.paleBlue,color=C.blue){s.addShape(pptx.ShapeType.roundRect,{x,y,w,h:0.34,rectRadius:0.08,fill:{color:fill},line:{color:fill}});s.addText(text,{x:x+0.1,y:y+0.07,w:w-0.2,h:0.18,fontSize:9.5,bold:true,color,align:'center',margin:0});}
function callout(s,n,title,body,x,y,w,h,color=C.blue,fill=C.paleBlue){card(s,x,y,w,h,{fill,line:color,width:1.2,shadow:false});s.addShape(pptx.ShapeType.ellipse,{x:x+0.12,y:y+0.13,w:0.36,h:0.36,fill:{color},line:{color}});s.addText(String(n),{x:x+0.12,y:y+0.19,w:0.36,h:0.16,fontSize:9,bold:true,color:C.white,align:'center',margin:0});s.addText(title,{x:x+0.58,y:y+0.12,w:w-0.7,h:0.25,fontSize:11.2,bold:true,color:C.ink,margin:0});s.addText(body,{x:x+0.58,y:y+0.42,w:w-0.72,h:h-0.48,fontSize:9.5,color:C.text,margin:0.01});}
function metric(s,val,label,x,y,w,color=C.blue){card(s,x,y,w,0.92,{fill:'FFFFFF',line:'DCE4EC',shadow:false});s.addText(val,{x:x+0.08,y:y+0.12,w:w-0.16,h:0.34,fontSize:22,bold:true,color,align:'center',margin:0});s.addText(label,{x:x+0.06,y:y+0.54,w:w-0.12,h:0.2,fontSize:8.8,color:C.muted,align:'center',margin:0});}
function codeBox(s,txt,x,y,w,h,title=''){card(s,x,y,w,h,{fill:'0B1220',line:'16233A',shadow:false});if(title)s.addText(title,{x:x+0.18,y:y+0.13,w:w-0.36,h:0.22,fontSize:10.2,bold:true,color:'A7F3D0',margin:0});s.addText(txt,{x:x+0.18,y:y+(title?0.45:0.18),w:w-0.36,h:h-(title?0.58:0.3),fontFace:'Consolas',fontSize:8.8,color:'E5EEF8',margin:0.01});}

{
 const s=pptx.addSlide();s.background={color:'F7FAFC'};s.addShape(pptx.ShapeType.rect,{x:0,y:0,w:13.333,h:0.12,fill:{color:C.blue},line:{color:C.blue}});
 s.addText('Enterprise Data Lakehouse\nRuntime Demonstration',{x:0.65,y:0.66,w:6.3,h:1.45,fontFace:'Aptos Display',fontSize:30,bold:true,color:C.navy,margin:0});
 s.addText('Kubernetes / OpenShift target - Data Platform - GitOps - Observability',{x:0.66,y:2.15,w:6.15,h:0.42,fontSize:14,color:C.teal,margin:0});
 s.addText('Démonstration construite à partir de preuves runtime réelles du lab local Kind.',{x:0.66,y:2.68,w:5.95,h:0.56,fontSize:12.5,color:C.text,margin:0});
 pill(s,'3 nœuds Ready',0.66,3.5,1.65);pill(s,'45 pods healthy/completed',2.42,3.5,2.2,C.paleGreen,C.green);pill(s,'7 PVC Bound',4.73,3.5,1.45,C.paleCyan,C.teal);pill(s,'2 Apps Argo Healthy / Synced',0.66,3.98,2.6,'F1ECFF','6941C6');pill(s,'6 transactions I12',3.38,3.98,1.9,C.paleAmber,C.amber);
 s.addText('Zidane Djamal',{x:0.66,y:5.55,w:3,h:0.4,fontSize:20,bold:true,color:C.ink,margin:0});s.addText('Architecte Solutions / Technique & Transverse',{x:0.66,y:5.98,w:4.7,h:0.32,fontSize:12.2,color:C.text,margin:0});s.addText('Kubernetes • OpenShift • Data Platform • GitOps • Cloud Native',{x:0.66,y:6.38,w:5.9,h:0.3,fontSize:10.2,color:C.muted,margin:0});
 card(s,7.15,0.55,5.55,6.1,{fill:'FFFFFF',line:'D7E3EE'});imgFit(s,A.arch,7.31,0.72,5.25,5.78,false);s.addText('Personal engineering lab - aucune donnée client confidentielle',{x:7.35,y:6.55,w:5.1,h:0.28,fontSize:9.3,color:C.muted,align:'center',margin:0});
}
{
 const s=pptx.addSlide('MASTER');addTitle(s,'1. Architecture globale démontrée','Du GitOps au Data Product, avec séparation claire stockage / table / catalogue / SQL.');imgFit(s,A.arch,0.48,1.28,12.37,5.62,true);
}
{
 const s=pptx.addSlide('MASTER');addTitle(s,'2. Streaming & processing : Kafka / Strimzi -> Spark','La chaîne d’ingestion est visible dans Redpanda Console, puis dans Spark History Server.');
 card(s,0.48,1.28,6.08,4.6);imgFit(s,A.kafka,0.62,1.5,5.8,3,false);s.addText('Kafka / Strimzi',{x:0.72,y:4.65,w:2,h:0.3,fontSize:15,bold:true,color:C.blue,margin:0});s.addText('4 topics • 57 partitions • topics métier : edl.smoke, transactions.raw, transactions.curated.\nRF=1 : lab local mono-broker, pas de claim HA.',{x:0.72,y:5.02,w:5.55,h:0.62,fontSize:10.2,color:C.text,margin:0.01});
 card(s,6.78,1.28,6.07,4.6);imgFit(s,A.sparkJobs,6.92,1.48,5.78,2.4,false);imgFit(s,A.sparkExec,6.92,4,5.78,1.45,false);s.addText('Spark History Server',{x:7.02,y:5.56,w:2.5,h:0.3,fontSize:15,bold:true,color:C.teal,margin:0});s.addText('Job PythonPi terminé • 1 stage • 10/10 tasks • driver + executor visibles.',{x:7.02,y:5.91,w:5.4,h:0.45,fontSize:10.2,color:C.text,margin:0.01});
 callout(s,1,'Kafka transporte','Le bus transporte les événements ; il n’est pas le stockage Lakehouse.',0.7,6.08,3.9,0.78,C.blue,C.paleBlue);callout(s,2,'Spark transforme','Le driver orchestre les stages/tasks et les executors réalisent le calcul.',4.75,6.08,4.05,0.78,C.teal,C.paleCyan);callout(s,3,'Preuve runtime','Redpanda Console et Spark History Server sont tous deux accessibles.',8.96,6.08,3.68,0.78,C.green,C.paleGreen);
}
{
 const s=pptx.addSlide('MASTER');addTitle(s,'3. Lakehouse physique : RustFS / S3 + Iceberg','Les fichiers sont physiques dans S3 ; Iceberg leur apporte la sémantique de table, snapshots et historique.');
 card(s,0.48,1.25,4,2.15);imgFit(s,A.rustRoot,0.62,1.4,3.72,1.85,false);card(s,0.48,3.56,4,2.25);imgFit(s,A.rustData,0.62,3.7,3.72,1.93,false);card(s,4.65,1.25,4,4.56);imgFit(s,A.rustMeta,4.8,1.42,3.7,4.2,false);
 callout(s,1,'RustFS / S3','Bucket edl-lab : raw, curated, evidence, checkpoints, contract-tests.',8.88,1.3,3.95,1.05,C.blue,C.paleBlue);callout(s,2,'Parquet = données','data/*.parquet contient les lignes physiques : 5 lignes dans un fichier, 1 ligne dans un second.',8.88,2.54,3.95,1.12,C.green,C.paleGreen);callout(s,3,'Iceberg = table versionnée','metadata/*.json + manifests/snapshots décrivent quels fichiers composent la table.',8.88,3.86,3.95,1.2,C.teal,C.paleCyan);codeBox(s,'s3://edl-lab/curated/analytics/transactions/\n  data/*.parquet\n  metadata/*.metadata.json',8.88,5.3,3.95,1.15,'Structure physique');
}
{
 const s=pptx.addSlide('MASTER');addTitle(s,'4. Iceberg devient lisible dans Jupyter','Le notebook relie la table logique, les snapshots et les fichiers physiques.');
 card(s,0.48,1.25,6.28,2.9);imgFit(s,A.jupyterRows,0.65,1.48,5.94,2.46,false);card(s,6.95,1.25,5.9,2.9);imgFit(s,A.jupyterFiles,7.12,1.47,5.56,2.46,false);card(s,0.48,4.35,6.1,2.15);imgFit(s,A.jupyterChart,0.72,4.52,5.62,1.8,false);metric(s,'6','transactions lues',6.92,4.52,1.75,C.blue);metric(s,'2','fichiers Parquet',8.84,4.52,1.75,C.green);metric(s,'1','table Iceberg',10.76,4.52,1.75,C.teal);s.addText('Lecture logique : polaris.analytics.transactions',{x:7,y:5.72,w:5.25,h:0.28,fontSize:11.5,bold:true,color:C.ink,margin:0});s.addText('Le notebook montre les 6 lignes métier, les metadata tables Iceberg et la relation vers les fichiers Parquet.',{x:7,y:6.05,w:5.2,h:0.52,fontSize:10.2,color:C.text,margin:0.01});
}
{
 const s=pptx.addSlide('MASTER');addTitle(s,'5. Catalogue & SQL : Polaris -> Trino','Polaris référence la table Iceberg ; Trino exécute le SELECT et retourne les données.');
 card(s,0.48,1.25,6.55,5.5);imgFit(s,A.polaris,0.65,1.45,6.2,4,false);s.addText('Polaris Console',{x:0.72,y:5.62,w:2,h:0.28,fontSize:15,bold:true,color:C.blue,margin:0});s.addText('quickstart_catalog → analytics → transactions\nUUID : 8894029f-a135-4248-9464-8af1cd2f8966\nMetadata : .../metadata/00002-....metadata.json',{x:0.72,y:5.98,w:5.95,h:0.62,fontSize:9.7,color:C.text,margin:0.01});
 codeBox(s,'SELECT eventId, transactionId, amount, status\nFROM polaris.analytics.transactions\nORDER BY eventId;\n\nE2E-I12...  17.42   ACCEPTED\nevt-0001     125.4    ACCEPTED\nevt-0002      90.0    ACCEPTED\nevt-0003     250.1    REJECTED\nevt-0004      19.99   ACCEPTED\nevt-0005     800.0    PENDING',7.25,1.25,5.6,4.25,'Trino CLI - lecture réussie');callout(s,1,'Polaris catalogue','Il connaît le catalog, le namespace, la table, le schéma et la metadata-location Iceberg.',7.25,5.72,2.62,0.95,C.blue,C.paleBlue);callout(s,2,'Trino exécute','Le moteur SQL résout la table via Polaris puis lit les fichiers déclarés par Iceberg.',10.03,5.72,2.82,0.95,C.green,C.paleGreen);
}
{
 const s=pptx.addSlide('MASTER');addTitle(s,'6. Diagramme de séquence E2E','Écriture puis lecture : le stockage physique, le format de table, le catalogue et le moteur SQL restent séparés.');imgFit(s,A.seq,0.48,1.27,12.37,5.62,true);
}
{
 const s=pptx.addSlide('MASTER');addTitle(s,'7. Observabilité : Prometheus -> Grafana','Prometheus stocke les séries ; Grafana donne la vue synthétique de la plateforme.');
 card(s,0.48,1.28,6.15,3.25);imgFit(s,A.grafana,0.65,1.47,5.82,2.9,false);card(s,6.8,1.28,6.05,3.25);imgFit(s,A.prometheus,6.98,1.47,5.7,2.9,false);callout(s,1,'Kafka lag : “No data”','Absence de série de consumer group au moment de la capture ; ce n’est pas un lag mesuré à zéro.',0.72,4.8,3.8,1.12,C.amber,C.paleAmber);callout(s,2,'Under replicated = 0','La métrique Kafka est bien présente. RF=1 reste un choix de lab local, pas une preuve HA.',4.72,4.8,3.8,1.12,C.green,C.paleGreen);callout(s,3,'Trino & restarts','Les requêtes très courtes sont difficiles à échantillonner ; les redémarrages restent quasi nuls.',8.72,4.8,3.8,1.12,C.blue,C.paleBlue);
 s.addText('Applications / Kubernetes  →  Prometheus  →  PromQL  →  Grafana',{x:1.3,y:6.2,w:10.7,h:0.36,fontSize:13,bold:true,color:C.navy,align:'center',margin:0});
}
{
 const s=pptx.addSlide('MASTER');addTitle(s,'8. GitOps, gouvernance & sécurité','Argo CD maintient le cluster conforme à Git ; le baseline applique les garde-fous Kubernetes.');
 card(s,0.48,1.28,5.75,3.15);imgFit(s,A.argoApps,0.65,1.5,5.42,2.7,false);card(s,6.45,1.28,6.4,3.15);imgFit(s,A.argoTree,6.62,1.5,6.05,2.7,false);metric(s,'2','apps Argo CD',0.65,4.72,1.6,'6941C6');metric(s,'Healthy','état applicatif',2.45,4.72,1.65,C.green);metric(s,'Synced','Git = cluster',4.3,4.72,1.65,C.blue);callout(s,1,'RBAC','ServiceAccounts et rôles limitent les droits des workloads.',6.5,4.72,1.92,1.17,C.blue,C.paleBlue);callout(s,2,'NetworkPolicy','Deny-by-default puis flux explicitement autorisés.',8.52,4.72,2,1.17,C.teal,C.paleCyan);callout(s,3,'Kyverno','Admission et conformité du cluster dans le lab.',10.64,4.72,1.95,1.17,C.green,C.paleGreen);codeBox(s,'GitHub\n  ↓ desired state\nArgo CD\n  ↓ reconciliation\nKubernetes Kind',0.65,6.05,4.45,0.75,'Boucle GitOps');s.addText('Argo CD ne traite aucune transaction : il garantit l’état désiré du socle.',{x:5.35,y:6.08,w:7.1,h:0.52,fontSize:10.4,color:C.text,margin:0.01});
}
{
 const s=pptx.addSlide('MASTER');addTitle(s,'9. Preuve runtime, limites et positionnement','Une démonstration d’architecture exploitable en entretien, sans sur-vendre la portée du lab.');
 metric(s,'3','nœuds Ready',0.7,1.5,2.15,C.blue);metric(s,'45','pods healthy / completed',3.03,1.5,2.15,C.green);metric(s,'7','PVC Bound',5.36,1.5,2.15,C.teal);metric(s,'2','Apps Argo Healthy/Synced',7.69,1.5,2.15,'6941C6');metric(s,'6','transactions I12',10.02,1.5,2.15,C.amber);
 card(s,0.7,2.72,7.45,2.4);s.addText('Ce que la démo prouve',{x:0.95,y:2.97,w:2.5,h:0.3,fontSize:17,bold:true,color:C.navy,margin:0});s.addText('• Flux E2E Kafka → Spark → Iceberg/RustFS → Polaris → Trino → Jupyter\n• Interfaces runtime réellement accessibles : Redpanda Console, Spark History, RustFS, Polaris, Grafana, Prometheus, Argo CD\n• GitOps, RBAC, NetworkPolicy et Policy-as-Code visibles dans le cluster\n• Données I12 relues par Trino et Jupyter depuis la même table Iceberg',{x:0.98,y:3.42,w:6.85,h:1.35,fontSize:11.1,color:C.text,margin:0.02});
 card(s,8.42,2.72,4.2,2.4,{fill:C.paleAmber,line:'FEC84B',shadow:false});s.addText('Limites assumées',{x:8.68,y:2.97,w:2.1,h:0.3,fontSize:17,bold:true,color:C.amber,margin:0});s.addText('• Lab local sur une workstation\n• RF=1 côté Kafka\n• Polaris in-memory / non durable\n• Pas de claim HA multi-hôte / DR\n• Pas de production readiness',{x:8.68,y:3.43,w:3.55,h:1.25,fontSize:11.1,color:C.text,margin:0.02});s.addShape(pptx.ShapeType.line,{x:0.7,y:5.45,w:11.9,h:0,line:{color:'D0D5DD',width:1}});s.addText('Zidane Djamal',{x:0.75,y:5.72,w:3,h:0.35,fontSize:22,bold:true,color:C.navy,margin:0});s.addText('Architecte Solutions / Technique & Transverse',{x:0.75,y:6.12,w:4.4,h:0.3,fontSize:12.2,color:C.text,margin:0});s.addText('Kubernetes • OpenShift • Data Platform • GitOps • Cloud Native',{x:0.75,y:6.48,w:5.5,h:0.26,fontSize:10.2,color:C.muted,margin:0});s.addText('github.com/zdmooc/enterprise-data-lakehouse-kubernetes-openshift',{x:6.25,y:5.96,w:6,h:0.35,fontFace:'Consolas',fontSize:10.3,color:C.blue,align:'right',margin:0});pill(s,'Personal Engineering Lab',9.23,6.42,2.95,C.paleBlue,C.blue);
}

pptx.writeFile({fileName:pptxPath});
console.log(pptxPath);
