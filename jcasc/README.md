# Jenkins Configuration as Code (JCasC) Specifications

This module documents the Jenkins Configuration as Code (JCasC) YAML manifests used to provision the **SnapDev Jenkins Master Controller** completely without manual UI intervention.

---

## Technical File Audit

| File Name | Targeted JCasC Namespace | Primary Responsibilities |
| --- | --- | --- |
| [`system.yaml`](file:///d:/Personal_Files/VS_Code_Check/Devops_Practice/Snap_Dev/jcasc/system.yaml) | `jenkins`, `unclassified` | System message banner, controller executor isolation (`numExecutors: 0`), system admin email, global SMTP mailer settings, and `email-ext` failure triggers. |
| [`security.yaml`](file:///d:/Personal_Files/VS_Code_Check/Devops_Practice/Snap_Dev/jcasc/security.yaml) | `jenkins.securityRealm`, `jenkins.authorizationStrategy` | Disables signup, creates local admin account from environment variables (`JENKINS_ADMIN_USERNAME`), and applies Global Matrix RBAC permissions. |
| [`credentials.yaml`](file:///d:/Personal_Files/VS_Code_Check/Devops_Practice/Snap_Dev/jcasc/credentials.yaml) | `credentials.system.domainCredentials` | Provisions global credentials for `github-creds` (Personal Access Token), `dockerhub-creds` (DockerHub login), and `smtp-creds` (Mail authentication). |
| [`nodes.yaml`](file:///d:/Personal_Files/VS_Code_Check/Devops_Practice/Snap_Dev/jcasc/nodes.yaml) | `jenkins.nodes` | Provisions the permanent SSH build agent node (`flask-app-agent`) connecting over private IP to port 22 using credential `agent-ssh-key`. |
| [`plugins.txt`](file:///d:/Personal_Files/VS_Code_Check/Devops_Practice/Snap_Dev/jcasc/plugins.txt) | Plugin Management | List of 14 plugins required for pipeline execution, matrix auth, Docker workflow, and email extension. |

---

## Deep Dive: YAML Configuration Specifications

### 1. Controller System & Mailer (`system.yaml`)

The manifest [`system.yaml`](file:///d:/Personal_Files/VS_Code_Check/Devops_Practice/Snap_Dev/jcasc/system.yaml) enforces controller security boundaries and notification channels:

```yaml
jenkins:
  systemMessage: |
    Welcome to Snap_Dev Jenkins Controller

    This Jenkins instance is managed using Jenkins Configuration as Code (JCasC).

    Controller Responsibilities:
    - Receive GitHub Webhooks
    - Schedule and Trigger Pipelines
    - Manage Users, Credentials and Plugins
    - Delegate all build execution to Jenkins Agents

  numExecutors: 0
  mode: EXCLUSIVE

unclassified:
  location:
    adminAddress: "${ADMIN_EMAIL}"

  mailer:
    smtpHost: "${SMTP_SERVER}"
    smtpPort: "${SMTP_PORT}"
    useSsl: ${SMTP_SSL}
    useTls: false
    charset: "UTF-8"
    authentication:
      username: "${SMTP_USERNAME}"
      password: "${SMTP_PASSWORD}"

  email-ext:
    charset: "UTF-8"
    debugMode: false
    allowUnregisteredEnabled: false
    adminRequiredForTemplateTesting: false
    defaultSubject: "$PROJECT_NAME - Build # $BUILD_NUMBER - $BUILD_STATUS!"
    defaultBody: |-
      $PROJECT_NAME - Build # $BUILD_NUMBER - $BUILD_STATUS:
      Check console output at $BUILD_URL to view the results.
    defaultTriggerIds:
      - "hudson.plugins.emailext.plugins.trigger.FailureTrigger"
```

#### Line-by-Line Technical Analysis:
- `numExecutors: 0`: Sets executor count on controller to zero. This enforces Master-Agent isolation so builds never run on the controller node.
- `mode: EXCLUSIVE`: Restricts master from executing unlabelled jobs.
- `unclassified.mailer`: Configures Jenkins core mailer settings using environment variable substitution (`${SMTP_SERVER}`, `${SMTP_PORT}`, `${SMTP_SSL}`).
- `unclassified.email-ext`: Configures default parameters for the Extended Email plugin, binding automatic email triggers to build failures.

---

### 2. Authentication & Authorization (`security.yaml`)

The manifest [`security.yaml`](file:///d:/Personal_Files/VS_Code_Check/Devops_Practice/Snap_Dev/jcasc/security.yaml) configures authentication and RBAC permissions:

```yaml
jenkins:
  securityRealm:
    local:
      allowsSignup: false
      users:
        - id: "${JENKINS_ADMIN_USERNAME}"
          password: "${JENKINS_ADMIN_PASSWORD}"

  authorizationStrategy:
    globalMatrix:
      entries:
        - user:
            name: "${JENKINS_ADMIN_USERNAME}"
            permissions:
              - "Overall/Administer"
```

#### Line-by-Line Technical Analysis:
- `allowsSignup: false`: Blocks public account creation via the Jenkins login interface.
- `users`: Dynamically registers the root administrator user from runtime environment variables.
- `authorizationStrategy.globalMatrix`: Applies Global Matrix authorization strategy, granting `Overall/Administer` permissions strictly to the admin account.

---

### 3. Automated Credentials Store (`credentials.yaml`)

The manifest [`credentials.yaml`](file:///d:/Personal_Files/VS_Code_Check/Devops_Practice/Snap_Dev/jcasc/credentials.yaml) injects global credentials into the Jenkins credentials provider:

```yaml
credentials:
  system:
    domainCredentials:
      - credentials:
          - usernamePassword:
              id: "github-creds"
              scope: GLOBAL
              username: "${GITHUB_USERNAME}"
              password: "${GITHUB_TOKEN}"
              description: "GitHub Credentials"

          - usernamePassword:
              id: "dockerhub-creds"
              scope: GLOBAL
              username: "${DOCKERHUB_USERNAME}"
              password: "${DOCKERHUB_PASSWORD}"
              description: "Docker Hub Credentials"

          - usernamePassword:
              id: "smtp-creds"
              scope: GLOBAL
              username: "${SMTP_USERNAME}"
              password: "${SMTP_PASSWORD}"
              description: "Gmail SMTP Credentials"
```

---

### 4. Build Agent Node Topology (`nodes.yaml`)

The manifest [`nodes.yaml`](file:///d:/Personal_Files/VS_Code_Check/Devops_Practice/Snap_Dev/jcasc/nodes.yaml) registers the permanent SSH build agent node:

```yaml
jenkins:
  nodes:
    - permanent:
        name: "${AGENT_NAME}"
        nodeDescription: "Ubuntu EC2 Docker Build Agent"
        remoteFS: "${AGENT_REMOTE_FS}"
        numExecutors: ${AGENT_EXECUTORS}
        labelString: "${AGENT_LABELS}"
        mode: EXCLUSIVE
        retentionStrategy: "always"
        launcher:
          ssh:
            host: "${AGENT_PRIVATE_IP}"
            port: 22
            credentialsId: "agent-ssh-key"
            sshHostKeyVerificationStrategy:
              nonVerifyingKeyVerificationStrategy: {}
```

#### Line-by-Line Technical Analysis:
- `remoteFS`: Specifies working directory path on Agent host (`/home/ubuntu/jenkins`).
- `labelString`: Binds selection label `flask-app-agent` to this node.
- `launcher.ssh`: Configures SSH launcher connecting over internal AWS private IP (`${AGENT_PRIVATE_IP}`) using credential `agent-ssh-key`.

---

### 5. Plugin Audit Table (`plugins.txt`)

The manifest [`plugins.txt`](file:///d:/Personal_Files/VS_Code_Check/Devops_Practice/Snap_Dev/jcasc/plugins.txt) lists all 14 required Jenkins plugins:

| Plugin Name | Functional Purpose |
| --- | --- |
| `configuration-as-code` | Core JCasC engine plugin |
| `git` | Git SCM integration |
| `github` | GitHub Webhook and API integration |
| `workflow-aggregator` | Pipeline core workflow suite |
| `pipeline-stage-view` | Visual stage view UI |
| `docker-workflow` | Docker pipeline step commands (`docker.build`, etc.) |
| `credentials` | Jenkins credentials management core |
| `ssh-slaves` | SSH build agent launcher plugin |
| `ssh-credentials` | SSH private key credential provider |
| `job-dsl` | Programmatic job definition support |
| `matrix-auth` | Matrix-based security authorization strategy |
| `docker-commons` | Docker API common libraries |
| `mailer` | Core email notification plugin |
| `email-ext` | Extended HTML email notification plugin |

---

## Required Environment Variables Reference

| Variable Name | Description | Example |
| --- | --- | --- |
| `JENKINS_ADMIN_USERNAME` | Admin Username | `admin` |
| `JENKINS_ADMIN_PASSWORD` | Admin Password | `Password123!` |
| `ADMIN_EMAIL` | Admin Email | `admin@example.com` |
| `GITHUB_USERNAME` | GitHub User | `Deepak8260` |
| `GITHUB_TOKEN` | GitHub Personal Access Token | `ghp_xxxxxxxxxxxx` |
| `DOCKERHUB_USERNAME` | DockerHub User | `kumar3472` |
| `DOCKERHUB_PASSWORD` | DockerHub Access Token | `dckr_pat_xxxxxxx` |
| `SMTP_SERVER` | SMTP Host | `smtp.gmail.com` |
| `SMTP_PORT` | SMTP Port | `465` |
| `SMTP_SSL` | Enable SSL | `true` |
| `SMTP_USERNAME` | Mail User | `kd.codegeek@gmail.com` |
| `SMTP_PASSWORD` | Gmail App Password | `xxxx xxxx xxxx xxxx` |
| `AGENT_NAME` | Agent Node Name | `flask-app-agent` |
| `AGENT_PRIVATE_IP` | Agent AWS Private IP | `10.0.1.45` |
| `AGENT_REMOTE_FS` | Remote Workdir | `/home/ubuntu/jenkins` |
| `AGENT_EXECUTORS` | Concurrent Executors | `1` |
| `AGENT_LABELS` | Selection Label | `flask-app-agent` |

---

## Verification & JCasC Hot Reloading

```bash
# Export environment variable on Jenkins Master
export CASC_JENKINS_CONFIG=/var/jenkins_home/casc_configs/

# Reload JCasC configuration live without restarting Jenkins
curl -X POST -u admin:YourAdminPassword123! http://localhost:8080/configuration-as-code/reload
```
