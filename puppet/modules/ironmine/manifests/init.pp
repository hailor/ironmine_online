class ironmine{
  define tarball (
    $source,
    $target_dir = '/tmp',
    $install = false,
    $target = '',
    $compress_type = 'tgz',
    $unless = ''
  ) {
  
    $source_split = split($source, '/')
    $protocol = $source_split[0]
    $file_name = $source_split[-1]
  
    Exec {
      path => ['/usr/bin', '/bin']
    }

    exec { "create_$target_dir_$file_name":
      command => "/bin/mkdir -p $target_dir",
      creates => "$target_dir"
    }
  
    if $protocol == 'http:' or $protocol == 'ftp:' {
  
      if !defined(Package['wget']) {
        package { 'wget':
          ensure => installed
        }
      }
  
      exec { "get-source-${file_name}":
        command => "wget ${source} -qP /tmp",
        require => Package["wget"],
        unless => $unless,
      }
      file { "file-source-${file_name}":
        ensure => present,
        path => "/tmp/${file_name}",
        require => Exec["get-source-${file_name}"]
      }
    } elsif $protocol == 'puppet:' {
      file { "file-source-${file_name}":
        ensure => present,
        path => "/tmp/${file_name}",
        source => $source
      }
    }

    case $compress_type {
      'tgz','tar.gz': { $command = "tar -xzf /tmp/${file_name} -C ${target_dir}/" }
      'tar': { $command = "tar -xzf  /tmp/${file_name} -C ${target_dir}/" }
      'zip': { $command = "unzip -o /tmp/${file_name} -d ${target_dir}/" }
      'bz2': { $command = "tar -jxf  /tmp/${file_name} -C ${target_dir}/" }

    }
  
    exec { "unpack-source-${file_name}":
      command => $command,
      require => [File["file-source-${file_name}"],Exec["create_$target_dir_$file_name"]],
      unless => $unless,
    }

    if $install {
      exec { "install-source-${file_name}":
        command => $install,
        cwd => "${target_dir}/$target",
        require => [File["file-source-${file_name}"],Exec["create_$target_dir_$file_name"]],
        unless => $unless
      } 
    }
  
  } 
}