http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/OperationList-cmd.html

AMI (awscli ec2 ami)
===
ec2-create-image
ec2-deregister
ec2-describe-image-attribute
ec2-describe-images
ec2-migrate-image
ec2-modify-image-attribute
ec2-register
ec2-reset-image-attribute

Availability Zones & Regions
============================
ec2-describe-availability-zone
ec2-describe-regions

Elastic Block Store (awscli ec2 ebs)
===================
ec2-attach-volume
ec2-copy-snapshot
ec2-create-snapshot
ec2-create-volume
ec2-delete-disk-image
ec2-delete-snapshot
ec2-delete-volume
ec2-describe-snapshot-attribute
ec2-describe-snapshots
ec2-describe-volumes
ec2-describe-volume-attribute
ec2-describe-volume-status
ec2-detach-volume
ec2-enable-volume-io
ec2-import-volume
ec2-modify-snapshot-attribute
ec2-modify-volume-attribute
ec2-reset-snapshot-attribute

EIP (awscli ec2 eip)
===
ec2-allocate-address
ec2-associate-address
ec2-describe-addresses
ec2-disassociate-address
ec2-release-address

Instances (awscli ec2 instances)
=========
*ec2-describe-instance-attribute
*ec2-describe-instance-status
*ec2-describe-instances
ec2-import-instance
ec2-modify-instance-attribute
*ec2-reboot-instances
ec2-reset-instance-attribute
ec2-run-instances
*ec2-start-instances
*ec2-stop-instances
*ec2-terminate-instances

Key Pairs (awscli ec2 kp)
=========
ec2-create-keypair
ec2-delete-keypair
ec2-describe-keypairs
ec2-fingerprint-key
ec2-import-keypair

Monitoring (awscli ec2 monitoring)
==========
ec2-monitor-instances
ec2-unmonitor-instances

Placement Groups (awscli ec2 placement)
================
ec2-create-placement-group
ec2-delete-placement-group
ec2-describe-placement-groups

Reserved Instances
==================
ec2-cancel-reserved-instances-listing
ec2-create-reserved-instances-listing
ec2-describe-reserved-instances
ec2-describe-reserved-instances-listings
ec2-describe-reserved-instances-offerings
ec2-purchase-reserved-instances-offering

Security Groups (awscli ec2 secgroup)
===============
ec2-authorize
ec2-create-group
ec2-delete-group
ec2-describe-group
ec2-revoke

Spot Instances (awscli ec2 spot)
==============
ec2-cancel-spot-instance-requests
ec2-create-spot-datafeed-subscription
ec2-delete-spot-datafeed-subscription
ec2-describe-spot-datafeed-subscription
ec2-describe-spot-instance-requests
ec2-describe-spot-price-history
ec2-request-spot-instances

Tags (awscli ec2 tags)
====
ec2-create-tags
ec2-delete-tags
ec2-describe-tags

VM Import
=========
ec2-cancel-conversion-task
ec2-delete-disk-image
ec2-describe-conversion-tasks
ec2-import-instance
ec2-import-volume
ec2-resume-import

VM Export
=========
ec2-cancel-export-task
ec2-create-instance-export-task
ec2-describe-export-tasks

VPC (awscli vpc)
===

VPCs (awscli vpc)
=================
ec2-create-vpc
ec2-delete-vpc
ec2-describe-vpc-attribute
ec2-describe-vpcs
ec2-modify-vpc-attribute

VPN Connections (awscli vpc connections)
============================
ec2-create-vpn-connection
ec2-delete-vpn-connection
ec2-describe-vpn-connections

Virtual Private Gateways (awscli vpc priv_gateways)
=====================================
ec2-attach-vpn-gateway
ec2-create-vpn-gateway
ec2-delete-vpn-gateway
ec2-describe-vpn-gateways
ec2-detach-vpn-gateway

VPC Gateways (awscli vpc cust_gateways)
============
ec2-create-customer-gateway
ec2-delete-customer-gateway
ec2-describe-customer-gateways

VPC DHCP Options (awscli vpc dhcp)
================
ec2-associate-dhcp-options
ec2-create-dhcp-options
ec2-delete-dhcp-options
ec2-describe-dhcp-options

Route Tables (awscli vpc route_tables)
=========================
ec2-associate-route-table
ec2-create-route
ec2-create-route-table
ec2-delete-route
ec2-delete-route-table
ec2-describe-route-tables
ec2-disassociate-route-table
ec2-replace-route
ec2-replace-route-table-association

Network ACLs (awscli vpc network_acls)
=========================
ec2-create-network-acl
ec2-create-network-acl-entry
ec2-delete-network-acl
ec2-delete-network-acl-entry
ec2-describe-network-acls
ec2-replace-network-acl-association
ec2-replace-network-acl-entry

VPC Elastic Network Interfaces (awscli vpc net_interfaces)
==============================
ec2-attach-network-interface
ec2-create-network-interface
ec2-delete-network-interface
ec2-describe-network-interfaces
ec2-describe-network-interface-attributes
ec2-detach-network-interface
ec2-modify-network-interface-attribute
ec2-reset-network-interface-attribute

VPC Internet Gateways (awscli vpc int_gateways)
=====================
ec2-attach-internet-gateway
ec2-create-internet-gateway
ec2-delete-internet-gateway
ec2-describe-internet-gateways
ec2-detach-internet-gateway

Subnets (awscli vpc subnets)
===================
ec2-create-subnet
ec2-delete-subnet
ec2-describe-subnets