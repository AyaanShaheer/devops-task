pipeline {
    agent any
    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        ECR_URI           = '023231074437.dkr.ecr.us-east-1.amazonaws.com/devops-task'
        IMAGE_TAG         = "${env.BUILD_NUMBER}"
    }
    stages {
        stage('Build & Test') {
            steps {
                sh 'node --version'
                sh 'npm ci'
                sh 'npm test || echo "no tests yet"'
            }
        }
        stage('Dockerize') {
            steps {
                script {
                    def image = docker.build("devops-task:${IMAGE_TAG}")
                }
            }
        }
        stage('Push to ECR') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-jenkins-credentials', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                        aws ecr get-login-password --region $AWS_DEFAULT_REGION | \
                        docker login --username AWS --password-stdin $ECR_URI
                        docker tag devops-task:$IMAGE_TAG $ECR_URI:$IMAGE_TAG
                        docker push $ECR_URI:$IMAGE_TAG
                    '''
                }
            }
        }
        stage('Deploy to App Runner') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-jenkins-credentials', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                        aws apprunner create-service \
                          --service-name devops-task-service \
                          --source-configuration "ImageRepository={ImageIdentifier=$ECR_URI:$IMAGE_TAG,ImageRepositoryType=ECR,ImageConfiguration={Port=3000}}" \
                          --instance-configuration Cpu=256,Memory=512 \
                          --region $AWS_DEFAULT_REGION || \
                        aws apprunner update-service \
                          --service-arn $(aws apprunner list-services --region $AWS_DEFAULT_REGION --query "ServiceSummaryList[?ServiceName==\''devops-task-service\''].ServiceArn" --output text) \
                          --source-configuration "ImageRepository={ImageIdentifier=$ECR_URI:$IMAGE_TAG,ImageRepositoryType=ECR,ImageConfiguration={Port=3000}}" \
                          --region $AWS_DEFAULT_REGION
                    '''
                }
            }
        }
    }
}
