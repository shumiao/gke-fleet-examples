# gke-fleet-examples

This project contains easy-to-follow examples for managing multiple Google Kubernetes Engine (GKE) clusters via [GKE fleets](https://cloud.google.com/kubernetes-engine/docs/fleets-overview).

Contents

1. fleet-and-teams-setup: Contains a Terraform configuration for provisioning a fleet encompassing three clusters and two teams. This serves as a straightforward Terraform implementation of [fleet team management](https://cloud.google.com/anthos/fleet-management/docs/team-management).

2. config-management/configs: A repository demonstrating the use of [Anthos Config Management](https://cloud.google.com/anthos-config-management/docs/tutorials/config-sync-multi-repo) to sync configurations to team namespaces in clusters across the fleet established in the "fleet-and-teams-setup" directory.

3. fleet-and-argocd: Contains an example using Argo CD to deploy applications to Fleet team namespaces.

   - The fleet has three application clusters on GKE, one app operator team `frontend` with a `webserver` namespace.

      ![fleet](https://github.com/shumiao/gke-fleet-examples/assets/6844327/332662c2-3788-47e7-a645-ed18011b990a)

   - Platform admin intalls an [`argocd-fleet-syncer`](fleet-and-argocd/argocd-fleet-syncer-install.yaml) in the Argo CD central cluster. This tool will poll your fleet clusters and teams' tenancy topoloy, and creates Argo CD cluster secrets labeled with the teams.
   
   - Platform admins deploys a [`webserver-applicationset`](fleet-and-argocd/webserver-applicationset.yaml) in the Argo CD central cluster. The ApplicationSet specifies a Git repo path as the source of the CD pipeline, and Fleet team 
  `frontend`'s `webserver` namespace as the destination. Then the CD pipeline is ready!
     
   - The `frontend` app operator team can now create deployments and configurations in the source Git repo path. They will be automatically synced into the `webserver` Fleet namespace.
