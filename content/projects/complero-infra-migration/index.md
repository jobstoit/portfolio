---
title: "Complero Infrastructure Migration"
date: 2024-05-09T10:41:40+02:00
draft: false
hero: gitops-toolkit.webp
menu:
  sidebar:
    name: "Complero Infra Migration"
---

[Complero](https://complero.com) used to have it's infrastructure hosted on [Netcup](https://www.netcup.eu) VPS's.
Complero had a setup with 3 nodes that hosted a docker swarm and 2 additional Nodes that hosted the Postgres Instances.

For our migration we first needed to find a proper cloud host that was strictly GDPR compliant and that was a European Company and hosted servers in Germany.
After several different considerations we found that [OVH](https://www.ovhcloud.com) was the best offering for Complero.

After finding our new vendor we made sure we have the proper measures in place to preform the migration such as backups and the ability to switch the DNS records back at moments notice.

## Kubernetes

We switched over to a Managed Kubernetes by OVH.
I setup a private network that this cluster would opperate in.
I setup the following opperators:
- [FluxCD](https://fluxcd.io) for a GitOps workflow
- [NGINX Ingress controller](https://github.com/kubernetes/ingress-nginx) for handling ingress
- [Cert-Manager](https://cert-manager.io) for Handling SSL certificates
- [External-DNS](https://github.com/kubernetes-sigs/external-dns) to autotomatically create DNS records when Ingress definitions are detected
- [Hashicorp Vault](https://www.vaultproject.io) for secret management and the Vault Secret Injector to inject vault secrets into Kubernetes
- [Hasicorp Boundary](https://www.boundaryproject.io) for access management, for both access to the cluster and access to the database and any internal app with IAM.
- [Velero](https://velero.io) for backup managment

Other than that I set up all the internal tools we previously had on the old infrastructure.
I created the helm charts for our application. 
And setup [Flux Image automation](https://fluxcd.io/flux/guides/image-update/) policies so flux would automatically detect when there is a new version of the app and deploy it to the cluster.


## Postgres

We switched our Postgres nodes over to OVH's managed Postgres.
We added the Postgres instance to the Private network that the Kubernetes cluster was also running in.
Luckily OVH works has [Aiven](https://aiven.io) under the hood and supports [Logical Replication](https://www.postgresql.org/docs/current/logical-replication.html) (See [Aiven's logical replication docs](https://aiven.io/docs/products/postgresql/howto/setup-logical-replication)).
This meant that we could replicate our running database and anything that would be applied to the old database would now be applied to the new one as it was being written.
We first did the test with our DEV database and made sure that our application was running and if there were any changes in the old dev database that it would show up in this new one. 
This meant that at the day of the migration we could simply start the app on the new infrastrucutre which pointed to this new database and then simply switch the DNS record to point to the new app which had all the same data while it being on a totally new database.
This meant that we had close to no downtime.

## Object Storage Migraion

For our object storage we used the Minio Client to replicate all the data.
We simply created a deployment definition with the minio client running the `mc mirror --watch` command.
We did restart this a couple times just to make sure it had really copied all of the objects we really had and we compared the sizes of the buckets to make sure everything was moved over.

## The migration

Having replicated everything on the simply switched over the DNS record to point to the new infrastructure and everything worked with minimal downtime.
