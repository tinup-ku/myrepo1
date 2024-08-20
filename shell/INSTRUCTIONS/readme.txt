#########################################
HOW TO UPDATE splunk_extract in Bitbucket.08/24/2022
#########################################
tos_splunk_core/tools/splunkHadoopExtracts/bin/splunk_extract
-----------------------------------------------------------------------------------
root@svm0966cdc ~/bitbucket/jasper.dang -> git clone https://bitbucket.schwab.com/scm/AD00203364/tos_splunk_apps.git
-----------------------------------------------------------------------------------
https://bitbucket.schwab.com/projects/AD00203364/repos/tos_splunk_core/
root@svm0966cdc ~/bitbucket/jasper.dang -> git clone https://bitbucket.schwab.com/scm/AD00203364/tos_splunk_core.git
Cloning into 'tos_splunk_core'...
Username for 'https://bitbucket.schwab.com': jasper.dang
Password for 'https://jasper.dang@bitbucket.schwab.com':

Then
cd /root/bitbucket/jasper.dang/tos_splunk_core/tools/splunkHadoopExtracts/bin


https://bitbucket.schwab.com/projects/AD00203364/repos/tos_splunk_apps/browse/prod/index/apps.git
https://bitbucket.schwab.com/scm/AD00203364/tos_kafkaconnect.git
https://bitbucket.schwab.com/scm/AD00203364/tos_kafkaconnect/prod.git
Then
cd /root/bitbucket/jasper.dang
git clone https://bitbucket.schwab.com/scm/AD00203364/tos_kafkaconnect.git

2/1/2022: How to clone tos_splunk_apps
git clone https://bitbucket.schwab.com/scm/AD00203364/tos_splunk_apps.git
or
git clone https://bitbucket.schwab.com/scm/AD00203364/tos_splunk_apps

6/1/2022: push_bundle/push_lookups
git clone https://bitbucket.schwab.com/scm/AD00203364/tos_splunk_core.git


https://bitbucket.schwab.com/projects/AD00203364/repos/tos_kafkaconnect/browse/prod/pcf-logs/pcf-connector-configs/pcf-org-name-splunk-index-config.json

1. Login to Steve Salt master, cud1-008918.us.global.schwab.com, and identify bitbucket url in /etc/salt/master:
   https://bitbucket.schwab.com/scm/ad00203364/tos_syslog.git

2. Go to https://bitbucket.schwab.com/scm/ad00203364/tos_syslog.git

   In Source dropdown, choose dev

   Output:
   a. You should see 
      conf.d
      README.md
      syslog-ng.conf

3. On the left hand side of https://bitbucket.schwab.com/scm/ad00203364/tos_syslog.git
   click on "Create branch"

   You will see
   
   Repository: TOS-Splunk/tos-syslog
   In Branch type dropdown, choose Feature
   In Branch from dropdown, choose dev
   In Branch name, after feature/, enter HEC_ITRS_TE_Coveo

   Click "Create branch" button

   Now you'll see https://bitbucket.schwab.com/projects/AD00203364/repos/tos_splunk_apps/browse?at=refs%2Fheads%2Ffeature%2FHEC_ITRS_TE_Coveo

   Under Source, you will see
   
   feature/HEC_ITRS_TE_Coveo

4. On svm0966cdc
   cd /root/bitbucket
   mkdir jasper.dang
   cd jasper.dang
   [root@svm0966cdc jasper.dang]# git clone https://bitbucket.schwab.com/scm/AD00203364/tos_splunk_apps.git

Output:
------- cut here ------
Cloning into 'tos_syslog'...
Password for 'https://jasper.dang@bitbucket.schwab.com':
remote: Enumerating objects: 111, done.
remote: Counting objects: 100% (111/111), done.
remote: Compressing objects: 100% (111/111), done.
remote: Total 111 (delta 56), reused 0 (delta 0)
Receiving objects: 100% (111/111), 16.00 KiB | 0 bytes/s, done.
Resolving deltas: 100% (56/56), done.
------- cut here ------

[root@svm0966cdc jasper.dang]# pwd
/root/bitbucket/jasper.dang
[root@svm0966cdc jasper.dang]# ls -l
total 0
drwxr-xr-x 4 root root 67 Jun 24 15:04 tos_syslog

vi /root/bitbucket/jasper.dang/tos_syslog/.git/config, and add stanza below

[user]
        name = Dang, Jasper
        email = jasper.dang@schwab.com

5. git branch
Output:
[root@svm0966cdc conf.d]# git branch
* master

Note: We need to make sure it's in dev as described in Step 3 above.

[root@svm0966cdc tos_syslog]# git checkout -q dev 

[root@svm0966cdc tos_syslog]# git pull
Password for 'https://jasper.dang@bitbucket.schwab.com':
Already up-to-date.

[root@svm0966cdc tos_syslog]# git branch
* dev
  master
[root@svm0966cdc tos_syslog]# git checkout -q feature/TOS-10382
05/13/2022:
If in release
git checkout -q release/TOS-11361

Verify the branch is correct:

[root@svm0966cdc tos_syslog]# git branch
  dev
