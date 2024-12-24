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
        SCRIPT_DIR = "/root/scripts"
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
                                    ssh -i $SSH_KEY_PATH -o StrictHostKeyChecking=no ${VPS_A_USER}@${VPS_A_HOST} 'mkdir -p ${COMPOSE_DIR}'
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
                                    ssh -i $SSH_KEY_PATH -o StrictHostKeyChecking=no ${VPS_B_USER}@${VPS_B_HOST} 'mkdir -p ${SCRIPT_DIR}'
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
                                    scp -i $SSH_KEY_PATH -o StrictHostKeyChecking=no ${BACKUP_SCRIPT} ${VPS_A_USER}@${VPS_A_HOST}:${COMPOSE_DIR}
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
                                    scp -i $SSH_KEY_PATH -o StrictHostKeyChecking=no ${RESTORE_SCRIPT} ${VPS_B_USER}@${VPS_B_HOST}:${SCRIPT_DIR}
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
                            ssh -i $SSH_KEY_PATH -o StrictHostKeyChecking=no ${VPS_A_USER}@${VPS_A_HOST} 'bash ${COMPOSE_DIR}/${BACKUP_SCRIPT_NAME} ${VPS_B_USER} ${VPS_B_HOST} ${COMPOSE_DIR} ${BACKUP_DIR}'
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
                            ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${VPS_B_USER}@${VPS_B_HOST} 'bash ${SCRIPT_DIR}/${RESTORE_SCRIPT_NAME} ${BACKUP_DIR}'
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
                        git clone https://github.com/IbinMas/test-jenkins.git || echo "Repository already cloned."
                        cd test-jenkins

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
            echo "Ensuring Docker services are running..."
            script {
                parallel(
                    "Docker Service on VPS_A": {
                        withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH')]) {
                            sh """
                            ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${VPS_A_USER}@${VPS_A_HOST} <<'EOF'
                            sudo systemctl start docker || echo "Docker already running."
                            docker ps
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
