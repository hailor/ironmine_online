Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

$app_folder = "/var/apps/ironmine"
$ruby_version = "ruby-1.9.2-p318"
$mysql_table_detect = "/var/apps/ironmine"

group { ["web","ironmine"]:
    ensure => "present",
}

user { 'nginx':
  ensure   => 'present',
  comment  => 'nginx user',
  groups => ['web'],
  shell    => '/sbin/nologin',
  require => Group["web"]
}

user { 'ironmine':
  ensure   => 'present',
  groups => ['ironmine','web'],
  comment  => 'ironmine user',
  managehome => 'true',
  shell    => '/bin/sh',
  require => Group["web"]
}

class { 'java':
  distribution => 'jdk',
  version => 'latest',
}

include rvm 

rvm_system_ruby {
  "${ruby_version}":
    ensure => 'present',
    default_use => false;
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
  require => [File["data_file"]]
}

exec { "import_prod_data" :
  command => "/usr/bin/mysql -u root --password=root --database=irm_prod --skip-column-names -e 'source /var/datas/irm_prod_uat_2013-07-16.sql;'",
  timeout=> 30000,
  onlyif=> 'test -z "$(/usr/bin/mysql -u root --password=root --database=irm_prod --skip-column-names -e "show tables;")"',
  require => [File["data_file"]]
}


include nginx

nginx::file { 'www.ironmine.com.conf':
  content => template('ironmine/nginx.conf.erb')
} 

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

exec { "install_unicorn" :
  command => "/usr/local/rvm/bin/rvm-shell ${ruby_version} -c 'gem install  unicorn --source http://ruby.taobao.org/ --no-rdoc --no-ri  '",
  timeout=> 30000,
  unless=> "/usr/local/rvm/bin/rvm-shell ${ruby_version} -c 'gem list  unicorn -i'",
  require => [Rvm_system_ruby["${ruby_version}"]]
}

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
  command => "/usr/local/rvm/bin/rvm-shell ${ruby_version} -c 'bundle install'",
  cwd => "${app_folder}",
  timeout=> 30000,
  require => [File["${app_folder}"],Exec["install_bundler"]]
}

