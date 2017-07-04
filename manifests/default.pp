Exec { path => '/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin' }

include '::mysql::server'

include timezone
include user
include mysql
include git

class timezone {
  package { "tzdata":
    ensure => latest,
  }

  file { "/etc/localtime":
    require => Package["tzdata"],
    source => "file:///usr/share/zoneinfo/${tz}",
  }
}

class user {
  exec { 'add user':
    command => "sudo useradd -m -G wheel -s /bin/bash ${user}",
    unless => "id -u ${user}"
  }

  exec { 'set password':
    command => "passwd -f -u ${user}",
    require => Exec['add user']
  }
}

class mysql {
  $create_db_cmd = "CREATE DATABASE ${db_name} CHARACTER SET utf8;"
  $create_user_cmd = "CREATE USER '${db_user}'@localhost IDENTIFIED BY '${db_password}';"
  $grant_db_cmd = "GRANT ALL PRIVILEGES ON ${db_name}.* TO '${db_user}'@localhost;"

  exec { 'grant user db':
    command => "mysql -u root -e \"${create_db_cmd}${create_user_cmd}${grant_db_cmd}\"",
    unless => "mysqlshow -u${db_user} -p${db_password} ${db_name}",
    require => [
      Package['mysql-server'],
      Class['user']
    ]
  }
}

class { 'python' :
  version    => 'system',
  pip        => 'present',
  dev        => 'absent',
  virtualenv => 'absent',
  gunicorn   => 'absent',
}

class{'nginx': }
