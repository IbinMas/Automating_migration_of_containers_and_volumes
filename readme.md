# **Runbook for Automating the Migration of Containers and Volumes**

## **Repository Name**: Automating_migration_of_containers_and_volumes

This runbook provides a step-by-step guide for automating the migration of Docker containers and their associated volumes from one VPS (VPS_A) to another (VPS_B) using Jenkins pipelines.

---

## **Purpose**
To migrate containers and their volumes from VPS_A to VPS_B with minimal downtime and ensure that all data is transferred correctly. This includes the following:
- Copying Docker Compose files.
- Backing up and restoring Docker volumes.
- Deploying the containers on the new host.
- Automating the entire process via Jenkins.

---

## **Pipeline Overview**

### **Jenkinsfile**

The pipeline consists of the following stages:

1. **Copy Scripts**: Migrates the necessary backup and restore scripts to VPS_A and VPS_B, respectively.
2. **Execute Migrate Script in VPS_A**: Runs the migration script to back up volumes and transfer Docker Compose files from VPS_A to VPS_B.
3. **Execute Restore Script in VPS_B**: Restores the volumes and prepares the containers for deployment.
4. **Clone Docker Compose Repos and Deploy Containers**: Clones the Docker Compose files and starts the containers on VPS_B.

---

## **Execution Steps**

1. **Clone the repository on your Jenkins server**:
   ```bash
   git clone https://your-repository-url.git
   ```

2. **Configure Jenkins Credentials**:
   - Add the private key for `proxmox_server` under Jenkins credentials.

3. **Set Up the Jenkins Pipeline**:
   - Use the provided `Jenkinsfile` in the repository to create a pipeline job.

4. **Run the pipeline**:
   - Trigger the pipeline to migrate containers and volumes.

5. **Validate**:
   - Ensure containers and volumes are running on VPS_B using the following commands:
     ```bash
     docker ps
     docker volume ls
     ```

6. **Cleanup**:
   - Ensure temporary directories like `/tmp/docker_volume_backups` are cleaned up post-validation.

---

## **Validation Checklist**

- [ ] Ensure all Docker Compose files are transferred to VPS_B.
- [ ] Validate that all volumes are restored with correct labels.
- [ ] Check if all containers are up and running on VPS_B.
- [ ] Verify data integrity in restored volumes.

---

## **Key Notes**

- **Backup and Restore Scripts**:
  - The repository includes scripts (`migrate_containers_2.sh` and `restore_volumes.sh`) for automating the backup and restoration of Docker volumes.

- **Environment Variables**:
  - Ensure the environment variables in the `Jenkinsfile` are correctly configured to match your infrastructure.

- **Docker Service Validation**:
  - The pipeline includes steps to validate that the Docker service is running on both VPS_A and VPS_B.

- **Temporary Directories**:
  - The `/tmp/docker_volume_backups` directory is used for storing backups temporarily. Ensure this is cleaned up after migration.

---

## **Troubleshooting**

1. **Volume Label Issues**:
   - If volumes are not restored with the correct labels, verify the `COMPOSE_PROJECT_NAME` in the restore script matches the project name in your Docker Compose setup.

2. **Permission Errors**:
   - Ensure the SSH key has the necessary permissions and is correctly configured in Jenkins credentials.

3. **Docker Compose Version Warnings**:
   - If you encounter warnings about the `version` attribute being obsolete, consider removing the `version` field from your Docker Compose files to avoid confusion.

4. **Data Integrity Issues**:
   - Verify the integrity of restored data by inspecting the contents of the volumes after restoration.

