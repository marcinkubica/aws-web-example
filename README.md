## **An example of load-balanced web service provisioning and deployment with Ansible and AWS**

Following Ansible playbook deploys a simple html web code (off a git repo). It will take care of provisioning Linux instances, setting up loadbalancer with security groups as well as adding your deployment box' user ssh-key and WAN IP to the cloud for ssh access.

Additionally you will be scale the deployment up or down, by adding or removing instances or tell Ansible to wipe and clean the site entirelly. Please have a look at `group_vars/frontend`file and identify any possible clash in variable names used.

### Installation
You will need a CentOS Linux box and playbooks were tested with Ansible 2.3. If you don't have CentOS to use as a deployment box you might use `Vagrant` to bring up one quickly. Probably easiest way to do so is with Oracle VirtualBox.

 - Install VirtualBox from https://www.virtualbox.org/wiki/Downloads
 - Install Vagrant from https://www.vagrantup.com/downloads.html
 - Execute in command line
```sh
vagrant init centos/7
vagrant up --provider virtualbox
vagrant ssh
```
 - You should be dropped into `vagrant@localhost` by the above
 - Git clone this repo and change directory to `aws-web-exampe/install` and run `./install-box.sh`to install required components for your deployment machine (epel, Ansible and Boto python libs for AWS)
 - Open your AWS IAM web console and generate (or reuse) your credentials. Add them to `aws_cred.sh` file and run `source ./aws_cred.sh` Ideally do it on a copy outside of the git folder for security reasons (or you might find publishing your credentials at PR or other push to github :) )
- Change your directory back to the root folder afterwards.

### Configuration
To speed-up the dynamic inventory script execution, the AWS region has been limited to `us-east-1` in file `inv/ec2.ini` To change it please also update `group_vars/frontend -> web_region`

Amount of your web instances is controlled by `group_vars/frontend -> web_count` and is initially set to 1.

Apart from the settings above there should be no other settings you would need to edit or modify for this example to work.

### Provisioning and deployment
To run this example simply execute `ansible-playbook site-create.yml` You will be notifed at the end what is your loadbalancer URL to access the website.

### Scaling up.
After changing `web_count` to a higher value you can use two ways of applying this change:

 - By re-running the main playbook `ansible-playbook site-create.yml`
 - By runing the main playbook limited to instances provisioning and web deployment only:
  - `ansible-playbook site-create.yml --tags "scale-up"`

Your newly created instances will be automatically added to the loadbalancer pool. Please note if you would have any of your previous instances in a 'stopped' state by now (ie. done manually or if they would die for some reason), the code objective is to check for instances running and any instances in a state other than running are treated as non-functional (or non-existent)

### Scaling down.
After changng `web_count` to a lower value use `ansible-playbook site-scale-down.yml`

### Wipe and clean your site
In order to completelly wipe instaces, ssh key, security groups and the loadbalancer simply run: `ansible-playbook site-delete.yml` Please note this should only remove object previously provisioned by this project. All other objects should remain intact.

### Other scenarios.
Main playbook has several roles and each of the role is accessible via tags. You can list these with `ansible-playbook site-create.yml -l`

*Updating web-code only:*
`ansible-playbook site-create.yml --tags "deploy-web"`

*Taking a web node out of loadbalancer pool:*
`ansible-playbook site-create.yml --tags "loadbalancer-register" --extra-vars "instance_id=i-03d1985a27e9c4be1 web_lb_register_state=absent"`

 - Use state 'present' to get the node back to the pool.


### Examples

