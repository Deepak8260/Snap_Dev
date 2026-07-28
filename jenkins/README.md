# Jenkins Declarative CI/CD Pipelines

This module documents the production Jenkins declarative pipeline manifests used for building, testing, deploying, and emailing automated status reports in **SnapDev**.

---

## Technical File Audit

| Pipeline File | Target Agent | Primary Deployment Strategy | Reporting Mechanism | Cleanup Action |
| --- | --- | --- | --- | --- |
| [`Jenkinsfile-build`](Jenkinsfile-build) | `label 'flask-app-agent'` | Raw Docker Build & `docker run` | Plain Text via `emailext` | Container stop & rm |
| [`Jenkinsfile-compose`](Jenkinsfile-compose) | `label 'flask-app-agent'` | `docker compose pull`<br>`docker compose up -d --force-recreate` | Responsive HTML Email Template | `always { sh 'docker logout \|\| true' }` |

---

## Deep Dive: Pipeline Code Walkthroughs

### 1. Direct Build Pipeline (`Jenkinsfile-build`)

The pipeline [`Jenkinsfile-build`](Jenkinsfile-build) executes local image builds and single-container deployments:

```groovy
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
"""
            )
        }
    }
}
```

---

### 2. Docker Compose Production Pipeline (`Jenkinsfile-compose`)

The pipeline [`Jenkinsfile-compose`](Jenkinsfile-compose) manages production deployments via Docker Compose with styled HTML email notifications:

```groovy
pipeline {
    agent { label 'flask-app-agent' }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/Deepak8260/Snap_Dev.git'
                echo 'Repository cloned successfully.'
            }
        }

        stage('Pull Latest Image') {
            steps {
                sh 'docker compose pull'
                echo 'Latest Docker image pulled successfully .'
            }
        }

        stage('Deploy Application') {
            steps {
                sh 'docker compose up -d --force-recreate'
                echo 'Application deployed successfully.'
            }
        }
    }

    post {
        success {
            mail(
                to: 'kd.codegeek@gmail.com',
                subject: "✅ Snap Dev CI/CD | Build Success #${env.BUILD_NUMBER}",
                mimeType: 'text/html',
                body: """
<!DOCTYPE html>
<html>
<body style="margin:0;padding:0;background:#f4f6f9;font-family:Arial,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0" style="padding:30px;">
<tr><td align="center">
<table width="700" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:14px;overflow:hidden;box-shadow:0 10px 25px rgba(0,0,0,.12);">
<tr><td style="background:#111827;padding:28px;color:white;">
<h1 style="margin:0;">🚀 Snap Dev CI/CD Pipeline</h1>
<p style="margin:8px 0 0;color:#d1d5db;">Automated Deployment Report</p>
</td></tr>
<tr><td style="background:#16a34a;color:white;padding:18px;text-align:center;font-size:22px;font-weight:bold;">
✅ BUILD SUCCESSFUL
</td></tr>
<tr><td style="padding:30px;">
<h2 style="margin-top:0;color:#111827;">Deployment Summary</h2>
<table width="100%" cellpadding="12" cellspacing="0" style="border-collapse:collapse;">
<tr style="background:#f8fafc;"><td><b>Project</b></td><td>Snap Dev</td></tr>
<tr><td><b>Job</b></td><td>${env.JOB_NAME}</td></tr>
<tr style="background:#f8fafc;"><td><b>Build Number</b></td><td>#${env.BUILD_NUMBER}</td></tr>
<tr><td><b>Status</b></td><td style="color:#16a34a;font-weight:bold;">SUCCESS</td></tr>
<tr style="background:#f8fafc;"><td><b>Build URL</b></td><td><a href="${env.BUILD_URL}">Open Jenkins Build</a></td></tr>
</table>
<br>
<div style="text-align:center;">
<a href="${env.BUILD_URL}" style="background:#2563eb;color:white;padding:14px 28px;border-radius:8px;text-decoration:none;font-weight:bold;">View Build Details</a>
</div>
</td></tr>
</table>
</td></tr>
</table>
</body>
</html>
"""
            )
            echo 'Build Successful!'
        }

        failure {
            mail(
                to: 'kd.codegeek@gmail.com',
                subject: "❌ Snap Dev CI/CD | Build Failed #${env.BUILD_NUMBER}",
                mimeType: 'text/html',
                body: """
<!DOCTYPE html>
<html>
<body style="margin:0;padding:0;background:#f4f6f9;font-family:Arial,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0" style="padding:30px;">
<tr><td align="center">
<table width="700" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:14px;overflow:hidden;box-shadow:0 10px 25px rgba(0,0,0,.12);">
<tr><td style="background:#111827;padding:28px;color:white;">
<h1 style="margin:0;">🚀 Snap Dev CI/CD Pipeline</h1>
<p style="margin:8px 0 0;color:#d1d5db;">Automated Deployment Report</p>
</td></tr>
<tr><td style="background:#dc2626;color:white;padding:18px;text-align:center;font-size:22px;font-weight:bold;">
❌ BUILD FAILED
</td></tr>
<tr><td style="padding:30px;">
<h2 style="margin-top:0;color:#111827;">Deployment Summary</h2>
<table width="100%" cellpadding="12" cellspacing="0" style="border-collapse:collapse;">
<tr style="background:#f8fafc;"><td><b>Project</b></td><td>Snap Dev</td></tr>
<tr><td><b>Job</b></td><td>${env.JOB_NAME}</td></tr>
<tr style="background:#f8fafc;"><td><b>Build Number</b></td><td>#${env.BUILD_NUMBER}</td></tr>
<tr><td><b>Status</b></td><td style="color:#dc2626;font-weight:bold;">FAILED</td></tr>
<tr style="background:#f8fafc;"><td><b>Build URL</b></td><td><a href="${env.BUILD_URL}">Open Jenkins Build</a></td></tr>
</table>
<br>
<div style="text-align:center;">
<a href="${env.BUILD_URL}" style="background:#dc2626;color:white;padding:14px 28px;border-radius:8px;text-decoration:none;font-weight:bold;">View Error Logs</a>
</div>
</td></tr>
</table>
</td></tr>
</table>
</body>
</html>
"""
            )
            echo 'Pipeline Failed!'
        }

        always {
            sh 'docker logout || true'
        }
    }
}
```

---

## Technical Features of Email Reporting

1. **Inline CSS Styling**: Standard email clients (Gmail, Outlook) strip `<style>` head tags. CSS is inlined on table elements (`padding`, `background`, `border-radius`, `box-shadow`) to guarantee identical rendering across devices.
2. **Conditional Post Banners**:
   - Success Banners use background color `#16a34a` (Green) with checkmark icon `✅`.
   - Failure Banners use background color `#dc2626` (Red) with error icon `❌`.
3. **Dynamic Build Variable Injection**: Injects Jenkins environment variables (`${env.JOB_NAME}`, `${env.BUILD_NUMBER}`, `${env.BUILD_URL}`).
4. **Always Clean Session**: Executes `docker logout || true` in the `always` block to prevent lingering registry credentials on the build node.
