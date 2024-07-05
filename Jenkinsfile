pipeline {
    agent any

    environment {
        ECR_REGISTRY = '590184124193.dkr.ecr.ap-northeast-2.amazonaws.com'
        ECR_REPOSITORY = 'spring-petclinic-docker'
        GIT_REPO = 'https://github.com/ojung9/spring-petclinic-docker.git'
        BRANCH_NAME = 'main'
        AWS_REGION = 'ap-northeast-2'
        ARGOCD_SERVER = 'a6e9746d7bce541689f1bb354b7b95f2-1861123841.ap-northeast-2.elb.amazonaws.com'
        ARGOCD_APP_NAME = 'app'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: "${BRANCH_NAME}", url: "${GIT_REPO}"
            }
        }

        stage('Determine Version') {
            steps {
                script {
                    def tagsOutput = sh(
                        script: "aws ecr describe-images --repository-name ${ECR_REPOSITORY} --query 'imageDetails[*].imageTags[*]' --output text",
                        returnStdout: true
                    ).trim()

                    def tags = tagsOutput.tokenize()
                    echo "Existing tags in ECR: ${tags}"

                    def latestTag = [1, 5, 0] // default to 1.5.0 if no tags

                    tags.each { tag ->
                        def currentTag = tag.tokenize('.').collect { it.toInteger() }
                        if (compareVersions(currentTag, latestTag) > 0) {
                            latestTag = currentTag
                        }
                    }

                    def (major, minor, patch) = latestTag

                    if (patch >= 15) {
                        patch = 0
                        minor += 1
                    } else {
                        patch += 1
                    }

                    if (minor >= 10) {
                        minor = 0
                        major += 1
                    }

                    env.NEW_VERSION = "${major}.${minor}.${patch}"
                    echo "New version: ${env.NEW_VERSION}"
                }
            }
        }

        stage('Build') {
            steps {
                sh 'echo $(date) > build_info.txt'
                sh 'mvn clean package -Dcheckstyle.skip=true'
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh 'aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID'
                        sh 'aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY'
                        sh 'aws configure set default.region ${AWS_REGION}'
                        sh 'aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}'

                        // Build the Docker image
                        sh "docker build --no-cache -t ${ECR_REGISTRY}/${ECR_REPOSITORY}:${env.NEW_VERSION} ."

                        // Push the Docker image with the new version tag
                        sh "docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:${env.NEW_VERSION}"

                        // Check if k8s/petclinic-deployment.yaml exists
                        if (fileExists('k8s/petclinic-deployment.yaml')) {
                            // Update the Kubernetes deployment file without changing replicas
                            sh """
                            sed -i 's#image: ${ECR_REGISTRY}/${ECR_REPOSITORY}:.*#image: ${ECR_REGISTRY}/${ECR_REPOSITORY}:${env.NEW_VERSION}#' k8s/petclinic-deployment.yaml
                            cat k8s/petclinic-deployment.yaml
                            """
                        } else {
                            error "k8s/petclinic-deployment.yaml file not found"
                        }
                    }
                }
            }
        }

        stage('Commit and Push Changes to Git') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'github-creds', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {
                        sh 'git config --global user.email "ojung9@gmail.com"'
                        sh 'git config --global user.name "ojugn9"'
                        sh 'git pull origin ${BRANCH_NAME}'

                        def changes = sh(script: 'git status --porcelain', returnStdout: true).trim()
                        if (changes) {
                            sh 'git add k8s/petclinic-deployment.yaml'
                            sh "git commit -m 'Update deployment to version ${env.NEW_VERSION}'"
                            sh "git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/ojung9/spring-petclinic-docker.git ${BRANCH_NAME}"
                        } else {
                            echo "No changes to commit"
                        }
                    }
                }
            }
        }

        stage('Check ArgoCD CLI Installation') {
            steps {
                sh '''
                if ! command -v argocd &> /dev/null
                then
                    echo "ArgoCD CLI could not be found. Installing..."
                    curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/download/v2.1.0/argocd-linux-amd64
                    chmod +x argocd
                    mv argocd /usr/local/bin/
                else
                    echo "ArgoCD CLI is installed"
                    argocd version
                fi
                '''
            }
        }

        stage('Deploy to EKS') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'Argo-creds', usernameVariable: 'ARGOCD_USERNAME', passwordVariable: 'ARGOCD_PASSWORD')]) {
                        sh '''
                        argocd login ${ARGOCD_SERVER} --username ${ARGOCD_USERNAME} --password ${ARGOCD_PASSWORD} --insecure --grpc-web
                        argocd app sync ${ARGOCD_APP_NAME} --prune --force
                        argocd app wait ${ARGOCD_APP_NAME} --sync
                        '''
                    }
                }
            }
        }
    }
}

def compareVersions(version1, version2) {
    for (int i = 0; i < version1.size(); i++) {
        if (version1[i] != version2[i]) {
            return version1[i] <=> version2[i]
        }
    }
    return 0
}