*Main playbook*
```sh
$ ansible-playbook site-create.yml
 [WARNING]: provided hosts list is empty, only localhost is available


PLAY [localhost] ********************************************************************************************************************************************

TASK [security : get my WAN ip] *****************************************************************************************************************************
ok: [localhost]

TASK [security : web access security group] *****************************************************************************************************************
changed: [localhost]

TASK [security : load balancer access security group] *******************************************************************************************************
changed: [localhost]

TASK [security : web nodes ssh-key access using your ~/.ssh/id_rsa.pub] *************************************************************************************
changed: [localhost] => (item=ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC13F4x7Lz+8EmhKskGQtWmAY5q2Bj6f6Z7Eb9lShT7q2ldVLcYMQSIdBIoaT9JadlCL/aUm8K1+Rb3fWoPlXWnpsS
Qy4zNPqTi/84W3atoEYGxWg9ZIwqewuVc3AMtOZH3nmFdoMRIilLNWaJGxWEk+ckT0MAwa0jyySmDjbjVLdYBKFUpHYNxKD5nQUXbl+2I6Ger1pZxhond6wFyeGjuSECKYdeTKlSL9QECwNUhll9I41UvAtgR
/OdUIF5ymPc8R6IPlR5l9jcRR+E9HADUM6pMV7gg9H/ExQsUTdO/ffAD1BIcSyrNvXS+3F1NllGmrQpevo2VCZzgFgGopqX3 marcin@osboxes)

TASK [loadbalancer : setup] *********************************************************************************************************************************
changed: [localhost]

TASK [provision-web : instances] ****************************************************************************************************************************
changed: [localhost]

TASK [provision-web : testing ssh port state] ***************************************************************************************************************
ok: [localhost] => (item={u'kernel': None, u'root_device_type': u'ebs', u'private_dns_name': u'ip-172-31-74-172.ec2.internal', u'public_ip': u'52.91.204.18', 
u'private_ip': u'172.31.74.172', u'id': u'i-0955a674c6d47a761', u'ebs_optimized': False, u'state': u'running', u'virtualization_type': u'hvm', u'architecture
': u'x86_64', u'ramdisk': None, u'block_device_mapping': {u'/dev/sda1': {u'status': u'attached', u'delete_on_termination': True, u'volume_id': u'vol-0b59dccb
24fa38bf2'}}, u'key_name': u'web-ssh-key', u'image_id': u'ami-46c1b650', u'tenancy': u'default', u'groups': {u'sg-71430d0f': u'web-lb-security-group', u'sg-7
95e1007': u'web-servers-security-group'}, u'public_dns_name': u'ec2-52-91-204-18.compute-1.amazonaws.com', u'state_code': 16, u'tags': {u'node': u'web'}, u'p
lacement': u'us-east-1b', u'ami_launch_index': u'0', u'dns_name': u'ec2-52-91-204-18.compute-1.amazonaws.com', u'region': u'us-east-1', u'launch_time': u'201
7-05-20T23:20:51.000Z', u'instance_type': u't2.micro', u'root_device_name': u'/dev/sda1', u'hypervisor': u'xen'})

TASK [pause] ************************************************************************************************************************************************
Pausing for 15 seconds
(ctrl+C then 'C' = continue early, ctrl+C then 'A' = abort)
ok: [localhost]

PLAY [tag_node_web] *****************************************************************************************************************************************

TASK [Gathering Facts] **************************************************************************************************************************************
ok: [52.91.204.18]

TASK [common : install common packages] *********************************************************************************************************************
changed: [52.91.204.18] => (item=[u'epel-release', u'git'])

TASK [apache : install Apache] ******************************************************************************************************************************
changed: [52.91.204.18]

TASK [apache : configure SELinux for httpd] *****************************************************************************************************************
changed: [52.91.204.18]

TASK [apache : enable and start Apache] *********************************************************************************************************************
changed: [52.91.204.18]

TASK [deploy-web : ensure "/var/www/html"] ******************************************************************************************************************
ok: [52.91.204.18]

TASK [deploy-web : deploy web from "http://github.com/marcinkubica/web-code-example.git"] *******************************************************************
changed: [52.91.204.18]

TASK [loadbalancer-register : LB register] ******************************************************************************************************************
changed: [52.91.204.18 -> localhost]

PLAY [localhost] ********************************************************************************************************************************************

TASK [site-summary : get elb facts] *************************************************************************************************************************
ok: [localhost -> localhost]

TASK [site-summary : debug] *********************************************************************************************************************************
ok: [localhost] => {
    "changed": false,
    "msg": [
        "~~~",
        "Your web is loadbalanced under AWS LB at http://web-lb-183484222.us-east-1.elb.amazonaws.com",
        "~~~"
    ]
}

PLAY RECAP **************************************************************************************************************************************************
52.91.204.18               : ok=8    changed=6    unreachable=0    failed=0
localhost                  : ok=10   changed=5    unreachable=0    failed=0
```


*Scaling up*
```sh
$ ansible-playbook site-create.yml --tags "scale-up"

PLAY [localhost] ********************************************************************************************************************************************

TASK [provision-web : instances] ****************************************************************************************************************************
changed: [localhost]

TASK [provision-web : testing ssh port state] ***************************************************************************************************************
ok: [localhost] => (item={u'kernel': None, u'root_device_type': u'ebs', u'private_dns_name': u'ip-172-31-69-90.ec2.internal', u'public_ip': u'54.210.40.141',
u'private_ip': u'172.31.69.90', u'id': u'i-0e2b2dfe090fc24ce', u'ebs_optimized': False, u'state': u'running', u'virtualization_type': u'hvm', u'architecture'
: u'x86_64', u'ramdisk': None, u'block_device_mapping': {u'/dev/sda1': {u'status': u'attached', u'delete_on_termination': True, u'volume_id': u'vol-08204902a
b148efc2'}}, u'key_name': u'web-ssh-key', u'image_id': u'ami-46c1b650', u'tenancy': u'default', u'groups': {u'sg-71430d0f': u'web-lb-security-group', u'sg-79
5e1007': u'web-servers-security-group'}, u'public_dns_name': u'ec2-54-210-40-141.compute-1.amazonaws.com', u'state_code': 16, u'tags': {u'node': u'web'}, u'p
lacement': u'us-east-1b', u'ami_launch_index': u'0', u'dns_name': u'ec2-54-210-40-141.compute-1.amazonaws.com', u'region': u'us-east-1', u'launch_time': u'20
17-05-20T23:29:37.000Z', u'instance_type': u't2.micro', u'root_device_name': u'/dev/sda1', u'hypervisor': u'xen'})

TASK [pause] ************************************************************************************************************************************************
Pausing for 15 seconds
(ctrl+C then 'C' = continue early, ctrl+C then 'A' = abort)
ok: [localhost]

PLAY [tag_node_web] *****************************************************************************************************************************************

TASK [Gathering Facts] **************************************************************************************************************************************
ok: [52.91.204.18]
ok: [54.210.40.141]

TASK [common : install common packages] *********************************************************************************************************************
ok: [52.91.204.18] => (item=[u'epel-release', u'git'])
changed: [54.210.40.141] => (item=[u'epel-release', u'git'])

TASK [apache : install Apache] ******************************************************************************************************************************
ok: [52.91.204.18]
changed: [54.210.40.141]

TASK [apache : configure SELinux for httpd] *****************************************************************************************************************
ok: [52.91.204.18]
changed: [54.210.40.141]

TASK [apache : enable and start Apache] *********************************************************************************************************************
changed: [54.210.40.141]
ok: [52.91.204.18]

TASK [deploy-web : ensure "/var/www/html"] ******************************************************************************************************************
ok: [54.210.40.141]
ok: [52.91.204.18]

TASK [deploy-web : deploy web from "http://github.com/marcinkubica/web-code-example.git"] *******************************************************************
ok: [52.91.204.18]
changed: [54.210.40.141]

TASK [loadbalancer-register : LB register] ******************************************************************************************************************
ok: [52.91.204.18 -> localhost]
changed: [54.210.40.141 -> localhost]

PLAY [localhost] ********************************************************************************************************************************************

PLAY RECAP **************************************************************************************************************************************************
52.91.204.18               : ok=8    changed=0    unreachable=0    failed=0
54.210.40.141              : ok=8    changed=6    unreachable=0    failed=0
localhost                  : ok=3    changed=1    unreachable=0    failed=0
```