* feature/TOS-10382
  master
[root@svm0966cdc tos_syslog]# git pull
Password for 'https://jasper.dang@bitbucket.schwab.com':
Already up-to-date.

conf.d  README.md  syslog-ng.conf
[root@svm0966cdc tos_syslog]# cd conf.d
[root@svm0966cdc conf.d]# ls
ca-cem.conf   ciscoSyslog.conf  netcool_syslog.conf  system.conf
ciscofw.conf  f5.conf           paloalto.conf

Now copy from syslog-ng DEV, svm2505pdv to current directory

[root@svm0966cdc conf.d]# scp svm2505pdv:/etc/syslog-ng/conf.d/nas_storage.conf . 2>/dev/null


root@svm0966cdc conf.d]# ls -ltr
total 32
-rw-r--r-- 1 root root 3249 Jun 24 15:33 system.conf
-rw-r--r-- 1 root root 1582 Jun 24 15:33 paloalto.conf
-rw-r--r-- 1 root root 1289 Jun 24 15:33 netcool_syslog.conf
-rw-r--r-- 1 root root 1253 Jun 24 15:33 f5.conf
-rw-r--r-- 1 root root 1648 Jun 24 15:33 ciscoSyslog.conf
-rw-r--r-- 1 root root 1048 Jun 24 15:33 ciscofw.conf
-rw-r--r-- 1 root root  793 Jun 24 15:33 ca-cem.conf
-rw-r--r-- 1 root root 3593 Jun 24 15:37 nas_storage.conf

[root@svm0966cdc conf.d]# git add * && git commit -am "Adding file for TOS-10382|nas_storage.conf"

[feature/TOS-10382 1926ac9] Adding file for TOS-10382|nas_storage.conf

 1 file changed, 84 insertions(+)
 create mode 100644 conf.d/nas_storage.conf

[root@svm0966cdc conf.d]# git push
Password for 'https://jasper.dang@bitbucket.schwab.com':
Counting objects: 6, done.
Delta compression using up to 12 threads.
Compressing objects: 100% (4/4), done.
Writing objects: 100% (4/4), 1.66 KiB | 0 bytes/s, done.
Total 4 (delta 1), reused 0 (delta 0)
remote:
remote: Create pull request for feature/TOS-10382:
remote:   https://bitbucket.schwab.com/projects/AD00203364/repos/tos_syslog/pull-requests?create&sourceBranch=refs/heads/feature/TOS-10382
remote:

To https://jasper.dang@bitbucket.schwab.com/scm/ad00203364/tos_syslog.git
   70022fd..1926ac9  feature/TOS-10382 -> feature/TOS-10382


Then go to https://bitbucket.schwab.com/scm/ad00203364/tos_syslog.git to create pull request 

Then merge.

Once committed goto bitbucket.schwab.com , and 
1. ON LHS click on 3rd icon, Create Pull Request
2. Hit COntinue
3. Click on Create

See this link as an example

https://confluence.schwab.com/pages/viewpage.action?spaceKey=TOS&title=OpsEng+Guide%3A+On-boarding+Syslog+Event+Sources


- HOW TO DELETE A BRANCH:
[root@svm0966cdc tos_splunk_core]# git branch
* feature/Push_bundle_lookups
  stable

[root@svm0966cdc tos_splunk_core]# git push origin --delete feature/Push_bundle_lookups
Username for 'https://bitbucket.schwab.com': jasper.dang
Password for 'https://jasper.dang@bitbucket.schwab.com':
To https://bitbucket.schwab.com/scm/AD00203364/tos_splunk_core.git
 - [deleted]         feature/Push_bundle_lookups

- HOW TO SHOW ALL BRANCHES
[root@svm0966cdc tos_splunk_core]# git branch -r
  origin/HEAD -> origin/stable
  origin/Update_push_bundle_lookups
  origin/feature/IRE-1384-AccountMaintenance-support-ord188067-michelle-monteith
  origin/feature/SDM-10102-voice-secure-logs
  origin/feature/SDM-10665-clientservicing-secureroles-config
  origin/feature/SDM-12040-sje-secure-logs
  origin/feature/SDM-12312-sdm_consultations_general-secure-logs
  origin/feature/SDM-14329-update-crt_distributed-sourcetype
  origin/feature/SDM-14633-sdm_consultations_reports-1228876-702796-hari-earlapati
  origin/feature/SDM-15058-secure-logs-clientservicing
  origin/feature/SDM-15262-sdm_update-AD-group-CDMT
  origin/feature/SDM-17415-update-advisorservices-securelogging
  origin/feature/SDM-17415-update-secure-logging-advisor-services
  origin/feature/SDM-238-SchwabCom-support-ord208914-trevor-chalstrom
  origin/feature/SDM-2963-support-ord290229-sreedhar-yalavarthy
  origin/feature/SDM-6286-create-00-core-sh-app
  origin/feature/SDM-6903-fix-secure-role-cdmt-secure
  origin/feature/SDM-7961-update-BDE-sourcetype
  origin/feature/SDM-9549-updating-authentication-srchfilter
  origin/feature/TOS-7681-fields-for-sourcetype-netscreen-firewall-not-extracted-in-telecom-app
  origin/feature/shapp_update_11_17
  origin/hassanbhatti/authorize.conf-1633729197201
  origin/master
  origin/sairamgade/authorize.conf-1594320223832
  origin/stable

