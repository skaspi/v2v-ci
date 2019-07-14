@Library('rhv-qe-jenkins-library-khakimi@add_req_ansible') _

properties(
  [
    parameters(
      [
        string(defaultValue: 'v2v-node', description: 'Name or label of slave to run on.', name: 'NODE_LABEL'),
        booleanParam(defaultValue: false, description: 'Nightly pre check.', name: 'MIQ_NIGHTLY_PRE_CHECK'),
        booleanParam(defaultValue: false, description: 'Remove existing instance.', name: 'MIQ_REMOVE_EXISTING_INSTANCE'),
        string(defaultValue: '', description: 'GE FQDN. If left empty, the FQDN will be taken from source yaml.', name: 'GE'),
        string(defaultValue: '', description: 'The name of the main YAML file e.g. v2v-1. The file placed under rhevm-jenkins/qe/v2v/', name: 'SOURCE_YAML'),
        string(defaultValue: '', description: 'Image URL e.g. http://file.cloudforms.lab.eng.rdu2.redhat.com/builds/cfme/5.10/stable/cfme-rhevm-5.10.0.33-1.x86_64.qcow2', name: 'CFME_IMAGE_URL'),
        string(defaultValue: '', description: 'RHV hosts selection, separated by a comma e.g. 1,3-5,7. Leave empty to use ALL hosts.', name: 'RHV_HOSTS'),
        string(defaultValue: '', description: 'VMware hosts selection, separated by a comma e.g. 1,3-5,7. Leave empty to use ALL hosts.', name: 'VMW_HOSTS'),
        string(defaultValue: '', description: 'The source VMware data storage type. If left empty, the type will be set accordingly to source YML file.', name: 'VMW_STORAGE_NAME'),
        string(defaultValue: '', description: 'The target RHV data storage type. If left empty, the type will be set accordingly to source YML file.', name: 'RHV_STORAGE_NAME'),
        string(defaultValue: '', description: 'The number of hosts to be migrated.', name: 'NUMBER_OF_VMS'),
        string(defaultValue: 'regression_v2v_76_100_oct_2018', description: 'VMware Template name.', name: 'VMW_TEMPLATE_NAME'),
        choice(defaultValue: 'SSH', description: 'Migration Protocol - SSH/VDDK', name: 'TRANSPORT_METHODS', choices: ['SSH', 'VDDK']),
        string(defaultValue: '20', description: 'Provider concurrent migration max num of VMs.', name: 'PROVIDER_CONCURRENT_MAX'),
        string(defaultValue: '10', description: 'Host concurrent migration max num of VMs.', name: 'HOST_CONCURRENT_MAX'),
        string(defaultValue: '', description: 'Gerrit refspec for cherry pick.', name: 'JENKINS_GERRIT_REFSPEC')
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
  script {
      def stages = [Create_VMs:true,
                    Install_Nmon:true,
                    Add_extra_providers:true,
                    Set_RHV_provider_concurrent_VM_migration_max:true,
                    Conversion_hosts_enable:true,
                    Configure_oVirt_conversion_hosts:true,
                    Configure_ESX_hosts:true,
                    Create_transformation_mappings:true,
                    Create_transformation_plans:true,
                    Start_performance_monitoring:true,
                    Execute_transformation_plans:true,
                    Monitor_transformation_plans:true,
                    Stop_performance_monitoring:true]
  }
  stages {
    stage ('Main Lock') {
      options {
        lock(resource: "${GE}")
      }
      stages {
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
            ansible(
              playbook: "miq_run_step.yml",
              extraVars: ['@extra_vars.yml', 'miq_pre_check_nightly=true'],
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
              extraVars: ['@extra_vars.yml', 'miq_pre_check=true', 'v2v_ci_miq_vm_force_remove=true'],
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
              extraVars: ['@extra_vars.yml'],
              tags: ['miq_pre_check']
            )
          }
        }

        stage ("Deploy ManageIQ/CloudForms") {
          when {
            expression { params.MIQ_REMOVE_EXISTING_INSTANCE }
          }
          steps {
            ansible(
              playbook: "miq_deploy.yml",
              extraVars: ['@extra_vars.yml'],
            )
          }
        }

        stage ('Create VMs') {
          when {
            expression ${stages.Create_VMs}
          }
          steps {
            ansible(
              playbook: 'miq_run_step.yml',
              extraVars: ['@extra_vars.yml'],
              tags: ['miq_create_vms']
            )
          }
        }

        stage ('Install Nmon') {
          steps {
            ansible(
              playbook: 'miq_run_step.yml',
              extraVars: ['@extra_vars.yml'],
              tags: ['miq_install_nmon']
            )
          }
        }

        stage ('Add extra providers') {
          steps {
            ansible(
              playbook: 'miq_run_step.yml',
              extraVars: ['@extra_vars.yml'],
              tags: ['miq_add_extra_providers']
            )
          }
        }

        stage ('Set RHV provider concurrent VM migration max') {
          steps {
            ansible(
              playbook: 'miq_run_step.yml',
              extraVars: ['@extra_vars.yml'],
              tags: ['miq_set_provider_concurrent_vm_migration_max']
            )
          }
        }

        stage ('Conversion hosts enable') {
          steps {
            ansible(
              playbook: 'miq_run_step.yml',
              extraVars: ['@extra_vars.yml'],
              tags: ['miq_conversion_hosts_ansible']
            )
          }
        }

        stage ('Configure oVirt conversion hosts') {
          steps {
            ansible(
              playbook: 'miq_run_step.yml',
              extraVars: ['@extra_vars.yml'],
              tags: ['miq_config_ovirt_conversion_hosts']
            )
          }
        }

        stage ('Configure ESX hosts') {
          steps {
            ansible(
              playbook: 'miq_run_step.yml',
              extraVars: ['@extra_vars.yml'],
              tags: ['miq_config_vmware_esx_hosts']
            )
          }
        }


        stage ('Create transformation mappings') {
          steps {
            ansible(
              playbook: 'miq_run_step.yml',
              extraVars: ['@extra_vars.yml'],
              tags: ['miq_config_infra_mappings']
            )
          }
        }

        stage ('Create transformation plans') {
          steps {
            ansible(
              playbook: 'miq_run_step.yml',
              extraVars: ['@extra_vars.yml'],
              tags: ['miq_config_migration_plan']
            )
          }
        }

        stage ('Start performance monitoring') {
          steps {
            ansible(
              playbook: 'miq_run_step.yml',
              extraVars: ['@extra_vars.yml'],
              tags: ['miq_start_monitoring']
            )
          }
        }

        stage ('Execute transformation plans') {
          steps {
            ansible(
              playbook: 'miq_run_step.yml',
              extraVars: ['@extra_vars.yml'],
              tags: ['miq_order_migration_plan']
            )
          }
        }

        stage ('Monitor transformation plans') {
          steps {
            ansible(
              playbook: 'miq_run_step.yml',
              extraVars: ['@extra_vars.yml'],
              tags: ['miq_monitor_transformations']
            )
          }
        }

        stage ('Stop performance monitoring') {
          steps {
            ansible(
              playbook: 'miq_run_step.yml',
              extraVars: ['@extra_vars.yml'],
              tags: ['miq_stop_monitoring']
            )
          }
        }
      }
    }
  }
}