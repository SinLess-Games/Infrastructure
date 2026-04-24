# Building the Infrastructure

This guide provides step-by-step instructions for building the infrastructure using Ansible and Terraform. It assumes that you have already completed the initial setup and configuration of the infrastructure as outlined in the `01-Initialization-and-Setup.md` guide.

## Building the Infrastructure with Ansible

Ansible is used to automate the configuration and management of the infrastructure. The Ansible code for this infrastructure is located in the `Infrastructure/Ansible/` directory.

To build the infrastructure using Ansible, follow these steps:

### Step 1: Inspect the variable files

Before running the Ansible playbooks, it's important to review the variable files to ensure that they are configured correctly for your environment. The variable files are located in the `Infrastructure/Ansible/group_vars/` directory.

### Step 2: Run the Ansible playbooks

the play books will be run in a certain order based on dependencies.

#### 2a. Configure the Proxmox VE Hypervisors

After you have installed Proxmox VE on your servers, we use Ansible to configure the Proxmox VE hypervisors. This includes setting up the storage, networking, and other configurations required for the hypervisors to function properly.

```bash
task ansible:configure-proxmox
```

#### 2b. Configure the Technitium DNS Server

we use Technitium DNS server for our internal DNS needs. You can use Ansible to configure the Technitium DNS server. This includes setting up the DNS zones, records, and other configurations required for the DNS server to function properly.

```bash
task ansible:setup-technitium
``` 

#### 2c. Configure the The Vault server Cluster

we use Vault for secrets management. You can use Ansible to configure the Vault server cluster. This includes setting up the Vault servers, configuring the storage backend, and initializing the Vault cluster.

```bash
task ansible:deploy-vault
``` 

#### 2d. Configure the Postgres server Cluster

We use a external Postgres server cluster for our Kubernetes clusters. which allows us to tear down the clusters without losing data. You can use Ansible to configure the Postgres server cluster. This includes setting up the Postgres servers, configuring the storage backend, and initializing the Postgres cluster.

```bash
task ansible:deploy-postgres
```

### 2e. Configure the Wazuh server Cluster

We use Wazuh for security monitoring and log management. You can use Ansible to configure the Wazuh server cluster. This includes setting up the Wazuh servers, configuring the storage backend, and initializing the Wazuh cluster.

```bash
task ansible:deploy-wazuh
```

#### 2f. Configure the first of three Kubernetes Clusters

The first cluster we deploy is the Production cluster. This cluster will be used for running production workloads. It is important to deploy this cluster first so that we can use it to manage the other clusters.

```bash
task ansible:k8s:prod
```

#### 2g. Configure the second of three Kubernetes Clusters

The second cluster we deploy is the Staging cluster. This cluster will be used for testing and staging workloads. It is important to deploy this cluster after the Production cluster so that we can use the Production cluster to manage it.

```bash
task ansible:k8s:staging
```

#### 2h. Configure the third of three Kubernetes Clusters

The third cluster we deploy is the Development cluster. This cluster will be used for development workloads. It is important to deploy this cluster after the Staging cluster so that we can use the Staging cluster to manage it.

```bash
task ansible:k8s:dev
```

### Step 3: Verify the infrastructure

After running the Ansible playbooks, it's important to verify that the infrastructure has been built correctly. You can do this by checking the status of the various components and ensuring that they are running as expected. This includes checking the status of the Proxmox VE hypervisors, the Technitium DNS server, the Vault server cluster, and the Kubernetes clusters. You can also check the logs and metrics to ensure that everything is functioning properly.

## Conclusion

By following the steps outlined in this guide, you should have successfully built the infrastructure using Ansible. This infrastructure is now ready to be used for deploying applications and services. In the next guide, we will cover how to deploy applications and services on the Kubernetes clusters.
