@Library(['rhv-qe-jenkins-library@master']) _

properties(
  [
    parameters(
      [
        string(defaultValue: 'v2v-node', description: 'Name or label of slave to run on', name: 'NODE_LABEL'),
        booleanParam(defaultValue: false, description: 'Nightly pre check', name: 'MIQ_NIGHTLY_PRE_CHECK'),
        booleanParam(defaultValue: false, description: 'Remove existing instance', name: 'MIQ_REMOVE_EXISTING_INSTANCE'),
        string(defaultValue: '', description: 'GE FQDN. If left empty, the FQDN will be taken from source yaml', name: 'GE'),
        string(defaultValue: '', description: 'The name of the main YAML file e.g. v2v-1. The file placed under rhevm-jenkins/qe/v2v/', name: 'SOURCE_YAML'),
        string(defaultValue: '', description: 'Image URL e.g. http://file.cloudforms.lab.eng.rdu2.redhat.com/builds/cfme/5.10/stable/cfme-rhevm-5.10.0.33-1.x86_64.qcow2', name: 'CFME_IMAGE_URL'),
        string(defaultValue: '', description: 'RHV hosts selection, separated by a comma e.g. 1,3-5,7. Leave empty to use ALL hosts', name: 'RHV_HOSTS'),
        string(defaultValue: '', description: 'VMware hosts selection, separated by a comma e.g. 1,3-5,7. Leave empty to use ALL hosts', name: 'VMW_HOSTS'),
        string(defaultValue: '', description: 'The source VMware data storage type. If left empty, the type will be set accordingly to source YML file', name: 'VMW_STORAGE_NAME'),
        string(defaultValue: '', description: 'The target RHV data storage type. If left empty, the type will be set accordingly to source YML file', name: 'RHV_STORAGE_NAME'),
        string(defaultValue: '', description: 'The number of hosts to be migrated', name: 'NUMBER_OF_VMS'),
        string(defaultValue: 'regression_v2v_76_100_oct_2018', description: 'VMware Template name', name: 'VMW_TEMPLATE_NAME'),
        choice(defaultValue: 'VDDK', description: 'Migration Protocol - SSH/VDDK', name: 'TRANSPORT_METHODS', choices: ['VDDK', 'SSH']),
        string(defaultValue: '20', description: 'Provider concurrent migration max num of VMs', name: 'PROVIDER_CONCURRENT_MAX'),
        string(defaultValue: '10', description: 'Host concurrent migration max num of VMs', name: 'HOST_CONCURRENT_MAX'),
        choice(defaultValue: 'Create VMs', description: 'Specify a stage to run from', name: 'START_FROM_STAGE', choices: ['Create VMs', 'Install Nmon', 'Add extra providers', 'Set RHV provider concurrent VM migration max', 'Configure oVirt conversion hosts', 'Configure ESX hosts', 'vmware hosts set public key', 'Conversion hosts enable', 'Create transformation mappings', 'Create transformation plans', 'Start performance monitoring', 'Execute transformation plans', 'Monitor transformation plans']),
        booleanParam(defaultValue: false, description: 'If checked, this will be the ONLY stage to run', name: 'SINGLE_STAGE'),
        choice(defaultValue: '', description: 'Specify the verbosity level of running stages', name: 'VERBOSITY_LEVEL', choices: ['', '-v', '-vv', '-vvv']),
        string(defaultValue: '', description: 'Gerrit refspec for cherry pick', name: 'JENKINS_GERRIT_REFSPEC')
      ]
    ),
  ]
)

def stages_ = other.get_v2v_current_stage(params.START_FROM_STAGE, params.SINGLE_STAGE)

