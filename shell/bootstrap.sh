#!/bin/sh

# Directory in which librarian-puppet should manage its modules directory
PUPPET_DIR=/vagrant/puppet/

# NB: librarian-puppet might need git installed. If it is not already installed
# in your basebox, this will manually install it at this point using apt or yum
GIT=/usr/bin/git
APT_GET=/usr/bin/apt-get
YUM=/usr/bin/yum

if [ -x $YUM ]; then
    if [ ! "`rpm -q epel-release-6-8.noarch`" = "epel-release-6-8.noarch" ];then
          rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
          rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6
    fi

    if [ ! "`rpm -q rpmforge-release-0.5.3-1.el6.rf.x86_64`" = "rpmforge-release-0.5.3-1.el6.rf.x86_64" ];then
          rpm -Uvh http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm
          rpm --import http://apt.sw.be/RPM-GPG-KEY.dag.txt
    fi

    yum -q -y makecache
    yum -q -y install  ruby-devel rubygems
    yum -q -y groupinstall "Development Tools"
fi
if [ ! -x $GIT ]; then
    if [ -x $YUM ]; then
        yum -q -y makecache
        yum -q -y install git-core
    elif [ -x $APT_GET ]; then
        apt-get -q -y update
        apt-get -q -y install git
    else
        echo "No package installer available. You may need to install git manually."
    fi
fi

command -v puppet >/dev/null 2>&1 || {
    if [ -x $YUM ]; then
        if [ ! "`rpm -q puppetlabs-release-6-7.noarch`" = "puppetlabs-release-6-7.noarch" ];then
          rpm -ivh http://yum.puppetlabs.com/el/6/products/i386/puppetlabs-release-6-7.noarch.rpm
        fi
        yum -q -y makecache
        yum -q -y install puppet
    elif [ -x $APT_GET ]; then
        CODENAME="$(lsb_release -cs)"
        dpkg -L puppetlabs-release  2>/dev/null||{
          cd /tmp
          wget http://apt.puppetlabs.com/puppetlabs-release-$CODENAME.deb
          dpkg -i puppetlabs-release-$CODENAME.deb
          apt-get -q -y update
          apt-get -q -y install puppet
        }
    else
        echo "No package installer available. You may need to install puppet manually."
    fi
}



if [ "$(gem search -i librarian-puppet)" = "false" ]; then
  gem install librarian-puppet --source http://ruby.taobao.org/ --no-rdoc --no-ri
  cd $PUPPET_DIR && librarian-puppet update
else
  cd $PUPPET_DIR && librarian-puppet update
fi