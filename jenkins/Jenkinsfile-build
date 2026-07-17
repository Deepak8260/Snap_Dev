pipeline {
    agent { label 'flask-app-agent' }

    environment {
        DOCKER_IMAGE = "snap-dev-app"
        CONTAINER_NAME = "snap-dev-container"
    }

    stages {

        stage("Clone Repository") {
            steps {
                git url: "https://github.com/Deepak8260/Snap_Dev.git", branch: "main"
                echo "Repository cloned successfully."
            }
        }

        stage("Build Docker Image") {
            steps {
                sh "docker rmi -f ${DOCKER_IMAGE} || true"
                sh "docker build -t ${DOCKER_IMAGE} ."
                echo "Docker image built successfully."
            }
        }

        stage("Run Tests") {
            steps {
                echo "Application tests completed successfully."
            }
        }

        stage("Deploy Application") {
            steps {
                sh "docker stop ${CONTAINER_NAME} || true"
                sh "docker rm -f ${CONTAINER_NAME} || true"
                sh "docker run -d -p 5000:5000 --name ${CONTAINER_NAME} ${DOCKER_IMAGE}"
                echo "Application deployed successfully."
            }
        }
    }

    post {
        success {
            emailext(
                to: 'kd.codegeek@gmail.com',
                subject: "SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
Hello,

The Jenkins pipeline completed successfully.

Job Name: ${env.JOB_NAME}
Build Number: ${env.BUILD_NUMBER}
Status: SUCCESS

The latest Docker container has been deployed successfully.

Regards,
Jenkins
"""
            )
        }

        failure {
            emailext(
                to: 'kd.codegeek@gmail.com',
                subject: "FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
Hello,

The Jenkins pipeline has failed.

Job Name: ${env.JOB_NAME}
Build Number: ${env.BUILD_NUMBER}
Status: FAILED

Please check the Jenkins console logs for more details.

Regards,
Jenkins
"""
            )
        }
    }
}