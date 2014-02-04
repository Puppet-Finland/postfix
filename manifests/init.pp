#
# == Class: postfix
#
# Postfix class installs and configures postfix mail transfer agent for basic mail sending.
#
# == Parameters
#
# [*serveradmin*]
#   An email address where mail for root should be sent to. Defaults to the top-scope
#   variable $::serveradmin.
# [*relayhost*]
#   The host used for relaying mail. Defaults to '' which means that Postfix 
#   will try to send mail directly. 
# [*domain_mail_server*]
#   Selects whether to configure this postfix instance to receive mail for the
#   entire domain, or only for itself. Defaults to 'no'.
# [*inet_interfaces*]
#   Interfaces and/or IPv4/IPv6 addresses on which postfix will listen on. 
#   Special values are 'all' and 'loopback-only'. Defaults to 'loopback-only'.
# [*allow_ipv4_address*]
#   Allow SNMP connections from this IPv4 address/subnet. Defaults to 127.0.0.1.
# [*allow_ipv6_address*]
#   The IP-address part of an IPv6 subnet from which to allow connections.
#   Defaults to ::1.
# [*allow_ipv6_netmask*]
#   The netmask of the IPv6 subnet from which to allow connections. Defaults to
#   128. This is required because postfix needs IPv6 addresses in [::1]/128
#   format, which conflicts with puppet's array definitions.
# [*monitor_email*]
#   Email address where local service monitoring software sends it's reports to.
#   Defaults to top scope variable $::servermonitor.
#
# == Examples
#
# class {'postfix':
#   serveradmin => 'my.admin.email@domain.tld',
#   domain_mail_server => 'yes',
#   inet_interfaces => 'all'
#   allow_ipv4_address => '192.168.0.0/24',
#   allow_ipv6_address => '::1',
#   allow_ipv6_netmask => '128'
# }
#
# == Authors
#
# Samuli Seppänen <samuli.seppanen@gmail.com>
# Samuli Seppänen <samuli@openvpn.net>
# Mikko Vilpponen <vilpponen@protecomp.fi>
#
# == License
#
# BSD-lisence
# See file LICENSE for details
#
class postfix(
    $serveradmin = $::serveradmin,
    $relayhost = '',
    $domain_mail_server = 'no',
    $inet_interfaces = 'loopback-only',
    $allow_ipv4_address = '127.0.0.1',
    $allow_ipv6_address = '::1',
    $allow_ipv6_netmask = '128',
    $monitor_email = $::servermonitor
)
{

# Rationale for this is explained in init.pp of the sshd module
if hiera('manage_postfix', 'true') != 'false' {

    # SuSE has a very different idea of how we configure postfix, so for the 
    # time being it's only partially supported.
    if $::operatingsystem == 'OpenSuSE' {
        include postfix::install
        include postfix::service

        if tagged('monit') {
            class { 'postfix::monit':
                monitor_email => $monitor_email,
            }
        }
    }
    elsif $::operatingsystem == 'SLES' {
        include postfix::install
    }
    else {
        include postfix::install

        class {'postfix::config':
            serveradmin => $serveradmin,
            relayhost => $relayhost,
            domain_mail_server => $domain_mail_server,
            inet_interfaces => $inet_interfaces,
            allow_ipv4_address => $allow_ipv4_address,
            allow_ipv6_address => $allow_ipv6_address,
            allow_ipv6_netmask => $allow_ipv6_netmask,
        }
        include postfix::service

        # FreeBSD requires additional configuration
        if $::operatingsystem == 'FreeBSD' {
            include postfix::config::freebsd
        }

        if tagged('packetfilter') {
            class {'postfix::packetfilter':
                ipv4_address => $allow_ipv4_address,
                ipv6_address => "$allow_ipv6_address/$allow_ipv6_netmask",
            }
        }

        if tagged('monit') {
            class { 'postfix::monit':
                monitor_email => $monitor_email,
            }
        }
    }
}
}
