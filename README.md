# SnapDev — Flask App DevOps Pipeline

> A complete end-to-end DevOps project that containerizes a Flask application using Docker, deploys it on AWS EC2, and automates the entire build-deploy lifecycle using a Jenkins Master-Agent architecture with GitHub Webhooks and email notifications.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Architecture Diagram](#architecture-diagram)
- [Tech Stack](#tech-stack)
- [Repository Structure](#repository-structure)
- [Part 1 — Manual Docker Deployment](#part-1--manual-docker-deployment)
  - [Step 1: Launch an EC2 Instance](#step-1-launch-an-ec2-instance)
  - [Step 2: Install Docker on the Instance](#step-2-install-docker-on-the-instance)
  - [Step 3: Clone the Repository and Build the Docker Image](#step-3-clone-the-repository-and-build-the-docker-image)
  - [Step 4: Run the Container and Open Port 5000](#step-4-run-the-container-and-open-port-5000)
  - [Step 5: Push the Docker Image to DockerHub](#step-5-push-the-docker-image-to-dockerhub)
  - [Important Note on Instance Type](#important-note-on-instance-type)
- [Part 2 — Automated CI/CD with Jenkins](#part-2--automated-cicd-with-jenkins)
  - [Infrastructure Setup Overview](#infrastructure-setup-overview)
  - [Step 1: Launch Two Fresh EC2 Instances](#step-1-launch-two-fresh-ec2-instances)
  - [Step 2: Install Jenkins on the Master Node](#step-2-install-jenkins-on-the-master-node)
  - [Step 3: Unlock Jenkins and Complete Initial Setup](#step-3-unlock-jenkins-and-complete-initial-setup)
  - [Step 4: Install Docker and Java on the Agent Node](#step-4-install-docker-and-java-on-the-agent-node)
  - [Step 5: Create a Workspace Directory on the Agent](#step-5-create-a-workspace-directory-on-the-agent)
  - [Step 6: Generate SSH Key Pair on Jenkins Master](#step-6-generate-ssh-key-pair-on-jenkins-master)
  - [Step 7: Authorize the Master's Public Key on the Agent](#step-7-authorize-the-masters-public-key-on-the-agent)
  - [Step 8: Register the Agent Node in Jenkins UI](#step-8-register-the-agent-node-in-jenkins-ui)
  - [Step 9: Launch the Agent and Verify Connection](#step-9-launch-the-agent-and-verify-connection)
  - [Step 10: Configure Email (SMTP) Notifications in Jenkins](#step-10-configure-email-smtp-notifications-in-jenkins)
  - [Step 11: Add GitHub and DockerHub Credentials in Jenkins](#step-11-add-github-and-dockerhub-credentials-in-jenkins)
  - [Step 12: Create and Configure the Jenkins Pipeline Job](#step-12-create-and-configure-the-jenkins-pipeline-job)
  - [Step 13: Set Up the GitHub Webhook](#step-13-set-up-the-github-webhook)
  - [Step 14: Trigger a Build and Verify the Full Pipeline](#step-14-trigger-a-build-and-verify-the-full-pipeline)
- [How the Complete Flow Works](#how-the-complete-flow-works)
- [What the Jenkinsfile Does](#what-the-jenkinsfile-does)
- [Final Verification Checklist](#final-verification-checklist)
- [Troubleshooting](#troubleshooting)

---

## Project Overview

This project is split into two major parts.

**Part 1 — Manual Deployment:** The Flask application is containerized using Docker and deployed manually on an AWS EC2 instance. The Docker image is then pushed to DockerHub. This phase exists purely to validate that the application, Dockerfile, and Docker workflow are all working correctly before any automation is introduced.

**Part 2 — Automated CI/CD Pipeline:** The manual EC2 instance from Part 1 is terminated. Two fresh EC2 instances are created — one for Jenkins Master and one for the Jenkins Agent. Jenkins is configured with a Master-Agent architecture where the Master only orchestrates and the Agent does all the actual build and deployment work. From this point on, every code push to GitHub automatically triggers Jenkins, which builds the Docker image, pushes it to DockerHub, deploys the application, and sends an email notification about the build result.

---

## Architecture Diagram

```
Developer Pushes Code
        │
        ▼
   GitHub Repository
        │  (Webhook triggers Jenkins on port 8080)
        ▼
  Jenkins Master EC2 (t3.micro)
        │  (Delegates work to Agent over SSH on port 22)
        ▼
  Jenkins Agent EC2 (t3.micro)
        ├── Clones latest code from GitHub
        ├── Builds Docker Image
        ├── Pushes Image to DockerHub
        └── Deploys Application via Docker Compose
                        │
                        ▼
             Email Notification Sent
           (Success or Failure → Gmail)
```

---

## Tech Stack

| Component | Technology |
|---|---|
| Application | Python / Flask |
| Containerization | Docker, Docker Compose |
| Cloud Infrastructure | AWS EC2 (Ubuntu) |
| CI/CD Server | Jenkins |
| Source Control | GitHub |
| Container Registry | DockerHub |
| Email Notifications | Gmail SMTP / Jenkins Extended Email Plugin |
| Automation Trigger | GitHub Webhook |

---

## Repository Structure

```
Flask-1-tier-app/
├── app.py                              # Main Flask application
├── requirements.txt                    # Python dependencies
├── Dockerfile                          # Docker image definition
├── docker-compose.yml                  # Docker Compose configuration
├── Jenkinsfile                         # Jenkins pipeline definition
├── Jenkins_Installation_For_AWS.sh     # Jenkins + Java installation script
└── docker_setup.sh                     # Docker installation script
```

> The installation scripts are available in this repository. For EC2 instances, copy the script content from GitHub, create a new file on the instance using `vim`, paste the content in, save with `:wq`, and run it. This approach is explained in detail in each step below.

---

## Part 1 — Manual Docker Deployment

This part validates the entire Docker setup manually before any automation is introduced. Once confirmed working, this instance will be terminated and you will move on to Part 2.

---

### Step 1: Launch an EC2 Instance

1. Go to **AWS Console → EC2 → Launch Instance**
2. Configure with the following settings:
   - **Name:** `snapdev-docker-test`
   - **AMI:** Ubuntu (latest LTS)
   - **Instance Type:** `t3.medium` *(see [Important Note](#important-note-on-instance-type) below)*
   - **Key Pair:** Create or select an existing key pair and download the `.pem` file
   - **Network Settings:** Enable SSH, HTTP, and HTTPS traffic
   - **Storage:** 15 GB
3. Click **Launch Instance**

SSH into the instance once it is running:

```bash
ssh -i your-key.pem ubuntu@<EC2-PUBLIC-IP>
```

Update system packages:

```bash
sudo apt update && sudo apt upgrade -y
```

---

### Step 2: Install Docker on the Instance

Copy the contents of `docker_setup.sh` from this repository. On the EC2 instance, create the file using `vim`:

```bash
vim docker_setup.sh
```

Paste the script content inside, save and exit with `:wq`, then run it:

```bash
bash docker_setup.sh
```

After installation, refresh the Docker group so the current session picks up the Docker permission without a reboot:

```bash
newgrp docker
```

Verify Docker is running:

```bash
docker --version
docker ps
```

---

### Step 3: Clone the Repository and Build the Docker Image

Clone this repository on the EC2 instance:

```bash
git clone https://github.com/Deepak8260/Flask-1-tier-app.git
cd Flask-1-tier-app
```

Build the Docker image:

```bash
docker build -t flask-app .
```

This reads the `Dockerfile` in the project root and packages the Flask application into a container image.

---

### Step 4: Run the Container and Open Port 5000

Run the Docker container:

```bash
docker run -d -p 5000:5000 flask-app
```

The Flask application runs on port 5000. Open that port in AWS:

1. Go to **AWS Console → EC2 → Your Instance → Security → Security Groups**
2. Click **Edit Inbound Rules → Add Rule**:
   - **Type:** Custom TCP
   - **Port Range:** `5000`
   - **Source:** Anywhere (`0.0.0.0/0`)
3. Click **Save rules**

Open a browser and navigate to:

```
http://<EC2-PUBLIC-IP>:5000
```

You should see the Flask application running successfully.

---

### Step 5: Push the Docker Image to DockerHub

Log in to DockerHub using your username and a **Personal Access Token** (not your account password):

```bash
docker login -u <your-dockerhub-username>
```

When prompted for a password, enter your DockerHub Personal Access Token. You can generate one at [hub.docker.com → Account Settings → Security → New Access Token](https://hub.docker.com/settings/security).

Tag the image with your DockerHub username:

```bash
docker tag flask-app <your-dockerhub-username>/flask-app:latest
```

Push the image:

```bash
docker push <your-dockerhub-username>/flask-app:latest
```

The image is now available in your DockerHub repository. Part 1 is complete.

> ✅ Once you have confirmed the application runs correctly and the image is on DockerHub, **terminate this EC2 instance**. Everything from here on is handled automatically by Jenkins.

---

### Important Note on Instance Type

> ⚠️ `t2.micro` (free tier) is too small to comfortably run both Jenkins and Docker simultaneously — it will be slow and may crash during builds. For the manual validation in Part 1, `t3.medium` is recommended as it provides enough CPU and memory for a stable experience. For the Jenkins Master and Agent instances in Part 2, `t3.micro` is sufficient since each instance handles only one responsibility.

---

## Part 2 — Automated CI/CD with Jenkins

With Part 1 confirmed and the test instance terminated, you will now set up a Jenkins Master-Agent pipeline. **Follow every step in the exact order listed — the sequence matters.**

---

### Infrastructure Setup Overview

| Instance | Name | Role | What Is Installed |
|---|---|---|---|
| EC2 #1 | `jenkins-master` | Orchestration only | Jenkins + Java |
| EC2 #2 | `agent-node` | Build and deploy | Java + Docker |

The Master never builds or deploys anything itself. It receives the webhook trigger from GitHub, picks up the pipeline, and delegates all work to the Agent over SSH. The Agent does everything — clone, build, push, deploy.

---

### Step 1: Launch Two Fresh EC2 Instances

Launch two separate EC2 instances with the following settings for each:

| Setting | Value |
|---|---|
| AMI | Ubuntu (latest LTS) |
| Instance Type | `t3.micro` |
| Key Pair | Use the same key pair for both (simplifies SSH access) |
| Network Settings | Enable SSH, HTTP, HTTPS |
| Storage | 15 GB |

Name them clearly:
- Instance 1: `jenkins-master`
- Instance 2: `agent-node`

---

### Step 2: Install Jenkins on the Master Node

SSH into the **`jenkins-master`** instance:

```bash
ssh -i your-key.pem ubuntu@<JENKINS-MASTER-PUBLIC-IP>
```

Update packages first:

```bash
sudo apt update && sudo apt upgrade -y
```

Copy the contents of `Jenkins_Installation_For_AWS.sh` from this repository. Create the file on the instance using `vim`:

```bash
vim Jenkins_Installation_For_AWS.sh
```

Paste the script content, save and exit with `:wq`, then run it:

```bash
bash Jenkins_Installation_For_AWS.sh
```

This script installs both Java and Jenkins. Once the script finishes, open port `8080` in AWS so you can access Jenkins in a browser:

1. Go to **AWS Console → EC2 → `jenkins-master` instance → Security → Security Groups**
2. Click **Edit Inbound Rules → Add Rule**:
   - **Type:** Custom TCP
   - **Port Range:** `8080`
   - **Source:** Anywhere (`0.0.0.0/0`)
3. Click **Save rules**

---

### Step 3: Unlock Jenkins and Complete Initial Setup

Open a browser and navigate to:

```
http://<JENKINS-MASTER-PUBLIC-IP>:8080
```

Jenkins will ask for an initial admin password. Retrieve it from the Master instance terminal:

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Copy the output, paste it into the browser, and click **Continue**.

On the next screen:
- Click **Install suggested plugins** and wait for the installation to complete
- Create your admin user (fill in username, password, full name, and email)
- Leave the Jenkins URL as the default and click **Save and Finish**
- Click **Start using Jenkins**

You are now on the Jenkins Dashboard. Keep this browser tab open — most of the configuration from here onward happens inside Jenkins.

---

### Step 4: Install Docker and Java on the Agent Node

Open a new terminal and SSH into the **`agent-node`** instance:

```bash
ssh -i your-key.pem ubuntu@<AGENT-NODE-PUBLIC-IP>
```

Update packages:

```bash
sudo apt update && sudo apt upgrade -y
```

**Install Docker:**

Copy the contents of `docker_setup.sh` from this repository. Create the file using `vim`:

```bash
vim docker_setup.sh
```

Paste the script content, save and exit with `:wq`, then run it:

```bash
bash docker_setup.sh
```

Refresh the Docker group:

```bash
newgrp docker
```

**Install Java:**

There is no separate Java installation script for the Agent. You have two options:

- **Option A:** Open `Jenkins_Installation_For_AWS.sh` from this repository, copy only the Java installation commands from it, and run them on the Agent.
- **Option B:** Follow the official Jenkins Linux installation guide at [https://www.jenkins.io/doc/book/installing/linux/](https://www.jenkins.io/doc/book/installing/linux/) and run only the Java installation step from there.

Example command (verify the version matches what is in the script or the official guide):

```bash
sudo apt install -y fontconfig openjdk-21-jre
```

Verify Java is installed:

```bash
java -version
```

> You do **not** need to install Jenkins itself on the Agent. Only Java and Docker are required here. Java is needed because the Jenkins Agent communicates with the Master through a Java-based remote process.

---

### Step 5: Create a Workspace Directory on the Agent

Still on the **`agent-node`**, create a dedicated working directory where Jenkins will clone code and run builds:

```bash
mkdir pipeline-workspace
cd pipeline-workspace
pwd
```

Copy the full output path — it will look like `/home/ubuntu/pipeline-workspace`. You will need this exact path in the next step when registering the agent inside Jenkins.

---

### Step 6: Generate SSH Key Pair on Jenkins Master

Switch back to the terminal connected to **`jenkins-master`** and generate an SSH key pair:

```bash
ssh-keygen
```

Press Enter through all prompts and leave the passphrase empty. This generates two files:

- `~/.ssh/id_ed25519` — **Private Key** — stays on the Master, will be pasted into Jenkins credentials
- `~/.ssh/id_ed25519.pub` — **Public Key** — will be copied to the Agent

---

### Step 7: Authorize the Master's Public Key on the Agent

On **`jenkins-master`**, display the public key:

```bash
cat ~/.ssh/id_ed25519.pub
```

Copy the entire output. Then switch to the terminal connected to **`agent-node`** and open the authorized keys file:

```bash
vim ~/.ssh/authorized_keys
```

Paste the public key on a new line, then save and exit with `:wq`.

This allows the Jenkins Master to SSH into the Agent without a password — which is exactly how Jenkins dispatches jobs to the Agent during every build.

---

### Step 8: Register the Agent Node in Jenkins UI

Go back to the Jenkins browser tab:

1. Click **Manage Jenkins → Nodes → New Node**
2. Enter the node name: `flask-app-agent`
3. Select **Permanent Agent** and click **Create**
4. Fill in the configuration form:

| Field | Value |
|---|---|
| Description | Agent node that handles build and deployment for the Flask application |
| Remote Root Directory | `/home/ubuntu/pipeline-workspace` |
| Labels | `flask-builder` |
| Usage | Use this node as much as possible |
| Launch Method | Launch agents via SSH |
| Host | Public IP of your `agent-node` EC2 instance |

5. Under **Credentials**, click **Add → Jenkins** and fill in:

| Field | Value |
|---|---|
| Kind | SSH Username with Private Key |
| ID | `flask-agent-ssh-key` |
| Description | SSH private key for Jenkins Master to connect to the Agent |
| Username | `ubuntu` |
| Private Key | Select **Enter directly** → paste the full contents of `~/.ssh/id_ed25519` from the Master |

6. Click **Add**, then select `flask-agent-ssh-key` from the Credentials dropdown
7. Set **Host Key Verification Strategy** to `Non-verifying`
8. Click **Save**

---

### Step 9: Launch the Agent and Verify Connection

1. From **Manage Jenkins → Nodes**, click on `flask-app-agent`
2. Click **Launch Agent**

Watch the log output. After a few seconds you should see:

```
Agent is successfully connected and online ✅
```

The Jenkins Master and Agent are now fully connected over SSH. Any pipeline job labeled `flask-builder` will be routed to this Agent automatically.

---

### Step 10: Configure Email (SMTP) Notifications in Jenkins

Jenkins needs to be able to send Gmail notifications for build success and failure. This involves three things: opening the SMTP port in AWS, generating a Gmail App Password, and configuring Jenkins to use it.

**Open Port 465 on the Jenkins Master Security Group:**

1. Go to **AWS Console → EC2 → `jenkins-master` instance → Security → Security Groups**
2. Click **Edit Inbound Rules → Add Rule**:
   - **Type:** Custom TCP
   - **Port Range:** `465`
   - **Source:** Anywhere (`0.0.0.0/0`)
3. Click **Save rules**

**Generate a Gmail App Password:**

Gmail does not allow your regular account password to be used for SMTP. An App Password is required:

1. Go to [myaccount.google.com](https://myaccount.google.com)
2. Navigate to **Security → 2-Step Verification** and make sure it is turned **ON**
3. In the same Security section, search for **App Passwords**
4. Create a new App Password with a name like `jenkins-snapdev`
5. Copy the 16-character password — you will not be able to view it again after closing the dialog

**Add Gmail Credentials in Jenkins:**

1. Go to **Manage Jenkins → Credentials → System → Global credentials (unrestricted)**
2. Click **Add Credentials** and fill in:

| Field | Value |
|---|---|
| Kind | Username and Password |
| Username | Your Gmail address (e.g., `yourname@gmail.com`) |
| Password | The 16-character App Password from above |
| ID | `gmail-app-password` |
| Description | Gmail App Password for Jenkins build notifications |

3. Click **Create**

**Configure Extended Email Notification in Jenkins:**

1. Go to **Manage Jenkins → System**
2. Scroll down to the **Extended Email Notification** section
3. Fill in **only these four fields** and leave everything else completely blank:

| Field | Value |
|---|---|
| SMTP Server | `smtp.gmail.com` |
| SMTP Port | `465` |
| Credentials | Select `gmail-app-password` |
| Use SSL | ✅ Checked |

4. Click **Save**

> ⚠️ **Critical:** Do NOT fill in Default Recipients, Reply-To List, Default Subject, or any other field in this section. Populating those fields will override whatever is defined in your Jenkinsfile and break email delivery.

---

### Step 11: Add GitHub and DockerHub Credentials in Jenkins

The pipeline needs credentials to pull code from GitHub and push images to DockerHub. Both are stored securely in Jenkins and referenced by their credential ID inside the Jenkinsfile.

**Add GitHub Credentials:**

1. Go to **Manage Jenkins → Credentials → System → Global credentials (unrestricted)**
2. Click **Add Credentials** and fill in:

| Field | Value |
|---|---|
| Kind | Username and Password |
| Username | Your GitHub username |
| Password | Your GitHub Personal Access Token |
| ID | `github-credentials` |
| Description | GitHub credentials for accessing the Flask app repository |

3. Click **Create**

> To generate a GitHub Personal Access Token, go to **GitHub → Settings → Developer Settings → Personal Access Tokens → Tokens (classic) → Generate new token**. Select at minimum the `repo` scope and copy the token immediately — it will not be shown again.

**Add DockerHub Credentials:**

1. Still in **Global credentials**, click **Add Credentials** again and fill in:

| Field | Value |
|---|---|
| Kind | Username and Password |
| Username | Your DockerHub username |
| Password | Your DockerHub Personal Access Token |
| ID | `dockerhub-credentials` |
| Description | DockerHub credentials for pushing Flask app images |

2. Click **Create**

> To generate a DockerHub Personal Access Token, go to **hub.docker.com → Account Settings → Security → New Access Token**.

---

### Step 12: Create and Configure the Jenkins Pipeline Job

Now you will create the actual pipeline job that pulls the `Jenkinsfile` from your GitHub repository and runs all stages on the Agent.

**Create the Job:**

1. From the **Jenkins Dashboard**, click **New Item**
2. Enter the job name: `flask-app-pipeline`
3. Select **Pipeline** as the project type
4. Click **OK**

**Configure the Job:**

You are now on the job configuration page. Work through it section by section:

**General:**
- Add a description: `CI/CD pipeline for the SnapDev Flask application`

**Build Triggers:**
- ✅ Check **GitHub hook trigger for GITScm polling**

This links the GitHub webhook to this specific job. Every time GitHub sends a push event webhook to Jenkins, Jenkins will find all jobs with this option enabled and trigger them automatically. Without this checkbox ticked, the webhook has nothing to connect to and builds will not trigger automatically.

**Pipeline:**

This is the most important section. Change the **Definition** dropdown from `Pipeline script` to:

> **Pipeline script from SCM**

This tells Jenkins to fetch the `Jenkinsfile` directly from your GitHub repository every time the pipeline runs, instead of requiring you to paste a script manually into the UI. This means any changes you push to the Jenkinsfile in GitHub are automatically picked up on the next build.

Fill in the fields that appear:

| Field | Value |
|---|---|
| SCM | Git |
| Repository URL | `https://github.com/Deepak8260/Flask-1-tier-app.git` |
| Credentials | Select `github-credentials` |
| Branch Specifier | `*/main` |
| Script Path | `Jenkinsfile` |

> **Script Path** tells Jenkins which file in the repository contains the pipeline definition. Since the `Jenkinsfile` is at the root of the repository, simply enter `Jenkinsfile` with no folder prefix.

Click **Save**.

---

### Step 13: Set Up the GitHub Webhook

The GitHub webhook is what makes GitHub notify Jenkins automatically on every push, which triggers the pipeline without any manual action.

First, confirm that port `8080` is open to `0.0.0.0/0` on your `jenkins-master` Security Group (done in Step 2 — verify the Source is `Anywhere` and not restricted to just your IP).

Then in GitHub:

1. Go to your repository → **Settings → Webhooks → Add webhook**
2. Fill in the form:

| Field | Value |
|---|---|
| Payload URL | `http://<JENKINS-MASTER-PUBLIC-IP>:8080/github-webhook/` |
| Content type | `application/json` |
| SSL Verification | Disable |
| Which events to trigger | Send me everything |

3. Click **Add webhook**

GitHub will immediately send a test ping to Jenkins. In the **Recent Deliveries** section of that webhook, a green tick confirms Jenkins received and responded to the ping successfully.

> ⚠️ The Payload URL must end with `/github-webhook/` including the trailing slash. Missing the slash is one of the most common reasons webhooks fail silently.

---

### Step 14: Trigger a Build and Verify the Full Pipeline

Everything is now configured. Trigger a build to verify the entire pipeline works end-to-end.

**Option A — Manual trigger (recommended for first run):**

Go to **Jenkins Dashboard → `flask-app-pipeline` → Build Now**. This is the safest way to confirm the pipeline works correctly before relying entirely on the webhook.

**Option B — Automatic trigger via Git push:**

Make any small change to your repository (for example, update a comment in `app.py`) and push to GitHub:

```bash
git add .
git commit -m "Trigger test build"
git push origin main
```

The webhook fires, Jenkins picks it up within seconds, and the pipeline starts automatically.

**Monitor the build:**

Click on the build number that appears under **Build History** on the left side of the job page, then click **Console Output**. You will see live logs of every stage running on the Agent — clone, Docker build, push to DockerHub, deploy with Docker Compose.

A successful run will look like:

```
[Pipeline] stage: Clone Repository
[Pipeline] stage: Build Docker Image
[Pipeline] stage: Push to DockerHub
[Pipeline] stage: Deploy Application
Finished: SUCCESS ✅
```

Check your Gmail inbox — you should receive a build notification email confirming success, or detailing the failure if something went wrong.

---

## How the Complete Flow Works

Once everything is configured, here is exactly what happens every time you push code to GitHub:

1. **GitHub** detects the push and fires a webhook to Jenkins Master on port `8080`
2. **Jenkins Master** receives the webhook and identifies the matching pipeline job (`flask-app-pipeline`)
3. **Jenkins Master** delegates the entire pipeline to the Agent labeled `flask-builder` over SSH
4. **Agent** clones the latest code from the GitHub repository
5. **Agent** builds the Docker image using the `Dockerfile`
6. **Agent** pushes the newly built image to DockerHub using the stored `dockerhub-credentials`
7. **Agent** deploys the updated application using Docker Compose
8. **On success** → Jenkins sends an email: *Build Successful — Flask App*
9. **On failure** → Jenkins sends an email: *Build Failed — Flask App* with error details
10. **Jenkins Master** remains completely free throughout — it only orchestrates and never runs build work itself

---

## What the Jenkinsfile Does

The `Jenkinsfile` at the root of this repository defines the complete pipeline. It:

- Targets the Agent node with the label `flask-builder` so all work runs on the Agent, never the Master
- Clones the latest application code from GitHub
- Builds the Docker image from the `Dockerfile`
- Authenticates with DockerHub using the stored `dockerhub-credentials` and pushes the image
- Deploys the updated application using Docker Compose on the Agent
- On **success** — sends a formatted email notification to the configured Gmail address
- On **failure** — sends a failure notification email with build details

Refer to the `Jenkinsfile` in this repository for the complete pipeline script.

After making any changes to the Jenkinsfile, commit and push:

```bash
git add Jenkinsfile
git commit -m "Updated Jenkins pipeline"
git push origin main
```

This push will itself trigger the webhook and kick off a new build automatically.

---

## Final Verification Checklist

| What to Verify | Where to Check |
|---|---|
| Agent is online | Jenkins → Manage Jenkins → Nodes → `flask-app-agent` shows **Online** |
| Gmail credentials saved | Jenkins → Manage Jenkins → Credentials → Global → `gmail-app-password` exists |
| GitHub credentials saved | Jenkins → Manage Jenkins → Credentials → Global → `github-credentials` exists |
| DockerHub credentials saved | Jenkins → Manage Jenkins → Credentials → Global → `dockerhub-credentials` exists |
| SMTP configured correctly | Jenkins → Manage Jenkins → System → Extended Email Notification → only SMTP fields filled |
| Pipeline job created | Jenkins Dashboard → `flask-app-pipeline` job exists |
| Build Triggers enabled | Job config → Build Triggers → GitHub hook trigger for GITScm polling is checked |
| SCM configured in job | Job config → Pipeline → Definition is `Pipeline script from SCM` → points to this repo |
| Webhook is live | GitHub → Repository → Settings → Webhooks → Recent Deliveries → green tick ✅ |
| Agent receives build work | Trigger a build → Console Output shows stages running on `flask-app-agent` |
| Pipeline auto-triggers on push | Push any small change to GitHub → Jenkins build starts within seconds |
| Email on success | Check inbox after a successful build |
| Email on failure | Intentionally break something small, push, and verify the failure email arrives |

---

## Troubleshooting

**Agent fails to connect**
- Confirm the public key is pasted correctly in `~/.ssh/authorized_keys` on the Agent with no extra spaces or line breaks
- Verify port `22` is open in the Agent's Security Group inbound rules
- Confirm the private key content pasted into Jenkins credentials exactly matches `~/.ssh/id_ed25519` from the Master — no extra lines or trailing spaces

**Jenkins not accessible on port 8080**
- Confirm port `8080` is open in the `jenkins-master` Security Group with Source `0.0.0.0/0`
- Check the Jenkins service is running: `sudo systemctl status jenkins`

**Port 5000 / application not accessible (Part 1 only)**
- Confirm the Security Group inbound rule for port `5000` has Source `0.0.0.0/0`
- Verify the container is running with `docker ps` on the instance

**Email notifications not sending**
- Confirm 2-Step Verification was enabled on your Gmail account before the App Password was generated
- Confirm port `465` is open in the `jenkins-master` Security Group
- Confirm no extra fields (Default Recipients, Reply-To, Default Subject) are filled in the Extended Email Notification section in Jenkins

**GitHub Webhook shows a red X or 302 response**
- Confirm port `8080` is open in the `jenkins-master` Security Group with Source `Anywhere (0.0.0.0/0)`
- Confirm the Payload URL ends with `/github-webhook/` including the trailing slash
- In Jenkins, go to **Manage Jenkins → Security** and confirm the webhook endpoint does not require authentication, or configure it with a secret token

**Pipeline does not auto-trigger on push but Build Now works**
- Confirm the **GitHub hook trigger for GITScm polling** checkbox is checked inside the job's Build Triggers section
- Confirm the webhook in GitHub is pointing to the correct Jenkins URL and showing a green response in Recent Deliveries

**DockerHub push fails**
- Confirm the credential ID `dockerhub-credentials` in Jenkins matches exactly what is referenced inside the Jenkinsfile
- Confirm the DockerHub Personal Access Token has write permissions

---

> **GitHub Repository:** [https://github.com/Deepak8260/Flask-1-tier-app](https://github.com/Deepak8260/Flask-1-tier-app)