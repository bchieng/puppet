class ocf_kerberos {
  package { 'heimdal-kdc':
    # if local realm has not been defined installation will fail
    require => File['/etc/krb5.conf'];
  }

  service { 'heimdal-kdc':
    subscribe => File['/etc/heimdal-kdc/kdc.conf', '/etc/heimdal-kdc/kadmind.acl'],
    require   => Package['heimdal-kdc'];
  }

  # The inetd service is installed as a dependency of the heimdal-kdc package
  service { 'inetd':
    require => Package['heimdal-kdc'];
  }

  file {
    '/etc/heimdal-kdc/kdc.conf':
      source  => 'puppet:///modules/ocf_kerberos/kdc.conf',
      require => Package['heimdal-kdc'];

    '/etc/heimdal-kdc/kadmind.acl':
      source  => 'puppet:///modules/ocf_kerberos/kadmind.acl',
      require => Package['heimdal-kdc'];

    '/etc/logrotate.d/heimdal-kdc':
      source  => 'puppet:///modules/ocf_kerberos/heimdal-kdc-logrotate',
      require => Package['heimdal-kdc'];

    '/etc/heimdal-kdc/check-pass-strength':
      source  => 'puppet:///modules/ocf_kerberos/check-pass-strength',
      mode    => '0755',
      require => Package['heimdal-kdc'];
  }

  augeas { '/etc/inetd.conf':
    context => '/files/etc/inetd.conf',
    changes => [
      'set service[last()+1] kerberos-adm',
      'set service[last()]/socket stream',
      'set service[last()]/protocol tcp6',
      'set service[last()]/wait nowait',
      'set service[last()]/user root',
      'set service[last()]/command /usr/sbin/tcpd',
      'set service[last()]/arguments/1 /usr/lib/heimdal-servers/kadmind',
    ],
    onlyif  => "match service[. = 'kerberos-adm'] size == 1",
    require => Package['heimdal-kdc'],
    notify  => Service['inetd'],
  }

  # Daily local git backup
  file { '/usr/local/sbin/kerberos-git-backup':
    mode   => '0755',
    source => 'puppet:///modules/ocf_kerberos/kerberos-git-backup';
  }

  cron { 'kerberos-git-backup':
    command => '/usr/local/sbin/kerberos-git-backup',
    minute  => 0,
    hour    => 4,
    require => File['/usr/local/sbin/kerberos-git-backup'];
  }
}
