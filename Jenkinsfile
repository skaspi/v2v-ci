@Library('rhv-qe-jenkins-library-khakimi@add_req_ansible') _
properties(
  [
    parameters(
      [
        string(defaultValue: 'v2v-node', description: 'Name or label of slave to run on.', name: 'NODE_LABEL'),
        string(defaultValue: '', description: 'Gerrit refspec for cherry pick', name: 'JENKINS_GERRIT_REFSPEC'),
        booleanParam(defaultValue: false, description: 'Nightly pre check', name: 'MIQ_NIGHTLY_PRE_CHECK'),
        booleanParam(defaultValue: false, description: 'Remove existing instance', name: 'MIQ_REMOVE_EXISTING_INSTANCE'),
        choice(defaultValue: 'SSH', description: 'Migration Protocol - SSH/VDDK', name: 'TRANSPORT_METHODS', choices: ['SSH', 'VDDK']),
        string(defaultValue: '', description: 'Image URL', name: 'CFME_IMAGE_URL'),
        string(defaultValue: '', description: 'The main YAML file', name: 'SOURCE_YAML'),
        string(defaultValue: '', description: 'RHV hosts selection, i.e. 1,2,3; 1-2,3; 1-3', name: 'RHV_HOSTS'),
        string(defaultValue: '', description: 'VMW hosts selection, i.e. 1,2,3; 1-2,3; 1-3', name: 'VMW_HOSTS'),
        string(defaultValue: 'NFS', description: 'The source data store type', name: 'VMW_STORAGE_TYPE', choices: ['NFS', 'ISCI', 'FC']),
        string(defaultValue: 'NFS', description: 'The target data store type', name: 'RHV_STORAGE_TYPE', choices: ['NFS', 'ISCI', 'FC']),
        string(defaultValue: 'regression_v2v_76_100_oct_2018', description: 'VMware Template name', name: 'VMW_TEMPLATE_NAME'),
        string(defaultValue: '20', description: 'Provider concurrent migration max num of VMs', name: 'PROVIDER_CONCURRENT_MAX'),
        string(defaultValue: '10', description: 'Host concurrent migration max num of VMs', name: 'HOST_CONCURRENT_MAX'),
        string(defaultValue: '', description: 'The number of hosts to be migrated', name: 'VMS_TO_MIGRATE')
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

    stage ("Generating inventory and extra_vars") {
      steps {
        sh '''
            if ["$RHV_HOSTS" = ""]; then
              RHV_HOSTS="all"
            fi
            if ["$VMW_HOSTS" = ""]; then
              VMW_HOSTS="all"
            fi

            DEST="${WORKSPACE}/jenkins"
            pushd "${DEST}"
            chmod +x ${DEST}/tools/v2v_env.py
            virtualenv yaml_generator && cd yaml_generator
            source bin/activate
            export PYTHONWARNINGS="ignore"
            pip install --upgrade pip
            python -m pip install pyyaml jinja2 pathlib
            RHV_HOSTS=`echo "$RHV_HOSTS" | awk '$1=$1'`   # removing extra spaces with awk
            VMW_HOSTS=`echo "$VMW_HOSTS" | awk '$1=$1'`
            ${DEST}/tools/v2v_env.py $SOURCE_YAML \
                                     --inventory ${DEST}/qe/v2v/inventory.yml \
                                     --extra_vars ${DEST}/qe/v2v/extra_vars.yml \
                                     --trans_method $TRANSPORT_METHODS \
                                     --image_url $CFME_IMAGE_URL \
                                     --rhv_hosts $RHV_HOSTS \
                                     --vmw_hosts $VMW_HOSTS \
                                     --vms_to_migrate $VMS_TO_MIGRATE \
                                     --provider_concurrent_max $PROVIDER_CONCURRENT_MAX \
                                     --max_concurrent_conversions $HOST_CONCURRENT_MAX \
                                     --v2v_ci_vmw_template $VMW_TEMPLATE_NAME \
                                     --v2v_ci_source_datastore $VMW_STORAGE_TYPE \
                                     --v2v_ci_target_datastore $RHV_STORAGE_TYPE \

            deactivate
            popd'''
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
