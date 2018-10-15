#!groovy

stage('Deploy MIQ Nightly') {
    node {
            ansiblePlaybook(
            colorized: true,
            playbook: 'deploy_ci.yml',
            extras: '-e @extra_vars.yml',
            hostKeyChecking: false,
            unbuffered: true)
        }
    }
