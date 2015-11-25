# == Class gitlab::install
#
# This class is called from gitlab for install.
#
class gitlab::install {

  $edition             = $::gitlab::edition
  $manage_package_repo = $::gitlab::manage_package_repo
  $package_ensure      = $::gitlab::package_ensure
  $package_name        = "gitlab-${edition}"
  $package_pin         = $::gitlab::package_pin

  # only do repo management when on a Debian-like system
  if $manage_package_repo {
    case $::osfamily {
      'debian': {
        include apt
        Exec['apt_update'] -> Package[$package_name]
        $_lower_os = downcase($::operatingsystem)
        apt::source { 'gitlab_official':
          comment  => 'Official repository for Gitlab',
          location => "https://packages.gitlab.com/gitlab/gitlab-${edition}/${_lower_os}/",
          release  => $::lsbdistcodename,
          repos    => 'main',
          key      => {
            id     => '1A4C919DB987D435939638B914219A96E15E78F4',
            source => 'https://packages.gitlab.com/gpg.key',
          },
          include  => {
            src    => true,
            deb    => true,
          },
        } ->
        package { $package_name:
          ensure => $package_ensure,
        }
        if $package_pin {
          apt::pin { 'hold-gitlab':
            packages => $package_name,
            version  => $package_ensure,
            priority => 1001,
          }
        }
      }
      'redhat': {
        if is_hash($::os) {
          $releasever = $::os[release][major]
        } else {
          $releasever = "\$releasever"
        }

        yumrepo { 'gitlab_official':
          descr         => 'Official repository for Gitlab',
          baseurl       => "https://packages.gitlab.com/gitlab/gitlab-${edition}/el/${releasever}/\$basearch",
          enabled       => 1,
          gpgcheck      => 0,
          gpgkey        => 'https://packages.gitlab.com/gpg.key',
          repo_gpgcheck => 1,
          sslcacert     => '/etc/pki/tls/certs/ca-bundle.crt',
          sslverify     => 1,
        } ->
        package { $package_name:
          ensure => $package_ensure,
        }
      }
      default: {
        fail("OS family ${::osfamily} not supported")
      }
    }
  } else {
    package { $package_name:
      ensure => $package_ensure,
    }
  }

}
