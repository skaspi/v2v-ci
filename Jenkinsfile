@Library('rhv-qe-jenkins-library-khakimi@add_req_ansible') _
properties(
  [
    parameters(
      [
        string(defaultValue: 'v2v-node', description: 'Name or label of slave to run on.', name: 'NODE_LABEL'),
        string(defaultValue: '', description: 'Gerrit refspec for cherry pick', name: 'JENKINS_GERRIT_REFSPEC'),
        booleanParam(defaultValue: false, description: 'Nightly pre check', name: 'MIQ_NIGHTLY_PRE_CHECK'),
        booleanParam(defaultValue: false, description: 'Remove existing instance', name: 'MIQ_REMOVE_EXISTING_INSTANCE'),
      ]
    ),
  ]
)

pipeline {
  agent {
    node {
      label params.NODE_LABEL ? params.NODE_LABEL : null
    }
  }
  stages {
    stage ("Checkout jenkins repository") {
      steps {
        checkout(
          [
            $class: 'GitSCM',
            branches: [[name: 'origin/rhevm-4.2']],
            doGenerateSubmoduleConfigurations: false,
            extensions: [
              [$class: 'RelativeTargetDirectory', relativeTargetDir: 'jenkins'],
              [$class: 'CleanBeforeCheckout'],
              [$class: 'CloneOption', depth: 0, noTags: false, reference: '', shallow: true],
              [$class: 'PruneStaleBranch']
            ],
            submoduleCfg: [],
            userRemoteConfigs: [[url: 'git://git.app.eng.bos.redhat.com/rhevm-jenkins.git']]
          ]
        )
        sh '''echo "Executed from: v2v Jenkinsfile"

        if [ -d $WORKSPACE/jenkins ]
        then
          pushd $WORKSPACE/jenkins
          echo $JENKINS_GERRIT_REFSPEC
          for ref in $JENKINS_GERRIT_REFSPEC ;
          do
            git fetch git://git.app.eng.bos.redhat.com/rhevm-jenkins.git "$ref" && git cherry-pick FETCH_HEAD || (
                echo \'!!! FAIL TO CHERRYPICK !!!\' "$ref" ; false
            )
          done
          popd
        fi
        '''
      }
    }

    stage ("ManageIQ/CloudForms Pre-Check Nightly") {
      when {
        expression { params.MIQ_NIGHTLY_PRE_CHECK }
      }
      steps {
        ansible(
          playbook: "miq_run_step.yml",
          extraVars: ['@jenkins/qe/v2v/extra_vars.yml', 'miq_pre_check_nightly=true'],
          tags: ['miq_pre_check_nightly']
        )
      }
    }

    stage ("ManageIQ/CloudForms Remove existing instance") {
      when {
        expression { params.MIQ_REMOVE_EXISTING_INSTANCE }
      }
      steps {
        ansible(
          playbook: "miq_run_step.yml",
          extraVars: ['@jenkins/qe/v2v/extra_vars.yml', 'miq_pre_check=true', 'v2v_ci_miq_vm_force_remove=true'],
          tags: ['miq_pre_check']
        )
      }
    }

    stage ("ManageIQ/CloudForms Remove Pre-Check") {
      when {
        expression { params.MIQ_REMOVE_EXISTING_INSTANCE }
      }
      steps {
        ansible(
          playbook: "miq_run_step.yml",
          extraVars: ['@jenkins/qe/v2v/extra_vars.yml'],
          tags: ['miq_pre_check']
        )
      }
    }

    stage ("Deploy ManageIQ/CloudForms") {
      steps {
        ansible(
          playbook: "miq_deploy.yml",
          extraVars: ['@jenkins/qe/v2v/extra_vars.yml'],
        )
      }
    }

    stage ('Create VMs') {
      steps {
        ansible(
          playbook: 'miq_run_step.yml',
          extraVars: ['@jenkins/qe/v2v/extra_vars.yml'],
          tags: ['miq_create_vms']
        )
      }
    }

    stage ('Install Nmon') {
      steps {
        ansible(
          playbook: 'miq_run_step.yml',
          extraVars: ['@jenkins/qe/v2v/extra_vars.yml'],
          tags: ['miq_install_nmon']
        )
      }
    }

    stage ('Add extra providers') {
      steps {
        ansible(
          playbook: 'miq_run_step.yml',
          extraVars: ['@jenkins/qe/v2v/extra_vars.yml'],
          tags: ['miq_add_extra_providers']
        )
      }
    }

    stage ('Set RHV provider concurrent VM migration max') {
      steps {
        ansible(
          playbook: 'miq_run_step.yml',
          extraVars: ['@jenkins/qe/v2v/extra_vars.yml'],
          tags: ['miq_set_provider_concurrent_vm_migration_max']
        )
      }
    }

    stage ('Conversion hosts enable') {
      steps {
        ansible(
          playbook: 'miq_run_step.yml',
          extraVars: ['@jenkins/qe/v2v/extra_vars.yml'],
          tags: ['miq_conversion_hosts_ansible']
        )
      }
    }

    stage ('Configure oVirt conversion hosts') {
      steps {
        ansible(
          playbook: 'miq_run_step.yml',
          extraVars: ['@jenkins/qe/v2v/extra_vars.yml'],
          tags: ['miq_config_ovirt_conversion_hosts']
        )
      }
    }

    stage ('Configure ESX hosts') {
      steps {
        ansible(
          playbook: 'miq_run_step.yml',
          extraVars: ['@jenkins/qe/v2v/extra_vars.yml'],
          tags: ['miq_config_vmware_esx_hosts']
        )
      }
    }


    stage ('Create transformation mappings') {
      steps {
        ansible(
          playbook: 'miq_run_step.yml',
          extraVars: ['@jenkins/qe/v2v/extra_vars.yml'],
          tags: ['miq_config_infra_mappings']
        )
      }
    }

    stage ('Create transformation plans') {
      steps {
        ansible(
          playbook: 'miq_run_step.yml',
          extraVars: ['@jenkins/qe/v2v/extra_vars.yml'],
          tags: ['miq_config_migration_plan']
        )
      }
    }

    stage ('Start performance monitoring') {
      steps {
        ansible(
          playbook: 'miq_run_step.yml',
          extraVars: ['@jenkins/qe/v2v/extra_vars.yml'],
          tags: ['miq_start_monitoring']
        )
      }
    }

    stage ('Execute transformation plans') {
      steps {
        ansible(
          playbook: 'miq_run_step.yml',
          extraVars: ['@jenkins/qe/v2v/extra_vars.yml'],
          tags: ['miq_order_migration_plan']
        )
      }
    }

    stage ('Monitor transformation plans') {
      steps {
        ansible(
          playbook: 'miq_run_step.yml',
          extraVars: ['@jenkins/qe/v2v/extra_vars.yml'],
          tags: ['miq_monitor_transformations']
        )
      }
    }

    stage ('Stop performance monitoring') {
      steps {
        ansible(
          playbook: 'miq_run_step.yml',
          extraVars: ['@jenkins/qe/v2v/extra_vars.yml'],
          tags: ['miq_stop_monitoring']
        )
      }
    }
  }
}
