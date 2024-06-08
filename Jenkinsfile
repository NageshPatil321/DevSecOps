pipeline {
    agent any
    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        SONARQUBE_SERVER = 'SonarQube-Server'
        SONARQUBE_TOKEN = credentials('SonarQube-Token')
    }
    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }
        stage('Checkout from Git') {
            steps {
                git branch: 'main', url: 'https://github.com/NageshPatil321/DevSecOps.git'
            }
        }
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv(SONARQUBE_SERVER) {
                    sh '''
                        $SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectName=Youtube-CICD \
                        -Dsonar.projectKey=Youtube-CICD \
                        -Dsonar.login=$SONARQUBE_TOKEN
                    '''
                }
            }
        }
        stage('Quality Gate') {
            steps {
                script {
                    def qualityGate = waitForQualityGate()
                    if (qualityGate.status != 'OK') {
                        error "Pipeline aborted due to quality gate failure: ${qualityGate.status}"
                    }
                }
            }
        }
        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }
        stage('TRIVY FS SCAN') {
            steps {
                sh 'trivy fs . > trivyfs.txt'
            }
        }
        stage('Docker Build') {
            steps {
                sh 'docker build -t youtube-clone:${BUILD_NUMBER} .'
                sh 'docker tag youtube-clone nagesh0205/youtube-clone:${BUILD_NUMBER}'
            }
        }
        stage('TRIVY Image Scan') {
            steps {
                sh 'trivy image nagesh0205/youtube-clone:${BUILD_NUMBER} > trivyimage.txt'
            }
        }
        stage('Update deployment file') {
            steps {
                script {
                    sh """
                    cd Kubernetes
                    sed -i 's/youtube-clone:[0-9]\\+/youtube-clone:$BUILD_NUMBER/g' deployment.yml
                    
                    # Commit and push the changes
                    git status
                    git add Kubernetes/deployment.yml
                    git commit -m "Update deployment image to version ${BUILD_NUMBER}"
                    git push origin main
                    """
                }
            }
        }
        stage('Docker Image Push') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'dockerhub') {
                        sh 'docker push nagesh0205/youtube-clone:${BUILD_NUMBER}'
                    }
                }
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    dir('Kubernetes') {
                        withKubeConfig(caCertificate: '', clusterName: '', contextName: '', credentialsId: 'kubernetes', namespace: '', restrictKubeConfigAccess: false, serverUrl: '') {
                            sh 'kubectl delete --all pods'
                            sh 'kubectl apply -f deployment.yml'
                            sh 'kubectl apply -f service.yml'
                        }
                    }
                }
            }
        }
    }
}
