# SnapDev — Flask App DevOps Pipeline

> A complete end-to-end DevOps project that containerizes a Flask web application using Docker (standard and multi-stage builds), manages deployment with Docker Compose, and automates the full build-test-deploy lifecycle using a Jenkins Master-Agent architecture with GitHub Webhooks and email notifications on AWS EC2.

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
- [Part 2 — Docker Multi-Stage Build](#part-2--docker-multi-stage-build)
  - [What is a Multi-Stage Build?](#what-is-a-multi-stage-build)
  - [Standard Dockerfile vs Multi-Stage Dockerfile](#standard-dockerfile-vs-multi-stage-dockerfile)
  - [How to Build and Run the Multi-Stage Image](#how-to-build-and-run-the-multi-stage-image)
- [Part 3 — Docker Compose Deployment](#part-3--docker-compose-deployment)
  - [What is Docker Compose?](#what-is-docker-compose)
  - [docker-compose.yml Explained](#docker-composeyml-explained)
  - [Running the App with Docker Compose](#running-the-app-with-docker-compose)
- [Part 4 — Automated CI/CD with Jenkins](#part-4--automated-cicd-with-jenkins)
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

This project is divided into four major parts that progressively build on each other.

**Part 1 — Manual Docker Deployment:** The Flask application is containerized using a standard `Dockerfile` and deployed manually on an AWS EC2 instance. The Docker image is pushed to DockerHub. This phase validates that the application, Dockerfile, and Docker workflow all work correctly before automation is introduced.

**Part 2 — Docker Multi-Stage Build:** A second Dockerfile (`Dockerfile-multi`) is introduced that uses multi-stage builds to produce a significantly smaller and more secure production image using Google's distroless base image. This section explains the concept, compares it to the standard build, and shows how to use it.

**Part 3 — Docker Compose Deployment:** A `docker-compose.yml` file is used to manage the container lifecycle declaratively — building the image, naming the container, setting restart policies, and mapping ports — all from a single command.

**Part 4 — Automated CI/CD Pipeline:** Two fresh EC2 instances are created — one for Jenkins Master and one for Jenkins Agent. Jenkins is configured with a Master-Agent architecture where the Master orchestrates and the Agent runs all build and deployment work. Every code push to GitHub automatically triggers Jenkins, which clones the code, builds the Docker image, pushes it to DockerHub, deploys via Docker Compose, and sends an email notification about the build result.

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

| Component            | Technology                                 |
|----------------------|--------------------------------------------|
| Application          | Python / Flask                             |
| Containerization     | Docker, Docker Compose, Multi-Stage Builds |
| Cloud Infrastructure | AWS EC2 (Ubuntu)                           |
| CI/CD Server         | Jenkins                                    |
| Source Control       | GitHub                                     |
| Container Registry   | DockerHub                                  |
| Email Notifications  | Gmail SMTP / Jenkins Extended Email Plugin |
| Automation Trigger   | GitHub Webhook                             |

---

## Repository Structure

```
Snap_Dev/
├── app.py                   # Main Flask application
├── requirements.txt         # Python dependencies
├── Dockerfile               # Standard single-stage Docker build
├── Dockerfile-multi         # Optimized multi-stage Docker build (distroless)
├── docker-compose.yml       # Docker Compose service definition
├── Jenkinsfile              # Jenkins declarative pipeline definition
├── static/                  # Static assets (CSS, JS, images)
├── templates/               # HTML templates for Flask
├── .gitignore
└── dummy.txt
```

---

## Part 1 — Manual Docker Deployment

This part validates the entire Docker setup manually before any automation is introduced. Once confirmed working, this instance will be terminated and you will move on to Part 2 and beyond.

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

Install Docker using the official convenience script:

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu
```

Refresh the Docker group so the current session picks up the Docker permission without a reboot:

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
git clone https://github.com/Deepak8260/Snap_Dev.git
cd Snap_Dev
```

The standard `Dockerfile` is:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["python", "app.py"]
```

Build the Docker image:

```bash
docker build -t flask-app .
```

---

### Step 4: Run the Container and Open Port 5000

Run the Docker container:

```bash
docker run -d -p 5000:5000 flask-app
```

Open port 5000 in AWS:

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

Log in to DockerHub using a **Personal Access Token** (not your account password):

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

> ✅ Once you have confirmed the application runs correctly and the image is on DockerHub, **terminate this EC2 instance**. Everything from here on is handled automatically by Jenkins.

---

### Important Note on Instance Type

> ⚠️ `t2.micro` (free tier) is too small to comfortably run both Jenkins and Docker simultaneously — it will be slow and may crash during builds. For manual validation in Part 1, `t3.medium` is recommended as it provides enough CPU and memory for a stable experience. For the Jenkins Master and Agent instances in Part 4, `t3.micro` is sufficient since each instance handles only one responsibility.

---

## Part 2 — Docker Multi-Stage Build

### What is a Multi-Stage Build?

A multi-stage Docker build uses multiple `FROM` instructions in a single `Dockerfile`. Each `FROM` starts a new build stage. You can selectively copy artifacts from one stage to another, leaving behind everything you don't need in the final image — build tools, compilers, intermediate files, etc.

The key benefits are:

- **Dramatically smaller image size** — only the runtime essentials are packaged
- **Improved security** — no build tools or unnecessary packages in the production image
- **No intermediate images to clean up** — all intermediate layers are discarded automatically

---

### Standard Dockerfile vs Multi-Stage Dockerfile

**Standard `Dockerfile`** (used in Part 1):

```dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["python", "app.py"]
```

This image includes pip, the Python installer, build utilities, and all installation artifacts — they remain in the final image even though they're not needed at runtime.

---

**Multi-Stage `Dockerfile-multi`** (this repository):

```dockerfile
# ── Stage 1: Builder ──────────────────────────────────────────────────────────
FROM python:3.9-slim as builder

WORKDIR /app
COPY . .
RUN pip install -r requirements.txt --target=/app/deps

# ── Stage 2: Final (Distroless) ───────────────────────────────────────────────
FROM gcr.io/distroless/python3-debian13

WORKDIR /app
COPY --from=builder /app/deps /app/deps
COPY --from=builder /app .
EXPOSE 5000
ENV PYTHONPATH="/app/deps"
CMD ["app.py"]
```

**How it works:**

- **Stage 1 (`builder`)** — uses `python:3.9-slim` to install all dependencies into the `/app/deps` directory using `--target` (isolated install, not into the system Python)
- **Stage 2 (final)** — uses Google's `distroless/python3-debian13` image, which contains only the Python runtime and nothing else: no shell, no package manager, no utilities
- Only the installed dependencies and application code are copied from the builder stage into the final image
- `PYTHONPATH` is set so Python can locate the dependencies at runtime

**Result:** The final image is a fraction of the size of the standard image and has a drastically reduced attack surface — there is literally no shell to exploit.

---

### How to Build and Run the Multi-Stage Image

Build using the multi-stage Dockerfile:

```bash
docker build -f Dockerfile-multi -t flask-app-mini .
```

Run the container:

```bash
docker run -d -p 5000:5000 flask-app-mini
```

Compare image sizes:

```bash
docker images
```

You will see that `flask-app-mini` is significantly smaller than `flask-app`.

---

## Part 3 — Docker Compose Deployment

### What is Docker Compose?

Docker Compose is a tool for defining and running multi-container (or single-container) Docker applications using a declarative YAML file. Instead of running long `docker run` commands with multiple flags, everything is defined in `docker-compose.yml` and the entire application stack is started with a single command.

Benefits include:

- Reproducible deployments — the configuration is version-controlled alongside the code
- Automatic restart policies — containers restart on failure or reboot without manual intervention
- Clean lifecycle management — one command to bring everything up, one command to tear everything down

---

### docker-compose.yml Explained

```yaml
services:
  app:
    build: .
    image: snapimg-mini
    container_name: snapcont
    restart: unless-stopped
    ports:
      - "5000:5000"
```

| Field              | Purpose                                                                                   |
|--------------------|-------------------------------------------------------------------------------------------|
| `build: .`         | Builds the Docker image from the `Dockerfile` in the current directory                   |
| `image: snapimg-mini` | Names the resulting image `snapimg-mini`                                               |
| `container_name: snapcont` | Assigns a fixed, predictable name to the running container                      |
| `restart: unless-stopped` | Automatically restarts the container if it crashes or the EC2 instance reboots — unless you manually stop it |
| `ports: "5000:5000"` | Maps port 5000 on the host to port 5000 inside the container                           |

---

### Running the App with Docker Compose

Make sure Docker Compose is installed. On modern Docker installations it is bundled as `docker compose` (without the hyphen):

```bash
docker compose version
```

If it is not available, install the plugin:

```bash
sudo apt install docker-compose-plugin -y
```

**Start the application:**

```bash
docker compose up -d
```

The `-d` flag runs it in detached (background) mode.

**View running containers:**

```bash
docker compose ps
```

**View application logs:**

```bash
docker compose logs -f
```

**Stop the application:**

```bash
docker compose down
```

**Rebuild and restart after a code change:**

```bash
docker compose up -d --build
```

Access the application at:

```
http://<EC2-PUBLIC-IP>:5000
```

---

## Part 4 — Automated CI/CD with Jenkins

With the Docker and Docker Compose setup confirmed, you will now set up a Jenkins Master-Agent pipeline that automates the entire build and deployment process on every code push to GitHub. **Follow every step in the exact order listed — the sequence matters.**

---

### Infrastructure Setup Overview

| Instance | Name             | Role               | What Is Installed      |
|----------|------------------|--------------------|------------------------|
| EC2 #1   | `jenkins-master` | Orchestration only | Jenkins + Java         |
| EC2 #2   | `agent-node`     | Build and deploy   | Java + Docker + Compose |

The Master never builds or deploys anything itself. It receives the webhook trigger from GitHub, picks up the pipeline, and delegates all work to the Agent over SSH. The Agent does everything — clone, build, push, deploy.

---

### Step 1: Launch Two Fresh EC2 Instances

Launch two separate EC2 instances with the following settings for each:

| Setting          | Value                                                   |
|------------------|---------------------------------------------------------|
| AMI              | Ubuntu (latest LTS)                                     |
| Instance Type    | `t3.micro`                                              |
| Key Pair         | Use the same key pair for both (simplifies SSH access)  |
| Network Settings | Enable SSH, HTTP, HTTPS                                 |
| Storage          | 15 GB                                                   |

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

Install Java (required by Jenkins):

```bash
sudo apt install -y fontconfig openjdk-21-jre
java -version
```

Install Jenkins:

```bash
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update
sudo apt install jenkins -y
sudo systemctl enable jenkins
sudo systemctl start jenkins
sudo systemctl status jenkins
```

Open port `8080` in AWS so you can access Jenkins in a browser:

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

You are now on the Jenkins Dashboard.

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

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu
newgrp docker
docker --version
```

**Install Docker Compose plugin:**

```bash
sudo apt install docker-compose-plugin -y
docker compose version
```

**Install Java:**

```bash
sudo apt install -y fontconfig openjdk-21-jre
java -version
```

> You do **not** need to install Jenkins itself on the Agent. Only Java, Docker, and Docker Compose are required here. Java is needed because the Jenkins Agent communicates with the Master through a Java-based remote process.

---

### Step 5: Create a Workspace Directory on the Agent

Still on the **`agent-node`**, create a dedicated working directory where Jenkins will clone code and run builds:

```bash
mkdir pipeline-workspace
cd pipeline-workspace
pwd
```

Copy the full output path — it will look like `/home/ubuntu/pipeline-workspace`. You will need this exact path when registering the agent inside Jenkins.

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

| Field                 | Value                                                                   |
|-----------------------|-------------------------------------------------------------------------|
| Description           | Agent node that handles build and deployment for the Flask application  |
| Remote Root Directory | `/home/ubuntu/pipeline-workspace`                                       |
| Labels                | `flask-app-agent`                                                       |
| Usage                 | Use this node as much as possible                                       |
| Launch Method         | Launch agents via SSH                                                   |
| Host                  | Public IP of your `agent-node` EC2 instance                             |

5. Under **Credentials**, click **Add → Jenkins** and fill in:

| Field       | Value                                                                                       |
|-------------|---------------------------------------------------------------------------------------------|
| Kind        | SSH Username with Private Key                                                               |
| ID          | `flask-agent-ssh-key`                                                                       |
| Description | SSH private key for Jenkins Master to connect to the Agent                                  |
| Username    | `ubuntu`                                                                                    |
| Private Key | Select **Enter directly** → paste the full contents of `~/.ssh/id_ed25519` from the Master  |

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

The Jenkins Master and Agent are now fully connected over SSH. Any pipeline job labeled `flask-app-agent` will be routed to this Agent automatically.

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

| Field       | Value                                               |
|-------------|-----------------------------------------------------|
| Kind        | Username and Password                               |
| Username    | Your Gmail address (e.g., `yourname@gmail.com`)     |
| Password    | The 16-character App Password from above            |
| ID          | `gmail-app-password`                                |
| Description | Gmail App Password for Jenkins build notifications  |

3. Click **Create**

**Configure Extended Email Notification in Jenkins:**

1. Go to **Manage Jenkins → System**
2. Scroll down to the **Extended Email Notification** section
3. Fill in **only these four fields** and leave everything else completely blank:

| Field       | Value                        |
|-------------|------------------------------|
| SMTP Server | `smtp.gmail.com`             |
| SMTP Port   | `465`                        |
| Credentials | Select `gmail-app-password`  |
| Use SSL     | ✅ Checked                   |

4. Click **Save**

> ⚠️ **Critical:** Do NOT fill in Default Recipients, Reply-To List, Default Subject, or any other field in this section. Populating those fields will override whatever is defined in your Jenkinsfile and break email delivery.

---

### Step 11: Add GitHub and DockerHub Credentials in Jenkins

The pipeline needs credentials to pull code from GitHub and push images to DockerHub. Both are stored securely in Jenkins and referenced by their credential ID inside the Jenkinsfile.

**Add GitHub Credentials:**

1. Go to **Manage Jenkins → Credentials → System → Global credentials (unrestricted)**
2. Click **Add Credentials** and fill in:

| Field       | Value                                                      |
|-------------|------------------------------------------------------------|
| Kind        | Username and Password                                      |
| Username    | Your GitHub username                                       |
| Password    | Your GitHub Personal Access Token                          |
| ID          | `github-credentials`                                       |
| Description | GitHub credentials for accessing the Snap_Dev repository   |

3. Click **Create**

> To generate a GitHub Personal Access Token, go to **GitHub → Settings → Developer Settings → Personal Access Tokens → Tokens (classic) → Generate new token**. Select at minimum the `repo` scope and copy the token immediately — it will not be shown again.

**Add DockerHub Credentials:**

1. Still in **Global credentials**, click **Add Credentials** again and fill in:

| Field       | Value                                               |
|-------------|-----------------------------------------------------|
| Kind        | Username and Password                               |
| Username    | Your DockerHub username                             |
| Password    | Your DockerHub Personal Access Token                |
| ID          | `dockerhub-credentials`                             |
| Description | DockerHub credentials for pushing Flask app images  |

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

**General:**
- Add a description: `CI/CD pipeline for the SnapDev Flask application`

**Build Triggers:**
- ✅ Check **GitHub hook trigger for GITScm polling**

This links the GitHub webhook to this specific job. Every time GitHub sends a push event webhook to Jenkins, Jenkins will find all jobs with this option enabled and trigger them automatically.

**Pipeline:**

Change the **Definition** dropdown from `Pipeline script` to:

> **Pipeline script from SCM**

This tells Jenkins to fetch the `Jenkinsfile` directly from your GitHub repository every time the pipeline runs, meaning changes pushed to the Jenkinsfile are automatically picked up on the next build.

Fill in the fields that appear:

| Field            | Value                                              |
|------------------|----------------------------------------------------|
| SCM              | Git                                                |
| Repository URL   | `https://github.com/Deepak8260/Snap_Dev.git`       |
| Credentials      | Select `github-credentials`                        |
| Branch Specifier | `*/main`                                           |
| Script Path      | `Jenkinsfile`                                      |

Click **Save**.

---

### Step 13: Set Up the GitHub Webhook

The GitHub webhook is what makes GitHub notify Jenkins automatically on every push, triggering the pipeline without any manual action.

First, confirm that port `8080` is open to `0.0.0.0/0` on your `jenkins-master` Security Group (verify the Source is `Anywhere` and not restricted to just your IP).

Then in GitHub:

1. Go to your repository → **Settings → Webhooks → Add webhook**
2. Fill in the form:

| Field                   | Value                                                      |
|-------------------------|------------------------------------------------------------|
| Payload URL             | `http://<JENKINS-MASTER-PUBLIC-IP>:8080/github-webhook/`   |
| Content type            | `application/json`                                         |
| SSL Verification        | Disable                                                    |
| Which events to trigger | Send me everything                                         |

3. Click **Add webhook**

GitHub will immediately send a test ping to Jenkins. In the **Recent Deliveries** section of that webhook, a green tick confirms Jenkins received and responded to the ping successfully.

> ⚠️ The Payload URL must end with `/github-webhook/` **including the trailing slash**. Missing the slash is one of the most common reasons webhooks fail silently.

---

### Step 14: Trigger a Build and Verify the Full Pipeline

Everything is now configured. Trigger a build to verify the entire pipeline works end-to-end.

**Option A — Manual trigger (recommended for first run):**

Go to **Jenkins Dashboard → `flask-app-pipeline` → Build Now**. This is the safest way to confirm the pipeline works correctly before relying entirely on the webhook.

**Option B — Automatic trigger via Git push:**

Make any small change to your repository and push to GitHub:

```bash
git add .
git commit -m "Trigger test build"
git push origin main
```

The webhook fires, Jenkins picks it up within seconds, and the pipeline starts automatically.

**Monitor the build:**

Click on the build number that appears under **Build History** on the left side of the job page, then click **Console Output**. You will see live logs of every stage running on the Agent.

A successful run will show:

```
[Pipeline] stage: Clone
[Pipeline] stage: Build
[Pipeline] stage: Test
[Pipeline] stage: Deploy
Finished: SUCCESS ✅
```

Check your Gmail inbox — you should receive a build notification email confirming success, or detailing the failure if something went wrong.

---

## How the Complete Flow Works

Once everything is configured, here is exactly what happens every time you push code to GitHub:

1. **GitHub** detects the push and fires a webhook to Jenkins Master on port `8080`
2. **Jenkins Master** receives the webhook and identifies the matching pipeline job (`flask-app-pipeline`)
3. **Jenkins Master** delegates the entire pipeline to the Agent labeled `flask-app-agent` over SSH
4. **Agent** clones the latest code from the GitHub repository
5. **Agent** removes any existing Docker image named `pandu` and builds a fresh one
6. **Agent** runs the test stage
7. **Agent** stops and removes any existing container named `gandu`, then deploys the updated container with Docker on port 5000
8. **On success** → Jenkins sends an email: `SUCCESS: flask-app-pipeline #<build-number>`
9. **On failure** → Jenkins sends an email: `FAILED: flask-app-pipeline #<build-number>` with error details
10. **Jenkins Master** remains completely free throughout — it only orchestrates and never runs build work itself

---

## What the Jenkinsfile Does

The `Jenkinsfile` at the root of this repository defines the complete pipeline as code:

```groovy
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
```

**Stage-by-stage breakdown:**

| Stage    | What It Does                                                                                        |
|----------|-----------------------------------------------------------------------------------------------------|
| `clone`  | Clones the latest code from the `main` branch of this repository onto the Agent                    |
| `build`  | Removes the previous Docker image (`pandu`) if it exists, then builds a fresh image from `Dockerfile` |
| `test`   | Placeholder test stage — extend this with `pytest` or any test framework as the project grows      |
| `deploy` | Stops and removes the previous container (`gandu`) if running, then starts the updated container on port 5000 |
| `post`   | Sends an email notification via Gmail SMTP on both success and failure                              |

After making any changes to the Jenkinsfile, commit and push:

```bash
git add Jenkinsfile
git commit -m "Updated Jenkins pipeline"
git push origin main
```

This push will itself trigger the webhook and kick off a new build automatically.

---

## Final Verification Checklist

| What to Verify                   | Where to Check                                                                             |
|----------------------------------|--------------------------------------------------------------------------------------------|
| Agent is online                  | Jenkins → Manage Jenkins → Nodes → `flask-app-agent` shows **Online**                      |
| Gmail credentials saved          | Jenkins → Manage Jenkins → Credentials → Global → `gmail-app-password` exists              |
| GitHub credentials saved         | Jenkins → Manage Jenkins → Credentials → Global → `github-credentials` exists              |
| DockerHub credentials saved      | Jenkins → Manage Jenkins → Credentials → Global → `dockerhub-credentials` exists           |
| SMTP configured correctly        | Jenkins → Manage Jenkins → System → Extended Email Notification → only SMTP fields filled  |
| Pipeline job created             | Jenkins Dashboard → `flask-app-pipeline` job exists                                        |
| Build Triggers enabled           | Job config → Build Triggers → GitHub hook trigger for GITScm polling is checked            |
| SCM configured in job            | Job config → Pipeline → Definition is `Pipeline script from SCM` → points to this repo     |
| Webhook is live                  | GitHub → Repository → Settings → Webhooks → Recent Deliveries → green tick ✅               |
| Agent receives build work        | Trigger a build → Console Output shows stages running on `flask-app-agent`                 |
| Pipeline auto-triggers on push   | Push any small change to GitHub → Jenkins build starts within seconds                      |
| Docker Compose works             | Run `docker compose up -d` on the agent → container starts with name `snapcont`            |
| Multi-stage image builds         | `docker build -f Dockerfile-multi -t flask-app-mini .` → verify smaller image size         |
| Email on success                 | Check inbox after a successful build                                                       |
| Email on failure                 | Intentionally break something small, push, and verify the failure email arrives            |

---

## Troubleshooting

**Agent fails to connect**
- Confirm the public key is pasted correctly in `~/.ssh/authorized_keys` on the Agent with no extra spaces or line breaks
- Verify port `22` is open in the Agent's Security Group inbound rules
- Confirm the private key content pasted into Jenkins credentials exactly matches `~/.ssh/id_ed25519` from the Master — no extra lines or trailing spaces

**Jenkins not accessible on port 8080**
- Confirm port `8080` is open in the `jenkins-master` Security Group with Source `0.0.0.0/0`
- Check the Jenkins service is running: `sudo systemctl status jenkins`

**Port 5000 / application not accessible**
- Confirm the Security Group inbound rule for port `5000` has Source `0.0.0.0/0`
- Verify the container is running: `docker ps`

**Docker Compose command not found**
- Install the Compose plugin: `sudo apt install docker-compose-plugin -y`
- Use `docker compose` (with a space, not `docker-compose`)

**Multi-stage build fails**
- Ensure Docker has internet access to pull `gcr.io/distroless/python3-debian13`
- Confirm the `--target` flag is not used at build time; the `Dockerfile-multi` manages stages internally

**Email notifications not sending**
- Confirm 2-Step Verification was enabled on your Gmail account before the App Password was generated
- Confirm port `465` is open in the `jenkins-master` Security Group
- Confirm no extra fields (Default Recipients, Reply-To, Default Subject) are filled in the Extended Email Notification section in Jenkins

**GitHub Webhook shows a red X or 302 response**
- Confirm port `8080` is open in the `jenkins-master` Security Group with Source `Anywhere (0.0.0.0/0)`
- Confirm the Payload URL ends with `/github-webhook/` **including the trailing slash**
- In Jenkins, go to **Manage Jenkins → Security** and confirm the webhook endpoint does not require authentication

**Pipeline does not auto-trigger on push but Build Now works**
- Confirm the **GitHub hook trigger for GITScm polling** checkbox is checked inside the job's Build Triggers section
- Confirm the webhook in GitHub is pointing to the correct Jenkins URL and showing a green response in Recent Deliveries

**DockerHub push fails**
- Confirm the credential ID `dockerhub-credentials` in Jenkins matches exactly what is referenced inside the Jenkinsfile
- Confirm the DockerHub Personal Access Token has write permissions

---

> **GitHub Repository:** https://github.com/Deepak8260/Snap_Dev
