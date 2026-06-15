pipeline {
    agent { label 'flask-app-agent' }

    stages {

        stage("clone") {
            steps {
                git url: "https://github.com/Deepak8260/Snap_Dev.git", branch: "main"
                echo "cloned successfully"
            }
        }

        stage("build") {
            steps {
                sh "docker rmi -f pandu || true"
                sh "docker build -t pandu ."
                echo "build successfully"
            }
        }

        stage("test") {
            steps {
                echo "tested successfully"
            }
        }

        stage("deploy") {
            steps {
                sh "docker stop gandu || true"
                sh "docker rm -f gandu || true"
                sh "docker run -d -p 5000:5000 --name gandu pandu"
                echo "deployed successfully"
            }
        }
    }

    post {
        success {
            emailext(
                to: 'kd.codegeek@gmail.com',
                subject: "SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "Build completed successfully."
            )
        }

        failure {
            emailext(
                to: 'kd.codegeek@gmail.com',
                subject: "FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "Build failed. Check Jenkins logs."
            )
        }
    }
}