Steps:
[root@svm0966cdc tos_splunk_core]# git branch
* feature/Push_bundle_lookups
  stable

[root@svm0966cdc tos_splunk_core]# git checkout stable
Switched to branch 'stable'
[root@svm0966cdc tos_splunk_core]# git branch
  feature/Push_bundle_lookups
* stable

[root@svm0966cdc tos_splunk_core]# git branch -D feature/Push_bundle_lookups
Deleted branch feature/Push_bundle_lookups (was baf5b06).
[root@svm0966cdc tos_splunk_core]# git branch
* stable
####################################################################

1. git clone https://bitbucket.schwab.com/scm/AD00203364/tos_splunk_core.git

2. To create a branch from master:
git checkout -b release/TOS-18536

Verify:
root@svm0966cdc ~/bitbucket/jasper.dang/tos_splunk_core/tools ->  git branch
* feature/TOS-18536
  stable

3. Updated push_bundle and push_lookup

4. root@svm0966cdc ~/bitbucket/jasper.dang/tos_splunk_core/tools -> git add * && git commit -am "TOS-18536: Revised 1. push_bundle to replace Search peer with SH captain, and 2. push_lookups to include RestAPI SH Deployer"
[feature/TOS-18536 ccae9d2] TOS-18536: Revised 1. push_bundle to replace Search peer with SH captain, and 2. push_lookups to include RestAPI SH Deployer
 2 files changed, 223 insertions(+), 119 deletions(-)
 rewrite tools/push_lookups (78%)

5. Create a pull request:
root@svm0966cdc ~/bitbucket/jasper.dang/tos_splunk_core/tools -> git push
warning: push.default is unset; its implicit value is changing in
Git 2.0 from 'matching' to 'simple'. To squelch this message
and maintain the current behavior after the default changes, use:

  git config --global push.default matching

To squelch this message and adopt the new behavior now, use:

  git config --global push.default simple

See 'git help config' and search for 'push.default' for further information.
(the 'simple' mode was introduced in Git 1.7.11. Use the similar mode
'current' instead of 'simple' if you sometimes use older versions of Git)

Username for 'https://bitbucket.schwab.com': jasper.dang
Password for 'https://jasper.dang@bitbucket.schwab.com':
Counting objects: 9, done.
Delta compression using up to 12 threads.
Compressing objects: 100% (5/5), done.
Writing objects: 100% (5/5), 2.80 KiB | 0 bytes/s, done.
Total 5 (delta 3), reused 0 (delta 0)
remote:
remote: Create pull request for feature/TOS-18536:
remote:   https://bitbucket.schwab.com/projects/AD00203364/repos/tos_splunk_core/pull-requests?create&sourceBranch=refs%2Fheads%2Ffeature%2FTOS-18536
remote:
To https://bitbucket.schwab.com/scm/AD00203364/tos_splunk_core.git
   7c81927..ccae9d2  feature/TOS-18536 -> feature/TOS-18536


6. From 5. go to
 https://bitbucket.schwab.com/projects/AD00203364/repos/tos_splunk_core/pull-requests?create&sourceBranch=refs%2Fheads%2Ffeature%2FTOS-18536

and verify the diff

7. Get approval and merge back to stable by sending Gerry/Puni/Loren:
 https://bitbucket.schwab.com/projects/AD00203364/repos/tos_splunk_core/pull-requests?create&sourceBranch=refs%2Fheads%2Ffeature%2FTOS-18536


Note:
In 7. you can run from the command line

root@svm0966cdc ~/bitbucket/jasper.dang/tos_splunk_core/tools -> git show
commit ccae9d228458fc3d5d0a692f32d4d221c0c0f9ac
Author: Punit Kumar <punit.kumar@schwab.com>
Date:   Mon Feb 27 12:17:19 2023 -0500

    TOS-18536: Revised 1. push_bundle to replace Search peer with SH captain, and 2. push_lookups to include RestA

diff --git a/tools/push_bundle b/tools/push_bundle
index 0ab6ae6..fd18668 100644
--- a/tools/push_bundle
+++ b/tools/push_bundle
...
...
...

diff --git a/tools/push_lookups b/tools/push_lookups
index 079cbd7..cc7e6d3 100644
--- a/tools/push_lookups
+++ b/tools/push_lookups

For example: 
1. push_bundle diff:
root@svm0966cdc ~/bitbucket/jasper.dang/tos_splunk_core/tools -> git diff 0ab6ae6 fd18668
diff --git a/0ab6ae6 b/fd18668
index 0ab6ae6..fd18668 100644


2. push_lookups diff:
root@svm0966cdc ~/bitbucket/jasper.dang/tos_splunk_core/tools -> git diff 079cbd7 cc7e6d3
diff --git a/079cbd7 b/cc7e6d3
index 079cbd7..cc7e6d3 100644
--- a/079cbd7
+++ b/cc7e6d3

