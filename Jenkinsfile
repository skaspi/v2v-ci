#!groovy

stage('Pre-check MIQ Nightly') {
    node {
       ansiColor('xterm') {
           ansiblePlaybook(
            playbook: 'miq_pre_check_nightly.yml',
            extras: '-e @extra_vars.yml',
            hostKeyChecking: false,
            unbuffered: true,
            colorized: true)
        }
    }
}

stage('Deploy ManageIQ') {
    node {
       ansiColor('xterm') {
           ansiblePlaybook(
            playbook: 'deploy_miq.yml',
            extras: '-e @extra_vars.yml',
            hostKeyChecking: false,
            unbuffered: true,
            colorized: true)
        }
    }
}

stage('Configure ManageIQ extra providers') {
    node {
       ansiColor('xterm') {
           ansiblePlaybook(
            playbook: 'miq_configure.yml',
            tags: 'miq_extra_providers',
            extras: '-e @extra_vars.yml',
            hostKeyChecking: false,
            unbuffered: true,
            colorized: true)
        }
    }
}

stage('Configure ManageIQ conversion hosts') {
    node {
       ansiColor('xterm') {
           ansiblePlaybook(
            playbook: 'miq_configure.yml',
            tags: 'miq_conversion_host',
            extras: '-e @extra_vars.yml',
            hostKeyChecking: false,
            unbuffered: true,
            colorized: true)
        }
    }
}
