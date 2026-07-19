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