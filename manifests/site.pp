Exec { path => '/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin' }

include '::mysql::server'

include timezone
include user
include packages
include nginx
include uwsgi
include python
include virtualenv
include software

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

  # Prepare user's project directories
  file { ["/home/${user}/virtualenvs",
          "/home/${user}/public_html",
          "/home/${user}/public_html/${domain_name}",
          "/home/${user}/public_html/${domain_name}/static"
          ]:
    ensure => directory,
    owner => "${user}",
    group => "${user}",
    require => Exec['add user'],
    before => File['media dir']
  }

  file { 'media dir':
    path => "/home/${user}/public_html/${domain_name}/media",
    ensure => directory,
    owner => "${user}",
    group => 'www-data',
    mode => 0775,
    require => Exec['add user']
  }
}

class packages {
  package { 'epel-release':
    ensure => latest
  }

  package { 'gcc':
    ensure => latest
  }

  package { 'curl':
    ensure => latest
  }
}

class nginx {
  package { 'nginx':
    ensure => latest,
  }

  service { 'nginx':
    ensure => running,
    enable => true,
    require => Package['nginx']
  }

  file { '/etc/nginx/sites-enabled/default':
    ensure => absent,
    require => Package['nginx']
  }

  file { 'sites-available config':
    path => "/etc/nginx/sites-available/${domain_name}",
    ensure => file,
    content => template("${inc_file_path}/nginx/nginx.conf.erb"),
    require => Package['nginx']
  }

  file { "/etc/nginx/sites-enabled/${domain_name}":
    ensure => link,
    target => "/etc/nginx/sites-available/${domain_name}",
    require => File['sites-available config'],
    notify => Service['nginx']
  }
}

class uwsgi {
  $sock_dir = '/tmp/uwsgi' # Without a trailing slash
  $uwsgi_user = 'www-data'
  $uwsgi_group = 'www-data'

  package { 'uwsgi':
    ensure => latest,
    provider => pip,
    require => Class['python']
  }

  service { 'uwsgi':
    ensure => running,
    enable => true
  }
}

class mysql {
  $create_db_cmd = "CREATE DATABASE ${db_name} CHARACTER SET utf8;"
  $create_user_cmd = "CREATE USER '${db_user}'@localhost IDENTIFIED BY '${db_password}';"
  $grant_db_cmd = "GRANT ALL PRIVILEGES ON ${db_name}.* TO '${db_user}'@localhost;"

  exec { 'grant user db':
    command => "mysql -u root -e \"${create_db_cmd}${create_user_cmd}${grant_db_cmd}\"",
    unless => "mysqlshow -u${db_user} -p${db_password} ${db_name}",
    require => Package['mysql-server']
  }
}

class python {
  package { 'python-devel':
    ensure => latest,
  }

  package { 'python-pip':
    ensure => latest,
  }
}

class virtualenv {
  package { 'virtualenv':
    ensure => latest,
    provider => pip,
    require => Class['python', 'user']
  }

  exec { 'create virtualenv':
    command => "virtualenv --always-copy ${domain_name}",
    cwd => "/home/${user}/virtualenvs",
    user => "${user}",
    require => Package['virtualenv']
  }

  file { "/home/${user}/virtualenvs/${domain_name}/requirements.txt":
    ensure => file,
    owner => "${user}",
    group => "${user}",
    mode => 0644,
    source => "${inc_file_path}/virtualenv/requirements.txt",
    require => Exec['create virtualenv']
  }
}

class software {
  package { 'git':
    ensure => latest,
  }

  package { 'vim':
    ensure => latest,
  }
}
