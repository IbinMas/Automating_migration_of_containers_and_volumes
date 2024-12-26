
// This pipeline asumes:
// 1. all docker volumes are named volume type
// 2. Add the private key for `proxmox_server` under Jenkins credentials.
// 3. server_A can perform rsync with server_B
// 4. you Ensure jq is Installed on server_A

pipeline {
    agent any

    environment {
        VPS_A_USER = "root"
        VPS_A_HOST = "10.1.1.221"
        VPS_B_USER = "root"
        VPS_B_HOST = "10.1.1.100"
        COMPOSE_DIR = "/root/test-jenkins"
        BACKUP_DIR = "/tmp/docker_volume_backups"
        SSH_KEY_PATH = credentials('proxmox_server')
        BACKUP_SCRIPT = "./scripts/migrate_containers_volumes.sh"
        RESTORE_SCRIPT = "./scripts/restore_volumes.sh"
        BACKUP_SCRIPT_NAME = "migrate_containers_volumes.sh"
        RESTORE_SCRIPT_NAME = "restore_volumes.sh"
        VOLUMES_LIST = "jenkins_home rocketchat_mongodb_data compose_files_web1_data compose_files_web2_data"
        // SCRIPT_DIR = "/root/scripts"

    }
    
    stages {
        stage('Prepare Servers') {
            parallel {
                stage('Prepare VPS_A') {
                    steps {
                        script {
                            echo "Ensuring directories exist on VPS_A..."
                            withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH')]) {
                                sh """
                                    ssh -i $SSH_KEY_PATH -o StrictHostKeyChecking=no ${VPS_A_USER}@${VPS_A_HOST} 'mkdir -p ${BACKUP_DIR}'
                                """
                            }
                        }
                    }
                }

                stage('Prepare VPS_B') {
                    steps {
                        script {
                            echo "Ensuring directories exist on VPS_B..."
                            withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH')]) {
                                sh """
                                    ssh -i $SSH_KEY_PATH -o StrictHostKeyChecking=no ${VPS_B_USER}@${VPS_B_HOST} 'mkdir -p ${BACKUP_DIR}'
                                    ssh -i $SSH_KEY_PATH -o StrictHostKeyChecking=no ${VPS_B_USER}@${VPS_B_HOST} 'mkdir -p ${COMPOSE_DIR}'

                                """
                            }
                        }
                    }
                }
            }
        }

        stage('Copy Scripts') {
            parallel {
                stage('Copy Backup Script to VPS_A') {
                    steps {
                        script {
                            echo "Copying backup script to VPS_A..."
                            sh "chmod +x ${BACKUP_SCRIPT}"
                            withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH')]) {
                                sh """
                                    scp -i $SSH_KEY_PATH -o StrictHostKeyChecking=no ${BACKUP_SCRIPT} ${VPS_A_USER}@${VPS_A_HOST}:${BACKUP_DIR}
                                """
                            }
                        }
                    }
                }

                stage('Copy Restore Script to VPS_B') {
                    steps {
                        script {
                            echo "Copying restore script to VPS_B..."
                            sh "chmod +x ${RESTORE_SCRIPT}"
                            withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH')]) {
                                sh """
                                    scp -i $SSH_KEY_PATH -o StrictHostKeyChecking=no ${RESTORE_SCRIPT} ${VPS_B_USER}@${VPS_B_HOST}:${BACKUP_DIR}
                                """
                            }
                        }
                    }
                }
            }
        }

        stage('Execute Backup on VPS_A') {
            steps {
                script {
                    echo "Running backup script on VPS_A..."
                    withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH')]) {
                        sh """
                            ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${VPS_A_USER}@${VPS_A_HOST} 'bash ${BACKUP_DIR}/${BACKUP_SCRIPT_NAME} ${VPS_B_USER} ${VPS_B_HOST} ${COMPOSE_DIR} ${BACKUP_DIR} ${VOLUMES_LIST}'
                        """
                    }
                }
            }
        }

        stage('Execute Restore on VPS_B') {
            steps {
                script {
                    echo "Running restore script on VPS_B..."
                    withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH')]) {
                        sh """
                            ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${VPS_B_USER}@${VPS_B_HOST} 'bash ${BACKUP_DIR}/${RESTORE_SCRIPT_NAME} ${BACKUP_DIR}'
                        """
                    }
                }
            }
        }

        stage('Deploy Docker Compose Projects on VPS_B') {
            steps {
                script {
                    echo "Cloning and deploying Docker Compose projects..."
                    withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH')]) {
                        sh """
                        ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${VPS_B_USER}@${VPS_B_HOST} <<EOF
                        set -e
                        echo "Cloning repository..."
                        # git clone https://github.com/IbinMas/test-jenkins.git || echo "Repository already cloned."
                        cd ${COMPOSE_DIR}

                        echo "Deploying all projects with docker-compose.yaml..."
                        find . -name "docker-compose.yaml" -execdir bash -c '
                            echo "Deploying project in directory: \$(pwd)"
                            docker compose up -d
                        ' \\;

                        echo "Listing running containers..."
                        docker ps
                        exit
                        EOF
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            echo "Clean Up and Ensuring Docker services are running..."
            script {
                parallel(
                    "Docker Service on VPS_A": {
                        withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH')]) {
                            sh """
                            ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${VPS_A_USER}@${VPS_A_HOST} <<'EOF'
                            sudo systemctl start docker || echo "Docker already running."
                            docker ps
                            rm -rf ${BACKUP_DIR}
                            exit
                            EOF
                            """
                        }
                    },
                    "Docker Service on VPS_B": {
                        withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH')]) {
                            sh """
                            ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${VPS_B_USER}@${VPS_B_HOST} <<'EOF'
                            sudo systemctl start docker || echo "Docker already running."
                            docker volume ls
                            docker ps
                            rm -rf ${BACKUP_DIR}
                            exit
                            EOF
                            """
                        }
                    }
                )
            }
        }
    }
}