*Scaling down*
```sh
 $ ansible-playbook site-scale-down.yml 

PLAY [localhost] ********************************************************************************************************************************************

TASK [updating instance count to 1] *************************************************************************************************************************
changed: [localhost]

PLAY RECAP **************************************************************************************************************************************************
localhost                  : ok=1    changed=1    unreachable=0    failed=0   
```


*Wipe and clean*

```sh
$ ansible-playbook site-delete.yml 

PLAY [localhost] ********************************************************************************************************************************************

TASK [loadbalancer : setup] *********************************************************************************************************************************
changed: [localhost]

TASK [provision-web : instances] ****************************************************************************************************************************
changed: [localhost]

TASK [provision-web : testing ssh port state] ***************************************************************************************************************
ok: [localhost] => (item={u'kernel': None, u'root_device_type': u'ebs', u'private_dns_name': u'', u'public_ip': None, u'private_ip': None, u'id': u'i-0e2b2df
e090fc24ce', u'ebs_optimized': False, u'state': u'terminated', u'virtualization_type': u'hvm', u'architecture': u'x86_64', u'ramdisk': None, u'block_device_m
apping': {}, u'key_name': u'web-ssh-key', u'image_id': u'ami-46c1b650', u'tenancy': u'default', u'groups': {}, u'public_dns_name': u'', u'state_code': 48, u'
tags': {u'node': u'web'}, u'placement': u'us-east-1b', u'ami_launch_index': u'0', u'dns_name': u'', u'region': u'us-east-1', u'launch_time': u'2017-05-20T23:
29:37.000Z', u'instance_type': u't2.micro', u'root_device_name': u'/dev/sda1', u'hypervisor': u'xen'})

TASK [security : get my WAN ip] *****************************************************************************************************************************
ok: [localhost]

TASK [security : web access security group] *****************************************************************************************************************
changed: [localhost]

TASK [security : load balancer access security group] *******************************************************************************************************
changed: [localhost]

TASK [security : web nodes ssh-key access using your ~/.ssh/id_rsa.pub] *************************************************************************************
changed: [localhost] => (item=ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC13F4x7Lz+8EmhKskGQtWmAY5q2Bj6f6Z7Eb9lShT7q2ldVLcYMQSIdBIoaT9JadlCL/aUm8K1+Rb3fWoPlXWnpsSQy4zNPqTi/84W3atoEYGxWg9ZIwqewuVc3AMtO
ZH3nmFdoMRIilLNWaJGxWEk+ckT0MAwa0jyySmDjbjVLdYBKFUpHYNxKD5nQUXbl+2I6Ger1pZxhond6wFyeGjuSECKYdeTKlSL9QECwNUhll9I41UvAtgR/OdUIF5ymPc8R6IPlR5l9jcRR+E9HADUM6pMV7
gg9H/ExQsUTdO/ffAD1BIcSyrNvXS+3F1NllGmrQpevo2VCZzgFgGopqX3 marcin@osboxes)

TASK [debug] ************************************************************************************************************************************************
ok: [localhost] => {
    "changed": false, 
    "msg": [
        "~~~~~~~~~~~~~~~~~~~~~~~~~~", 
        "Site demolition completed.", 
        "~~~~~~~~~~~~~~~~~~~~~~~~~~"
    ]
}

PLAY RECAP **************************************************************************************************************************************************
localhost                  : ok=8    changed=5    unreachable=0    failed=0   


```
