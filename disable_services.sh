#!/bin/sh
 
# Script to disable unneeded services at boot time
 
# Please read through each to ensure you want these disabled.
# For /most/ systems, this set up is fine.
 
# anacron
# The anacron subsystem is designed to provide cron functionality
# for machines which may be shut down during the normal times that
# system cron jobs run, frequently in the middle of the night. 
# Laptops and workstations which are shut down at night should keep
# anacron enabled, so that standard system cron jobs will run when 
# the machine boots.
chkconfig anacron off
service anacron stop
 
# apmd
# APM is being replaced by ACPI and should be considered deprecated.
# As such, it can be disabled if ACPI is supported by your hardware
# and kernel. If the file /proc/acpi/info exists and contains ACPI 
# version information, then APM can safely be disabled without loss
# of functionality.
chkconfig apmd off
service apmd stop
 
# autofs
# If the autofs service is not needed to dynamically mount NFS
# filesystems or removable media, disable the service 
chkconfig autofs off
service autofs stop
 
# avahi-daemon
# The Avahi daemon implements the DNS Service Discovery and Multicast
# DNS protocols, which provide service and host discovery on a network.
# It allows a system to automatically identify resources on the network,
# such as printers or web servers.
chkconfig avahi-daemon off
service avahi-daemon stop
 
# bluetooth
# If the system requires no Bluetooth devices, disable this service
chkconfig bluetooth off
service bluetooth stop
 
# cups
# Do you need the ability to print from this machine or to allow others
# to print to it? If not:
chkconfig cups off
service cups stop
 
# gpm
# GPM is the service that controls the text console mouse pointer.
# (The X Windows mouse pointer is unaffected by this service.)
chkconfig gpm off
service gpm stop
 
# haldaemon
# The haldaemon service provides a dynamic way of managing device
# interfaces. It automates device configuration and provides an API for
# making devices accessible to applications through the D-Bus interface.
chkconfig haldaemon off
service haldaemon stop
 
# hidd
# If the system requires no Bluetooth devices, disable this service
chkconfig hidd off
service hidd stop
 
# kudzu
# Kudzu, Red Hat’s hardware detection program, represents an unnecessary
# security risk as it allows unprivileged users to perform hardware
# configuration without authorization. Unless this specific functionality
# is required, Kudzu should be disabled.
chkconfig kudzu off
service kudzu stop
 
# mcstrans
# Unless there is some overriding need for the convenience of category
# label translation, disable the MCS translation service
chkconfig mcstrans off
service mcstrans stop
 
# messagebus
# If no services which require D-Bus are in use, disable this service
chkconfig messagebus off
service messagebus stop
 
# nfs services
# If NFS is not needed, disable NFS client daemons
chkconfig nfslock off
service nfslock stop
chkconfig rpcgssd off
service rpcgssd stop
chkconfig rpcidmapd off
service rpcidmapd stop
 
# pcscd
# If Smart Cards are not in use on the system, disable this service
chkconfig pcscd off
service pcscd stop
 
# portmap
# No NFS, NIS?  No portmap
chkconfig portmap off
service portmap stop
 
# xfs
# The system’s X.org requires the X Font Server service (xfs) to function.
# The xfs service will be started auto- matically if X.org is activated
# via startx. Therefore, it is safe to prevent xfs from starting at
# boot when X is disabled, even if users are allowed to run X manually.
chkconfig xfs off
service xfs stop