pipeline {
  agent {
    node {
      label params.NODE_LABEL ? params.NODE_LABEL : null
    }
  }
  stages {
    stage ('Main Stage') {
      options {
        lock(resource: "${GE}")
      }
      stages {
        stage ('Locked Resources') {
          steps {
            script {
              log.info("Locked resources: ${GE}")
            }
          }
        }
        stage ("Checkout jenkins repository") {
          steps {
            checkout(
              [
                $class: 'GitSCM',
                branches: [[name: 'origin/master']],
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

        stage ("Generating inventory and extra_vars") {
          steps {
            sh '''
                rm -rf yaml_generator
                virtualenv yaml_generator
                source yaml_generator/bin/activate
                pip install --upgrade pip
                pip install pyyaml jinja2 pathlib
                ${WORKSPACE}/jenkins/tools/v2v/v2v_env.py $SOURCE_YAML \
                                                        --inventory  ${WORKSPACE}/jenkins/qe/v2v/inventory \
                                                        --extra_vars ${WORKSPACE}/extra_vars.yml \
                                                        --trans_method $TRANSPORT_METHODS \
                                                        --image_url $CFME_IMAGE_URL \
                                                        --rhv_hosts "$RHV_HOSTS" \
                                                        --vmw_hosts "$VMW_HOSTS" \
                                                        --number_of_vms $NUMBER_OF_VMS \
                                                        --provider_concurrent_max $PROVIDER_CONCURRENT_MAX \
                                                        --host_concurrent_max $HOST_CONCURRENT_MAX \
                                                        --v2v_ci_vmw_template $VMW_TEMPLATE_NAME \
                                                        --v2v_ci_source_datastore "$VMW_STORAGE_NAME" \
                                                        --v2v_ci_target_datastore "$RHV_STORAGE_NAME" \
                                                        --job_basename_url $JOB_BASE_NAME \
                                                        --rhv_ge "$GE"

                deactivate
                '''
          }
        }

        stage ("ManageIQ/CloudForms Pre-Check Nightly") {
          when {
            expression { params.MIQ_NIGHTLY_PRE_CHECK }
          }
          steps {
            v2v_ansible(
              playbook: "miq_run_step.yml",
              extraVars: ['@extra_vars.yml', 'miq_pre_check_nightly=true'],
              tags: ['miq_pre_check_nightly'],
              verbosity: params.VERBOSITY_LEVEL
            )
          }
        }

        stage ("ManageIQ/CloudForms Remove existing instance") {
          when {
            expression { params.MIQ_REMOVE_EXISTING_INSTANCE }
          }
          steps {
            v2v_ansible(
              playbook: "miq_run_step.yml",
              extraVars: ['@extra_vars.yml', 'miq_pre_check=true', 'v2v_ci_miq_vm_force_remove=true'],
              tags: ['miq_pre_check'],
              verbosity: params.VERBOSITY_LEVEL
            )
          }
        }

        stage ("ManageIQ/CloudForms Remove Pre-Check") {
          when {
            expression { params.MIQ_REMOVE_EXISTING_INSTANCE }
          }
          steps {
            v2v_ansible(
              playbook: "miq_run_step.yml",
              extraVars: ['@extra_vars.yml'],
              tags: ['miq_pre_check'],
              verbosity: params.VERBOSITY_LEVEL
            )
          }
        }

        stage ("Deploy ManageIQ/CloudForms") {
          when {
            expression { params.MIQ_REMOVE_EXISTING_INSTANCE }
          }
          steps {
            v2v_ansible(
              playbook: "miq_deploy.yml",
              extraVars: ['@extra_vars.yml'],
              verbosity: params.VERBOSITY_LEVEL
            )
          }
        }

        stage ('Create VMs') {
          when {
            expression { stages_['Create VMs'] }
          }
          steps {
            v2v_ansible(
              playbook: 'miq_run_step.yml',
              extraVars: ['@extra_vars.yml'],
              tags: ['miq_create_vms'],
              verbosity: params.VERBOSITY_LEVEL
            )
          }
        }

        stage ('Install Nmon') {
          when {
            expression { stages_['Install Nmon'] }
          }
          steps {
            v2v_ansible(
              playbook: 'miq_run_step.yml',
              extraVars: ['@extra_vars.yml'],
              tags: ['miq_install_nmon'],
              verbosity: params.VERBOSITY_LEVEL
            )
          }
        }

        stage ('Add extra providers') {
          when {
            expression { stages_['Add extra providers'] }
          }
          steps {
            v2v_ansible(
              playbook: 'miq_run_step.yml',
              extraVars: ['@extra_vars.yml'],
              tags: ['miq_add_extra_providers'],
              verbosity: params.VERBOSITY_LEVEL
            )
          }
        }

        stage ('Set RHV provider concurrent VM migration max') {
          when {
            expression { stages_['Set RHV provider concurrent VM migration max'] }
          }
          steps {
            v2v_ansible(
              playbook: 'miq_run_step.yml',
              extraVars: ['@extra_vars.yml'],
              tags: ['miq_set_provider_concurrent_vm_migration_max'],
              verbosity: params.VERBOSITY_LEVEL
            )
          }
        }

        stage ('Configure oVirt conversion hosts') {
          when {
            expression { stages_['Configure oVirt conversion hosts'] }
          }
          steps {
            v2v_ansible(
              playbook: 'miq_run_step.yml',
              extraVars: ['@extra_vars.yml'],
              tags: ['miq_config_ovirt_conversion_hosts'],
              verbosity: params.VERBOSITY_LEVEL
            )
          }
        }

        stage ('Configure ESX hosts') {
          when {
            expression { stages_['Configure ESX hosts'] }
          }
          steps {
            v2v_ansible(
              playbook: 'miq_run_step.yml',
              extraVars: ['@extra_vars.yml'],
              tags: ['miq_config_vmware_esx_hosts'],
              verbosity: params.VERBOSITY_LEVEL
            )
          }
        }

        stage ('vmware hosts set public key') {
          when {
            expression { stages_['vmware hosts set public key'] }
          }
          steps {
            v2v_ansible(
              playbook: 'miq_run_step.yml',
              extraVars: ['@extra_vars.yml'],
              tags: ['vmware_hosts_set_public_key'],
              verbosity: params.VERBOSITY_LEVEL
            )
          }
        }

        stage ('Conversion hosts enable') {
          when {
            expression { stages_['Conversion hosts enable'] }
          }
          steps {
            v2v_ansible(
              playbook: 'miq_run_step.yml',
              extraVars: ['@extra_vars.yml'],
              tags: ['miq_conversion_hosts_enable'],
              verbosity: params.VERBOSITY_LEVEL
            )
          }
        }

        stage ('Create transformation mappings') {
          when {
            expression { stages_['Create transformation mappings'] }
          }
          steps {
            v2v_ansible(
              playbook: 'miq_run_step.yml',
              extraVars: ['@extra_vars.yml'],
              tags: ['miq_config_infra_mappings'],
              verbosity: params.VERBOSITY_LEVEL
            )
          }
        }

        stage ('Create transformation plans') {
          when {
            expression { stages_['Create transformation plans'] }
          }
          steps {
            v2v_ansible(
              playbook: 'miq_run_step.yml',
              extraVars: ['@extra_vars.yml'],
              tags: ['miq_config_migration_plan'],
              verbosity: params.VERBOSITY_LEVEL
            )
          }
        }

        stage ('Start performance monitoring') {
          when {
            expression { stages_['Start performance monitoring'] }
          }
          steps {
            v2v_ansible(
              playbook: 'miq_run_step.yml',
              extraVars: ['@extra_vars.yml'],
              tags: ['miq_start_monitoring'],
              verbosity: params.VERBOSITY_LEVEL
            )
          }
        }

        stage ('Execute transformation plans') {
          when {
            expression { stages_['Execute transformation plans'] }
          }
          steps {
            v2v_ansible(
              playbook: 'miq_run_step.yml',
              extraVars: ['@extra_vars.yml'],
              tags: ['miq_order_migration_plan'],
              verbosity: params.VERBOSITY_LEVEL
            )
          }
        }

        stage ('Monitor transformation plans') {
          when {
            expression { stages_['Monitor transformation plans'] }
          }
          steps {
            v2v_ansible(
              playbook: 'miq_run_step.yml',
              extraVars: ['@extra_vars.yml'],
              tags: ['miq_monitor_transformations'],
              verbosity: params.VERBOSITY_LEVEL
            )
          }
        }
      }
      post {
        always {
            v2v_ansible(
              playbook: 'miq_run_step.yml',
              extraVars: ['@extra_vars.yml'],
              tags: ['miq_stop_monitoring'],
              verbosity: params.VERBOSITY_LEVEL
            )
            script {
              def JOB_URL = "${JOB_BASE_NAME}"
              if (JOB_URL.contains('prod')) {
                archiveArtifacts artifacts: 'cfme_logs/*.tar.gz'
                archiveArtifacts artifacts: 'conv_logs/*.tar.gz'
              }
            }
        }
      }
    }
  }
}