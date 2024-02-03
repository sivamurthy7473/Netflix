pipeline {
    agent any
    tools {
        jdk 'java_17'
        nodejs 'node-16'
    }
    parameters {
      choice choices: ['apply', 'destroy'], description: 'this is for terraform we have to create infra or destroy', name: 'action'
    }
    environment {
        AWS_ACCESS_KEY_ID = credentials('acces_key')
        AWS_SECRET_ACCESS_KEY = credentials('secret_key')
        SONAR_SCANNER = tool 'sonar-tool'
        IMAGE_NAME = 'netflix'
        REGISTRY_NAME = 'sivamurthy1998'
        TMDB_DB_API_KEY = credentials('API_DB_TOKEN')
    }
    stages {
        stage("Clean WorkSpace"){
            steps {
                cleanWs()
            }
        }
         stage("Check Versions Installed or Not"){
            steps{
                script{
                    sh '''
                     echo "-----------Node Version----------"
                     node --version
                     echo "-----------Docker Version----------"
                     docker info
                     echo "-----------AWS Version----------"
                     aws --version
                     echo "-----------terraform Version----------"
                     terraform --version
                     echo "-----------Java Version----------"
                     java --version
                     echo "-----------Git Version----------"
                     git version
                    '''
                }
            }
        }
        stage("Git Checkout Branch"){
            steps{
                checkout scmGit(branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/sivamurthy7473/Netflix.git']])
            }
        }
        stage("Sonar CodeQuality Aalysis"){
            steps{
                withSonarQubeEnv(installationName: "sonar-server", credentialsId: 'SONAR-TOKEN') {
                    sh ''' 
                     $SONAR_SCANNER/bin/sonar-scanner -Dsonar.projectKey=Jenkins -Dsonar.projectName='Jenkins-Uat-env' 
                    '''
                }
            }
        }
        stage("Install Dependencies"){
            steps{
               script {
                 sh "npm install"
                 sh 'echo "-----------Npm Version-----------"'
                 sh "npm --version"
                }
            }
        }
        stage("OWASP Dependencies-Check"){
            steps{
                dependencyCheck additionalArguments:' --scan ./ --disableYarnAudit --disableNodeAudit' , odcInstallation: 'DC'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }
        stage("Trivy Filesyatem Scan"){
            steps{
                sh " trivy filesystem . > trvyscan.txt"
                sh 'echo "-----------trvyscan.txt----------"'
                sh 'cat trvyscan.txt'
            }
        }
        stage("Docker Image Build"){
            steps{
                withCredentials([string
                    (credentialsId: 'DOCKER_PASSWORD', variable: 'password')]) {
                    sh '''
                    echo "TMDB_V3_API_KEY: ${TMDB_V3_API_KEY}"
                    docker login -u ${REGISTRY_NAME} -p ${password}
                    docker image build --build-arg TMDB_V3_API_KEY=${TMDB_DB_API_KEY} -t ${REGISTRY_NAME}/${IMAGE_NAME}:${BUILD_ID} .
                    '''
                }
            }
        }
        stage("Trivi Image Scan"){
            steps {
                sh '''
                trivy image ${REGISTRY_NAME}/${IMAGE_NAME}:${BUILD_ID} > trivyimage.txt
                docker push ${REGISTRY_NAME}/${IMAGE_NAME}:${BUILD_ID}
                '''
                sh 'echo "-----------trvyscan.txt----------"'
                sh 'cat trvyscan.txt'
            }
        }
        stage("Terraform Init"){
            steps {
                script{
                    dir('AWS-EKS-CLUSTER') {
                       sh 'echo "-----------Terraform Intializing-------------"'
                       sh "terraform init"
                    }
                }
            }
        }
        stage("Check Terraform Format"){
            steps {
                script{
                    dir('AWS-EKS-CLUSTER') {
                        sh 'echo "-----------Terraform Alignment Correct or Not-------------"'
                        sh "terraform fmt"
                    }
                }
            }
        }
        stage('Terraform Validate'){
            steps {
                script{
                    dir('AWS-EKS-CLUSTER') {
                        sh 'echo "-----------Terraform Validating Resources-------------"'
                        sh "terraform validate"
                    }
                }
            }
        }
        stage("Terraform plan"){
            steps {
                script{
                    dir('AWS-EKS-CLUSTER') {
                        sh 'echo "-----------Terraform Preview The Template Code-------------"'
                        sh "terraform plan --var-file=./values.tfvars"
                    }
                    input message: 'are you sure to proceed ', ok: 'proceed'
                }
            }
        }
        stage("Terraform apply/destroy"){
            steps{
                script{
                    dir('AWS-EKS-CLUSTER'){
                        sh 'echo "-----------Terraform Create/Destroy The Resources------------"'
                        sh "terraform $action --auto-approve --var-file=./values.tfvars"
                    }
                }
            }
        }
        stage("Deploy Kubernetes Manifest Files"){
            steps{
               script{
                  dir('AWS-EKS-CLUSTER/manifestFiles') {
                     sh'''
                        aws eks update-kubeconfig --name my-eks-cluster --region us-west-1
                        kubectl apply -f deployment.yaml
                        kubectl apply -f service.yaml
                       '''
                  }
               } 
            }
        }
    }
}
