 exec { 'update_apt':
        command => '/usr/bin/apt-get update',
        require => [
        ],
      }

      package { 'openjdk-8-jdk':
        ensure   => 'installed',
        require  => Exec['update_apt'],
      }

