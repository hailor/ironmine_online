ironmine_online
===============


## vmware

1. mkdir /var/apps&&cd /var/apps
2. git clone git@github.com:hailor/ironmine_online.git
3. 复制初始化数据库脚本到/var/apps/ironmine_online/puppet/modules/ironmine/files/irm_prod_uat_2013-07-16.sql
4. 安装vmtools
5. 使用vmware共享ironmine开发文件夹到/mnt/hgfs/ironmine,并新建链接 ln -s /mnt/hgfs/ironmine /var/apps/ironmine
6. 运行 /var/apps/ironmine_online/puppet/shell/main.sh

## vagrant
