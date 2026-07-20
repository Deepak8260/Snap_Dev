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

def pipelineFile = new File("/home/ubuntu/Snap_Dev/jenkins/Jenkinsfile-compose")

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