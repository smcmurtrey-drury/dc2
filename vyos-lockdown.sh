#!/bin/vbash
# This header is required for VyOS to run config commands from a script
source /opt/vyatta/etc/functions/script-template

echo "Starting VyOS Lockdown Script..."

# Enter configuration mode
configure

delete nat source rule 101 translation address
set nat source rule 101 translation address masquerade

# Rule 10: Splunk Web (TCP 8000)
set nat destination rule 10 description 'Scored: Splunk Web UI'
set nat destination rule 10 inbound-interface eth4
set nat destination rule 10 destination address '10.229.100.11'
set nat destination rule 10 translation address '172.20.242.40'
set nat destination rule 10 protocol tcp
set nat destination rule 10 destination port 8000

# Rule 20: DNS (UDP 53)
set nat destination rule 20 description 'Scored: DNS'
set nat destination rule 20 inbound-interface eth4
set nat destination rule 20 destination address '10.229.100.11'
set nat destination rule 20 translation address '172.20.242.30'
set nat destination rule 20 protocol udp
set nat destination rule 20 destination port 53

# Rule 21: Ecomm HTTP (TCP 80)
set nat destination rule 21 description 'Scored: Ecomm-Web'
set nat destination rule 21 inbound-interface eth4
set nat destination rule 21 destination address '10.229.100.11'
set nat destination rule 21 translation address '172.20.242.30'
set nat destination rule 21 protocol tcp
set nat destination rule 21 destination port 80

# Rule 30: Mail SMTP (TCP 25)
set nat destination rule 30 description 'Scored: SMTP'
set nat destination rule 30 inbound-interface eth4
set nat destination rule 30 destination address '10.229.100.39'
set nat destination rule 30 translation address '172.20.242.40'
set nat destination rule 30 protocol tcp
set nat destination rule 30 destination port 25

# Rule 40: Web HTTP (TCP 80)
set nat destination rule 40 description 'Scored: Web-HTTP'
set nat destination rule 40 inbound-interface eth5
set nat destination rule 40 destination address '10.229.100.140'
set nat destination rule 40 translation address '172.20.240.101'
set nat destination rule 40 protocol tcp
set nat destination rule 40 destination port 80

# Rule 45: Web HTTPS (TCP 443)
set nat destination rule 45 description 'Scored: Web-HTTPS'
set nat destination rule 45 inbound-interface eth5
set nat destination rule 45 destination address '10.229.100.140'
set nat destination rule 45 translation address '172.20.240.101'
set nat destination rule 45 protocol tcp
set nat destination rule 45 destination port 443

set firewall name ipv4 OUTSIDE-IN default-action drop
set firewall name ipv4 OUTSIDE-IN default-log enable

set firewall name ipv4  OUTSIDE-IN rule 1 action accept
set firewall name ipv4 OUTSIDE-IN rule 1 state established enable
set firewall name ipv4 OUTSIDE-IN rule 1 state related enable

set firewall name ipv4 OUTSIDE-IN rule 20 action accept
set firewall name ipv4 OUTSIDE-IN rule 20 destination port 80
set firewall name ipv4 OUTSIDE-IN rule 20 protocol tcp

set firewall name ipv4 OUTSIDE-IN rule 21 action accept
set firewall name ipv4 OUTSIDE-IN rule 21 destination port 443
set firewall name ipv4 OUTSIDE-IN rule 21 protocol tcp

set firewall name ipv4 OUTSIDE-IN rule 30 action accept
set firewall name ipv4 OUTSIDE-IN rule 30 destination port 25
set firewall name ipv4 OUTSIDE-IN rule 30 protocol tcp

set firewall name ipv4 OUTSIDE-IN rule 31 action accept
set firewall name ipv4 OUTSIDE-IN rule 31 destination port 110
set firewall name ipv4 OUTSIDE-IN rule 31 protocol tcp

set firewall name ipv4 OUTSIDE-IN rule 40 action accept
set firewall name ipv4 OUTSIDE-IN rule 40 destination port 53
set firewall name ipv4 OUTSIDE-IN rule 40 protocol udp

set firewall name ipv4 OUTSIDE-IN rule 41 action accept
set firewall name ipv4 OUTSIDE-IN rule 41 destination port 53
set firewall name ipv4 OUTSIDE-IN rule 41 protocol tcp

set firewall name ipv4 OUTSIDE-IN rule 50 action accept
set firewall name ipv4 OUTSIDE-IN rule 50 protocol icmp

set firewall name ipv4 INSIDE-OUT default-action drop
set firewall name ipv4 INSIDE-OUT default-log enable

set firewall name ipv4 INSIDE-OUT rule 10 action accept
set firewall name ipv4 INSIDE-OUT rule 10 state established enable
set firewall name ipv4 INSIDE-OUT rule 10 state related enable

set firewall name ipv4 INSIDE-OUT rule 20 action accept
set firewall name ipv4 INSIDE-OUT rule 20 destination port 80,443
set firewall name ipv4 INSIDE-OUT rule 20 protocol tcp

set firewall name ipv4 INSIDE-OUT rule 21 action accept
set firewall name ipv4 INSIDE-OUT rule 21 destination port 443
set firewall name ipv4 INSIDE-OUT rule 21 protocol tcp

set firewall name ipv4 INSIDE-OUT rule 30 action accept
set firewall name ipv4 INSIDE-OUT rule 30 destination port 53
set firewall name ipv4 INSIDE-OUT rule 30 protocol udp

# Strict NTP: Only DC (172.20.240.102) can talk to Google NTP
set firewall name ipv4 INSIDE-OUT rule 40 description 'Strict NTP for DC'
set firewall name ipv4 INSIDE-OUT rule 40 action accept
set firewall name ipv4 INSIDE-OUT rule 40 protocol udp
set firewall name ipv4 INSIDE-OUT rule 40 destination port 123
set firewall name ipv4 INSIDE-OUT rule 40 source address '172.20.240.102'
set firewall name ipv4 INSIDE-OUT rule 40 destination address '216.239.35.0/24'

# Lock down management
delete service ssh
delete service telnet
delete service lldp
delete service snmp

# Apply and save the configuration
commit
save
echo "Lockdown Complete. Exiting."
exit
