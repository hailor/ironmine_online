ironmine_online
===============


## vmware

1. mkdir /var/apps&&cd /var/apps
2. git clone https://github.com/hailor/ironmine_online.git
3. 复制初始化数据库脚本到/var/apps/ironmine_online/puppet/modules/ironmine/files/irm_prod_uat_2013-07-16.sql
         
         guest vm:
         mkdir /var/apps/ironmine_online/puppet/modules/ironmine/files/
         host machine:
         scp /path/irm_prod_uat_2013-07-16.sql root@xxxx.xxx.xxxx.xxxx:/var/apps/ironmine_online/puppet/modules/ironmine/files/irm_prod_uat_2013-07-16.sql
4. 使用vmware共享ironmine开发文件夹到/mnt/hgfs/ironmine,并新建链接 ln -s /mnt/hgfs/ironmine /var/apps/ironmine
5. 运行 

          chmod +x /var/apps/ironmine_online/shell/main.sh&&/var/apps/ironmine_online/shell/main.sh

## vagrant
