Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

$app_folder = "/var/apps/ironmine"
$ruby_version = "ruby-1.9.2-p320"
$mysql_table_detect = "/var/apps/ironmine"


user { 'ironmine':
  ensure   => 'present',
  comment  => 'ironmine user',
  managehome => 'true',
  shell    => '/bin/sh',
  membership => minimum,
}

class { 'java':
  distribution => 'jdk',
  version => 'latest',
}
#sed -i 's!ftp.ruby-lang.org/pub/ruby!ruby.taobao.org/mirrors/ruby!' $rvm_path/config/db
include rvm 

rvm_system_ruby {
  "${ruby_version}":
    ensure => 'present',
    default_use => false;
}

class {
  'rvm::passenger::apache':
    version => '4.0.10',
    ruby_version => "$ruby_version",
    mininstances => '3',
    maxinstancesperapp => '0',
    maxpoolsize => '30',
    spawnmethod => 'smart-lv2';
}

class { 'mysql::server':
  config_hash => { 'root_password' => 'root' }
}

mysql::db { 'irm_dev':
  user     => 'ironmine',
  password => 'handoracle',
  host     => 'localhost',
  grant    => ['all'],
  charset => 'utf8',
  require => Class['mysql::server']
}

mysql::db { 'irm_prod':
  user     => 'ironmine',
  password => 'handoracle',
  host     => 'localhost',
  grant    => ['all'],
  charset => 'utf8',
  require => Class['mysql::server']
}

mysql::db { 'irm_test':
  user     => 'ironmine',
  password => 'handoracle',
  host     => 'localhost',
  grant    => ['all'],
  charset => 'utf8',
  require => Class['mysql::server']
}

database_grant { 'ironmine@%/*':
  privileges => ['all'] ,
  require => Class['mysql::server']
}

file { [ "/var/datas" ]:
       ensure => "directory",
}

file {"data_file":
    path=> "/var/datas/irm_prod_uat_2013-07-16.sql",
    source => "puppet:///modules/ironmine/irm_prod_uat_2013-07-16.sql",
    require => [Database["irm_prod"]],
}

exec { "import_dev_data" :
  command => "/usr/bin/mysql -u root --password=root --database=irm_dev --skip-column-names -e 'source /var/datas/irm_prod_uat_2013-07-16.sql;'",
  timeout=> 30000,
  onlyif=> 'test -z "$(/usr/bin/mysql -u root --password=root --database=irm_dev --skip-column-names -e "show tables;")"',
  require => [File["data_file"],Database['irm_dev']]
}

exec { "import_prod_data" :
  command => "/usr/bin/mysql -u root --password=root --database=irm_prod --skip-column-names -e 'source /var/datas/irm_prod_uat_2013-07-16.sql;'",
  timeout=> 30000,
  onlyif=> 'test -z "$(/usr/bin/mysql -u root --password=root --database=irm_prod --skip-column-names -e "show tables;")"',
  require => [File["data_file"],Database['irm_prod']]
}


#include nginx
#
#nginx::file { 'www.ironmine.com.conf':
#  content => template('ironmine/nginx.conf.erb')
#} 

#file { "/etc/nginx/nginx.conf":
#  content => template('ironmine/nginx.conf.erb'),
#  notify  => Service['nginx'],
#  require => Package['nginx'],
#  replace => false,
#  ensure => 'present'
#}



case $::osfamily {
   'debian': {
     package {'ruby-dev':ensure   => 'present'}
     package {'libmysqlclient-dev':ensure   => 'present'} 
   }
   default: {
     package {'ruby-devel':ensure   => 'present'}
     package {'mysql-devel':ensure   => 'present'}
   }
}


exec { "install_bundler" :
  command => "/usr/local/rvm/bin/rvm-shell ${ruby_version} -c 'gem install bundler --source http://ruby.taobao.org/ --no-rdoc --no-ri  '",
  timeout=> 30000,
  unless=> "/usr/local/rvm/bin/rvm-shell ${ruby_version} -c 'gem list bundler -i'",
  require => [Rvm_system_ruby["${ruby_version}"]]
}

#exec { "install_unicorn" :
#  command => "/usr/local/rvm/bin/rvm-shell ${ruby_version} -c 'gem install  unicorn --source http://ruby.taobao.org/ --#no-rdoc --no-ri  '",
#  timeout=> 30000,
#  unless=> "/usr/local/rvm/bin/rvm-shell ${ruby_version} -c 'gem list  unicorn -i'",
#  require => [Rvm_system_ruby["${ruby_version}"]]
#}



