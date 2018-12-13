// true/false build parameter to define if we need to run MIQ nightly pre-checks
def MIQ_NIGHTLY_PRE_CHECK = params.MIQ_NIGHTLY_PRE_CHECK
// Override default image QCOW url set on ansible
def MIQ_QCOW_URL = params.MIQ_QCOW_URL
// true/false build parameter to remove existing instance of MIQ if present/running
def MIQ_REMOVE_EXISTING_INSTANCE = params.MIQ_REMOVE_EXISTING_INSTANCE

echo "Running job ${env.JOB_NAME}, build ${env.BUILD_ID} on ${env.JENKINS_URL}"
echo "Build URL ${env.BUILD_URL}"
echo "Job URL ${env.JOB_URL}"

stage('ManageIQ/CloudForms Pre-Check') {
    node {
        
        if (MIQ_NIGHTLY_PRE_CHECK) {
            ansiColor('xterm') {
                ansiblePlaybook(
                    playbook: 'miq_run_step.yml',
                    tags: 'miq_pre_check_nightly',
                    extras: '-e "@extra_vars.yml" -e "miq_pre_check_nightly=true"',
                    hostKeyChecking: false,
                    unbuffered: true,
                    colorized: true)
            }
        }
        if (MIQ_QCOW_URL) {
            ansiColor('xterm') {
                echo "Override QCOW URL ON ansible playbook call"
            }
        }
        
        if (MIQ_REMOVE_EXISTING_INSTANCE) {
            ansiColor('xterm') {
                ansiblePlaybook(
                    playbook: 'miq_run_step.yml',
                    tags: 'miq_pre_check',
                    extras: '-e "@extra_vars.yml" -e "miq_pre_check=true" -e "v2v_ci_miq_vm_force_remove=true"',
                    hostKeyChecking: false,
                    unbuffered: true,
                    colorized: true)
            }
        }
        ansiColor('xterm') {
            ansiblePlaybook(
                playbook: 'miq_run_step.yml',
                tags: 'miq_pre_check',
                extras: '-e "@extra_vars.yml"',
                hostKeyChecking: false,
                unbuffered: true,
                colorized: true)
        }
    }
}

stage('Deploy ManageIQ/CloudForms') {
    node {
       ansiColor('xterm') {
           ansiblePlaybook(
                playbook: 'miq_deploy.yml',
                extras: '-e "@extra_vars.yml"',
                hostKeyChecking: false,
                unbuffered: true,
                colorized: true)
        }
    }
}

stage('Add extra providers') {
    node {
        ansiColor('xterm') {
            ansiblePlaybook(
                playbook: 'miq_run_step.yml',
                tags: 'miq_add_extra_providers',
                extras: '-e "@extra_vars.yml"',
                hostKeyChecking: false,
                unbuffered: true,
                colorized: true)
        }
    }
}

stage('Configure oVirt conversion hosts') {
    node {
        ansiColor('xterm') {
            ansiblePlaybook(
                playbook: 'miq_run_step.yml',
                tags: 'miq_config_ovirt_conversion_hosts',
                extras: '-e "@extra_vars.yml"',
                hostKeyChecking: false,
                unbuffered: true,
                colorized: true)
        }
    }
}

stage('Configure ESX hosts') {
    node {
        ansiColor('xterm') {
            ansiblePlaybook(
                playbook: 'miq_run_step.yml',
                tags: 'miq_config_vmware_esx_hosts',
                extras: '-e "@extra_vars.yml"',
                hostKeyChecking: false,
                unbuffered: true,
                colorized: true)
        }
    }
}


stage('Create transformation mappings') {
    node {
        ansiColor('xterm') {
            ansiblePlaybook(
                playbook: 'miq_run_step.yml',
                tags: 'miq_config_infra_mappings',
                extras: '-e "@extra_vars.yml"',
                hostKeyChecking: false,
                unbuffered: true,
                colorized: true)
        }
    }
}

stage('Create transformation plans') {
    node {
        ansiColor('xterm') {
            ansiblePlaybook(
                playbook: 'miq_run_step.yml',
                tags: 'miq_config_migration_plan',
                extras: '-e "@extra_vars.yml"',
                hostKeyChecking: false,
                unbuffered: true,
                colorized: true)
        }
    }
}

stage('Execute transformation plans') {
    node {
        ansiColor('xterm') {
            ansiblePlaybook(
                playbook: 'miq_run_step.yml',
                tags: 'miq_order_migration_plan',
                extras: '-e "@extra_vars.yml"',
                hostKeyChecking: false,
                unbuffered: true,
                colorized: true)
        }
    }
}

stage('Monitor transformation plans') {
    node {
        ansiColor('xterm') {
            ansiblePlaybook(
                playbook: 'miq_run_step.yml',
                tags: 'miq_monitor_transformations',
                extras: '-e "@extra_vars.yml"',
                hostKeyChecking: false,
                unbuffered: true,
                colorized: true)
        }
    }
}
