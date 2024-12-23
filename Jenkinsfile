pipeline {
    agent any

    environment {
        VPS_A_USER = "root"
        VPS_A_HOST = "10.1.1.221"
        VPS_B_USER = "root"
        VPS_B_HOST = "10.1.1.100"
        // COMPOSE_DIR = "/root/Prod-Compose"
        COMPOSE_DIR = "/root/test-jenkins"
        BACKUP_DIR = "/tmp/docker_volume_backups"
        SSH_KEY_CREDENTIALS = credentials('proxmox_server')
        BACKUP_SCRIPT = "./scripts/migrate_containers_volumes.sh"
        RESTORE_SCRIPT = "./scripts/restore_volumes.sh"
        BACKUP_SCRIPT_NAME = "migrate_containers_volumes.sh"
        RESTORE_SCRIPT_NAME = "restore_volumes.sh"
    }

    stages {
        stage('Copy Scripts') {
            parallel {
                stage('Copy the migrate script to VPS_A') {
                    steps {
                        script {
                            echo "Copying the migrate script to VPS_A..."
                            withCredentials([sshUserPrivateKey(credentialsId: env.SSH_KEY_CREDENTIALS, keyFileVariable: 'SSH_KEY_PATH')]) {
                                sh """
                                    chmod +x ${env.BACKUP_SCRIPT}
                                    scp -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${env.BACKUP_SCRIPT} ${env.VPS_A_USER}@${env.VPS_A_HOST}:${env.COMPOSE_DIR}
                                """
                            }
                        }
                    }
                }

                stage('Copy the restore script to VPS_B') {
                    steps {
                        script {
                            echo "Copying the restore script to VPS_B..."
                            withCredentials([sshUserPrivateKey(credentialsId: env.SSH_KEY_CREDENTIALS, keyFileVariable: 'SSH_KEY_PATH')]) {
                                sh """
                                    chmod +x ${env.RESTORE_SCRIPT}
                                    scp -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${env.RESTORE_SCRIPT} ${env.VPS_B_USER}@${env.VPS_B_HOST}:${env.COMPOSE_DIR}
                                """
                            }
                        }
                    }
                }
            }
        }

        stage('Execute migrate script in VPS_A') {
            steps {
                script {
                    echo "Executing migrate script on VPS_A..."
                    withCredentials([sshUserPrivateKey(credentialsId: env.SSH_KEY_CREDENTIALS, keyFileVariable: 'SSH_KEY_PATH')]) {
                        sh """
                            ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${env.VPS_A_USER}@${env.VPS_A_HOST} 'bash ${env.COMPOSE_DIR}/${env.BACKUP_SCRIPT_NAME} ${env.VPS_B_USER} ${env.VPS_B_HOST} ${env.COMPOSE_DIR} ${env.BACKUP_DIR}'
                        """
                    }
                }
            }
        }

        stage('Execute restore script in VPS_B') {
            steps {
                script {
                    echo "Executing restore script on VPS_B..."
                    withCredentials([sshUserPrivateKey(credentialsId: env.SSH_KEY_CREDENTIALS, keyFileVariable: 'SSH_KEY_PATH')]) {
                        sh """
                            ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${env.VPS_B_USER}@${env.VPS_B_HOST} 'bash ${env.COMPOSE_DIR}/${env.RESTORE_SCRIPT_NAME} ${env.BACKUP_DIR}'
                        """
                    }
                }
            }
        }

        stage('Clone Docker Compose Repos from Git and Deploy Containers') {
            steps {
                script {
                    echo "Cloning Docker Compose repos from Git and deploying containers..."
                    withCredentials([sshUserPrivateKey(credentialsId: env.SSH_KEY_CREDENTIALS, keyFileVariable: 'SSH_KEY_PATH')]) {
                        sh """
                            ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${env.VPS_B_USER}@${env.VPS_B_HOST} <<EOF
                            for dir in ${env.COMPOSE_DIR}/*/; do
                                (cd "$dir" && docker-compose up -d)
                            done
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
            echo "Cleaning up and ensuring Docker services are restarted."
            script {
                parallel (
                    "Check Docker service on VPS A": {
                        withCredentials([sshUserPrivateKey(credentialsId: env.SSH_KEY_CREDENTIALS, keyFileVariable: 'SSH_KEY_PATH')]) {
                            sh """
                                ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${env.VPS_A_USER}@${env.VPS_A_HOST} <<EOF
                                sudo systemctl start docker || echo Docker already started
                                docker ps
                                exit
                                EOF
                            """
                        }
                    },
                    "Check Docker service on VPS B": {
                        withCredentials([sshUserPrivateKey(credentialsId: env.SSH_KEY_CREDENTIALS, keyFileVariable: 'SSH_KEY_PATH')]) {
                            sh """
                                ssh -i ${SSH_KEY_PATH} -o StrictHostKeyChecking=no ${env.VPS_B_USER}@${env.VPS_B_HOST} <<EOF
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
