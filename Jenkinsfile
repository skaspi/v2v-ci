#!groovy

stage('Deploy MIQ Nightly') {
    node {
       ansiColor('xterm') {
           ansiblePlaybook(
            playbook: 'deploy_ci.yml',
            extras: '-e @extra_vars.yml',
            hostKeyChecking: false,
            unbuffered: true,
            colorized: true)
        }
    }
}
