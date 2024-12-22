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
        SSH_USER = 'root'
        BACKUP_SCRIPT = "./scripts/migrate_containers_2.sh"
        RESTORE_SCRIPT = "./scripts/restore_volumes.sh"
        RESTORE_SCRIPT_NAME = "restore_volumes.sh"
    }

    stages {
        stage('Copy Scripts') {
            parallel {
                stage('Copy the migrate_containers.sh to VPS_A') {
                    steps {
                        script {
                            echo "Copying the migrate_containers.sh to VPS_A..."
                            // withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH')]) {
                            //     sh "chmod +x ${BACKUP_SCRIPT}"
                            //     sh """
                            //         scp -i $SSH_KEY_PATH -o StrictHostKeyChecking=no ${BACKUP_SCRIPT} ${VPS_A_USER}@${VPS_A_HOST}:${COMPOSE_DIR}
                            //     """
                            // }
                        }
                    }
                }
                stage('Copy the restore_volumes.sh to VPS_B') {
                    steps {
                        script {
                            echo "Copying the restore_volumes.sh to VPS_B..."
                            withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH')]) {
                                sh "chmod +x ${RESTORE_SCRIPT}"
                                sh """
                                    scp -i $SSH_KEY_PATH -o StrictHostKeyChecking=no ${RESTORE_SCRIPT} ${VPS_B_USER}@${VPS_B_HOST}:${COMPOSE_DIR}
                                """
                            }
                        }
                    }
                }
            }
        }

        // stage('Execute migrate_container.sh in VPS_A') {
        //     steps {
        //         script {
        //             echo "Executing migrate_containers.sh on VPS_A..."
        //             withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH')]) {
        //                 sh """
        //                     ssh -i $SSH_KEY_PATH -o StrictHostKeyChecking=no ${VPS_A_USER}@${VPS_A_HOST} 'bash ${COMPOSE_DIR}/${BACKUP_SCRIPT} ${VPS_B_USER} ${VPS_B_HOST} ${COMPOSE_DIR} ${BACKUP_DIR}'
        //                 """
        //             }
        //         }
        //     }
        // }

        stage('Execute restore_volumes.sh in VPS_B') {
            steps {
                script {
                    echo "Executing restore_volumes.sh on VPS_B..."
                    withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH')]) {
                        sh """
                            ssh -i $SSH_KEY_PATH -o StrictHostKeyChecking=no ${VPS_B_USER}@${VPS_B_HOST} 'bash ${COMPOSE_DIR}/${RESTORE_SCRIPT_NAME} ${BACKUP_DIR}'
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
                            EOF
                        """
                    }
                }
            }
        }
    }

    // post {
    //     always {
    //         echo "Cleaning up and ensuring Docker services are restarted."
    //         script {
    //             parallel (
    //                 "Check Docker service on VPS A": {

    //                     // withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH')]) {
    //                     //     sh """
    //                     //         ssh -i $SSH_KEY_PATH -o StrictHostKeyChecking=no ${VPS_A_USER}@${VPS_A_HOST} 'sudo systemctl start docker || echo Docker already started'
    //                     //     """
    //                     // }
    //                 },
    //                 "Check Docker service on VPS B": {
    //                     withCredentials([sshUserPrivateKey(credentialsId: 'proxmox_server', keyFileVariable: 'SSH_KEY_PATH')]) {
    //                         sh """
    //                             ssh -i $SSH_KEY_PATH -o StrictHostKeyChecking=no ${VPS_B_USER}@${VPS_B_HOST} 'docker ps'
    //                         """
    //                     }
    //                 }
    //             )
    //         }
    //     }
    // }
}
