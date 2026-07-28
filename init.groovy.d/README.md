# Jenkins Groovy Post-Initialization Scripts

This module documents the automated Groovy post-initialization scripts executed by the Jenkins Master controller engine during system startup.

---

## Technical File Audit

| Script Name | Target System API | Target Files / Inputs | Idempotency Check |
| --- | --- | --- | --- |
| [`create-pipeline-job.groovy`](file:///d:/Personal_Files/VS_Code_Check/Devops_Practice/Snap_Dev/init.groovy.d/create-pipeline-job.groovy) | `org.jenkinsci.plugins.workflow.job.WorkflowJob`<br>`org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition` | `/var/lib/jenkins/bootstrap/Jenkinsfile-compose` | Skips if job `Snap-Dev` exists (`jenkins.getItem(jobName) != null`). |
| [`ssh-credential.groovy`](file:///d:/Personal_Files/VS_Code_Check/Devops_Practice/Snap_Dev/init.groovy.d/ssh-credential.groovy) | `com.cloudbees.plugins.credentials.SystemCredentialsProvider`<br>`com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey` | `/var/lib/jenkins/secrets/agent_key` | Skips if credential `agent-ssh-key` exists (`store.getCredentials(...).find`). |

---

## Technical Execution Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Jenkins Controller Startup                      │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│ Executes Scripts in /var/jenkins_home/init.groovy.d/ (Alphabetical)    │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
           ┌────────────────────────┴────────────────────────┐
           │                                                 │
           ▼                                                 ▼
┌────────────────────────────────────┐            ┌────────────────────────────────────┐
│   create-pipeline-job.groovy       │            │       ssh-credential.groovy        │
├────────────────────────────────────┤            ├────────────────────────────────────┤
│ 1. Validate Jenkins instance state │            │ 1. Verify /var/lib/jenkins/secrets/│
│ 2. Check if 'Snap-Dev' job exists  │            │    agent_key file existence        │
│ 3. Read Jenkinsfile-compose text   │            │ 2. Query SystemCredentialsProvider │
│ 4. Instantiate WorkflowJob         │            │ 3. Check if 'agent-ssh-key' exists │
│ 5. Set CpsFlowDefinition           │            │ 4. Instantiate BasicSSHUserPrivateKey│
│ 6. Persist job definition via      │            │ 5. Save to Global Domain           │
│    job.save()                      │            │    Credentials Store               │
└────────────────────────────────────┘            └────────────────────────────────────┘
```

---

## Detailed Script Code Walkthrough

### 1. Job Creation Bootstrap (`create-pipeline-job.groovy`)

The script [`create-pipeline-job.groovy`](file:///d:/Personal_Files/VS_Code_Check/Devops_Practice/Snap_Dev/init.groovy.d/create-pipeline-job.groovy) programmatically registers the `Snap-Dev` declarative pipeline workflow:

```groovy
import jenkins.model.*
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition

def jenkins = Jenkins.getInstanceOrNull()

if (jenkins == null) {
    println "Jenkins instance not available."
    return
}

def jobName = "Snap-Dev"

if (jenkins.getItem(jobName) != null) {
    println "Pipeline job '${jobName}' already exists. Skipping..."
    return
}

def pipelineFile = new File("/var/lib/jenkins/bootstrap/Jenkinsfile-compose")

if (!pipelineFile.exists()) {
    println "ERROR: Jenkinsfile-compose not found at ${pipelineFile.absolutePath}"
    return
}

def pipelineScript = pipelineFile.getText("UTF-8")

WorkflowJob job = jenkins.createProject(WorkflowJob.class, jobName)

job.description = "Snap_Dev Docker Compose Deployment Pipeline"

job.definition = new CpsFlowDefinition(pipelineScript, true)

job.save()

println "Pipeline job '${jobName}' created successfully."
```

#### Line-by-Line Code Rationale:
- `Jenkins.getInstanceOrNull()`: Obtains active singleton instance of Jenkins controller safely without throwing NullPointerException.
- `jenkins.getItem(jobName)`: Queries the Jenkins job registry to guarantee idempotency across controller restarts.
- `new File("/var/lib/jenkins/bootstrap/Jenkinsfile-compose")`: References pre-injected bootstrap pipeline file created by Terraform UserData.
- `pipelineFile.getText("UTF-8")`: Reads raw Groovy pipeline code as UTF-8 string.
- `jenkins.createProject(WorkflowJob.class, jobName)`: Instantiates a pipeline project object (`WorkflowJob`).
- `new CpsFlowDefinition(pipelineScript, true)`: Encapsulates pipeline code inside a CPS (Continuation Passing Style) flow definition with Groovy sandbox execution enabled (`true`).
- `job.save()`: Writes XML representation to `/var/jenkins_home/jobs/Snap-Dev/config.xml`.

---

### 2. SSH Credential Registration (`ssh-credential.groovy`)

The script [`ssh-credential.groovy`](file:///d:/Personal_Files/VS_Code_Check/Devops_Practice/Snap_Dev/init.groovy.d/ssh-credential.groovy) provisions the SSH private key required for Jenkins Master to authenticate with the remote Agent node over SSH:

```groovy
import com.cloudbees.plugins.credentials.SystemCredentialsProvider
import com.cloudbees.plugins.credentials.domains.Domain
import com.cloudbees.plugins.credentials.CredentialsScope
import com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey
import com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey.DirectEntryPrivateKeySource

def keyFile = new File("/var/lib/jenkins/secrets/agent_key")

if (!keyFile.exists()) {
    println "SSH private key file not found!"
    return
}

def privateKey = keyFile.text

def store = SystemCredentialsProvider.getInstance().getStore()

def existing = store
    .getCredentials(Domain.global())
    .find { it.id == "agent-ssh-key" }

if (existing != null) {
    println "SSH Credential already exists. Skipping creation."
    return
}

def credentials = new BasicSSHUserPrivateKey(
    CredentialsScope.GLOBAL,
    "agent-ssh-key",
    "ubuntu",
    new DirectEntryPrivateKeySource(privateKey),
    "",
    "SSH Key for Jenkins Agent"
)

store.addCredentials(
    Domain.global(),
    credentials
)

println "SSH Credential 'agent-ssh-key' created successfully."
```

#### Line-by-Line Code Rationale:
- `new File("/var/lib/jenkins/secrets/agent_key")`: Targets 4096-bit RSA private key dynamically generated by Terraform `tls_private_key`.
- `SystemCredentialsProvider.getInstance().getStore()`: Fetches Jenkins system credentials store instance.
- `store.getCredentials(Domain.global()).find { it.id == "agent-ssh-key" }`: Inspects global credentials domain to prevent duplicate credential entries.
- `new BasicSSHUserPrivateKey(...)`: Constructs SSH username/key credential object bound to default Ubuntu username `ubuntu` and key ID `agent-ssh-key`.
- `store.addCredentials(...)`: Saves credential permanently into Jenkins credentials subsystem (`credentials.xml`).

---

## File System & Permission Requirements

Ensure the following file permissions exist on the Jenkins Master host prior to script execution:

| File Path | Owner : Group | Required Permissions | Purpose |
| --- | --- | --- | --- |
| `/var/jenkins_home/init.groovy.d/` | `jenkins:jenkins` | `0755` (rwxr-xr-x) | Directory containing init scripts |
| `/var/lib/jenkins/secrets/agent_key` | `jenkins:jenkins` | `0600` (rw-------) | Private SSH key file |
| `/var/lib/jenkins/bootstrap/Jenkinsfile-compose` | `jenkins:jenkins` | `0644` (rw-r--r--) | Bootstrap pipeline file |

---

## Debugging Init Scripts

Inspect Jenkins startup logs to verify Groovy script execution results:

```bash
# View systemd service logs on Jenkins Master
journalctl -u jenkins -f | grep -E "Pipeline job|SSH Credential"
```
