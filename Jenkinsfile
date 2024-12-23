// This pipline asumes that you are using named volumes in you compose file.

pipeline {
    agent any

    environment {
        VPS_A_USER = "root"
        VPS_A_HOST = "10.1.1.221"
        VPS_B_USER = "root"
        VPS_B_HOST = "10.1.1.100"
        COMPOSE_DIR = "/root/Automating_migration_of_containers/compose_files"
        BACKUP_DIR = "/tmp/docker_volume_backups"
        SSH_KEY_PATH = credentials('proxmox_server')
        BACKUP_SCRIPT = "./scripts/migrate_containers_volumes.sh"
        RESTORE_SCRIPT = "./scripts/restore_volumes.sh"
        BACKUP_SCRIPT_NAME = "migrate_containers_volumes.sh"
        RESTORE_SCRIPT_NAME = "restore_volumes.sh"
        COMPOSE_PROJECT_NAME="compose_files"
    }

    stages {
        stage('Copy Scripts') {
            parallel {
                stage('Copy the migrate script to VPS_A') {
                    steps {
                        script {
                            echo "Copying the migrate script to VPS_A..."
                            withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH')]) {
                                sh "chmod +x ${BACKUP_SCRIPT}"
                                sh """
                                    scp -i $SSH_KEY_PATH -o StrictHostKeyChecking=no ${BACKUP_SCRIPT} ${VPS_A_USER}@${VPS_A_HOST}:${COMPOSE_DIR}
                                """
                            }
                        }
                    }
                }
                
                stage('Copy the restore script to VPS_B') {
                    steps {
                        script {
                            echo "Copying the restore script to VPS_B..."
                            withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH')]) {
                                sh "chmod +x ${RESTORE_SCRIPT}"
                                sh """
                                    #ssh -i $SSH_KEY_PATH -o StrictHostKeyChecking=no ${VPS_B_USER}@${VPS_B_HOST} 'bash mkdir ${COMPOSE_DIR}'
                                    
                                    scp -i $SSH_KEY_PATH -o StrictHostKeyChecking=no ${RESTORE_SCRIPT} ${VPS_B_USER}@${VPS_B_HOST}:${COMPOSE_DIR}
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
                    withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH')]) {
                        sh """
                            ssh -i $SSH_KEY_PATH -o StrictHostKeyChecking=no ${VPS_A_USER}@${VPS_A_HOST} 'bash ${COMPOSE_DIR}/${BACKUP_SCRIPT_NAME} ${VPS_B_USER} ${VPS_B_HOST} ${COMPOSE_DIR} ${BACKUP_DIR}'
                        """
                    }
                }
            }
        }

        stage('Execute restore script.sh in VPS_B') {
            steps {
                script {
                    echo "Executing restore script on VPS_B..."
                    withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH')]) {
                        sh """
                            ssh -i $SSH_KEY_PATH -o StrictHostKeyChecking=no ${VPS_B_USER}@${VPS_B_HOST} 'bash ${COMPOSE_DIR}/${RESTORE_SCRIPT_NAME} ${BACKUP_DIR} ${COMPOSE_PROJECT_NAME}'
                        """
                    }
                }
            }
        }

        stage('Clone Docker Compose Repos from Git and Deploy Containers') {
            steps {
                script {
                    echo "Cloning Docker Compose repos from Git and deploying containers..."
                    withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH')]) {
                        sh """
                            ssh -i $SSH_KEY_PATH -o StrictHostKeyChecking=no ${VPS_B_USER}@${VPS_B_HOST} <<EOF
                            cd ${COMPOSE_DIR}
                            docker compose up -d
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

                        withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH')]) {
                            sh """
                                ssh -i $SSH_KEY_PATH -o StrictHostKeyChecking=no ${VPS_A_USER}@${VPS_A_HOST} <<EOF
                                sudo systemctl start docker || echo Docker already started
                                docker ps
                                #rm -rf ${BACKUP_DIR}
                                exit
                                EOF

                            """
                        }
                    },
                    "Check Docker service on VPS B": {
                        withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH')]) {
                            sh """
                                ssh -i $SSH_KEY_PATH -o StrictHostKeyChecking=no ${VPS_B_USER}@${VPS_B_HOST} <<EOF
                                docker volume ls
                                docker ps
                                #rm -rf ${BACKUP_DIR}

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