#file { [ "/var/apps" ]:
#       ensure => "directory",
#}
#
#
#
#vcsrepo { '/var/apps/ironmine':
#  ensure => latest,
#  provider => git,
#  force => true,
#  source => 'http://github.com/aronezhang/ironmine.git',
#  require => File["${app_folder}"]
#}

file { [ "/var/apps"]:
       ensure => "directory",
}
file { [ "/var/apps/ironmine"]:
       ensure => "present",
       require => File["/var/apps"]
}

#file {"unicorn_config_file":
#    path=> "${app_folder}/config/unicorn.rb",
#    content => template('ironmine/unicorn.rb.erb'),
#    require => [File["${app_folder}"],Exec["install_unicorn"]],
#}
#
#file {"unicorn_ctl_file":
#    path=> "${app_folder}/script/unicorn.sh",
#    content => template('ironmine/unicorn.sh.erb'),
#    mode    => '0777',
#    require => [File["${app_folder}"],Exec["install_unicorn"]],
#}

exec { "gems_install" :
  command => "/usr/local/rvm/bin/rvm-shell ${ruby_version} -c 'export NLS_LANG=AMERICAN_AMERICA.UTF8&&export ORACLE_HOME=/var/apps/oracle_client/instantclient_11_2&&export LD_LIBRARY_PATH=/var/apps/oracle_client/instantclient_11_2&&bundle install'",
  cwd => "${app_folder}",
  timeout=> 30000,
  require => [File["${app_folder}"],Exec["install_bundler"],Ironmine::Tarball["instantclient-basic-linux.x64-11.2.0.3.0"],Ironmine::Tarball["instantclient-sdk-linux.x64-11.2.0.3.0"],Ironmine::Tarball["instantclient-sqlplus-linux.x64-11.2.0.3.0"]]
}

ironmine::tarball{"instantclient-basic-linux.x64-11.2.0.3.0":
  source => "puppet:///modules/ironmine/instantclient-basic-linux.x64-11.2.0.3.0.zip",
  target_dir => "/var/apps/oracle_client",
  target => "instantclient_11_2",
  compress_type => "zip",
  install => "ln -s /var/apps/oracle_client/instantclient_11_2/libocci.so.11.1  /var/apps/oracle_client/instantclient_11_2/libocci.so&&ln -s /var/apps/oracle_client/instantclient_11_2/libclntsh.so.11.1 /var/apps/oracle_client/instantclient_11_2/libclntsh.so",
  unless => "test -e /var/apps/oracle_client/instantclient_11_2/libocci.so",
  require => [File["/var/apps"]]  
}

ironmine::tarball{"instantclient-sdk-linux.x64-11.2.0.3.0":
  source => "puppet:///modules/ironmine/instantclient-sdk-linux.x64-11.2.0.3.0.zip",
  target_dir => "/var/apps/oracle_client",
  target => "instantclient_11_2",
  compress_type => "zip",
  unless => "test -d /var/apps/oracle_client/instantclient_11_2/sdk",
  require => [File["/var/apps"] ] 
}

ironmine::tarball{"instantclient-sqlplus-linux.x64-11.2.0.3.0":
  source => "puppet:///modules/ironmine/instantclient-sqlplus-linux.x64-11.2.0.3.0.zip",
  target_dir => "/var/apps/oracle_client",
  target => "instantclient_11_2",
  compress_type => "zip",
  unless => "test -e /var/apps/oracle_client/instantclient_11_2/sqlplus",
  require => [File["/var/apps"] ] 
}


package {'libreoffice':ensure   => 'present'}

ironmine::tarball{"unoconv":
  source => "http://dag.wieers.com/home-made/unoconv/unoconv-0.6.tar.gz",
  target_dir => "/var/apps",
  target => "unoconv-0.6",
  unless => "test -e /usr/bin/unoconv",
  install => "ln -s /var/apps/unoconv-0.6/unoconv /usr/bin/unoconv",
  require => [File["/var/apps"],Package['libreoffice']] 
}


ironmine::tarball{"wkhtmltopdf":
  source => "http://wkhtmltopdf.googlecode.com/files/wkhtmltopdf-0.9.9-static-amd64.tar.bz2",
  target_dir => "/var/apps/wkhtmltopdf",
  target => "",
  compress_type => "bz2",
  unless => "test -e /var/apps/wkhtmltopdf/wkhtmltopdf-amd64",
  install => "ln -s /var/apps/wkhtmltopdf/wkhtmltopdf-amd64 /usr/local/bin/wkhtmltopdf",
  require => [File["/var/apps"]] 
}
