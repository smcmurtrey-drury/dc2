configure

# DNS — locked to internal DNS server only
set rulebase security rules ALLOW-OUTBOUND-DNS from inside
set rulebase security rules ALLOW-OUTBOUND-DNS to outside
set rulebase security rules ALLOW-OUTBOUND-DNS source any
set rulebase security rules ALLOW-OUTBOUND-DNS destination 172.20.240.102
set rulebase security rules ALLOW-OUTBOUND-DNS application dns
set rulebase security rules ALLOW-OUTBOUND-DNS service application-default
set rulebase security rules ALLOW-OUTBOUND-DNS action allow
set rulebase security rules ALLOW-OUTBOUND-DNS log-end yes
set rulebase security rules ALLOW-OUTBOUND-DNS profile-setting group CCDC-STRICT

# HTTP/HTTPS
set rulebase security rules ALLOW-OUTBOUND-WEB from inside
set rulebase security rules ALLOW-OUTBOUND-WEB to outside
set rulebase security rules ALLOW-OUTBOUND-WEB source any
set rulebase security rules ALLOW-OUTBOUND-WEB destination any
set rulebase security rules ALLOW-OUTBOUND-WEB application [ web-browsing ssl ]
set rulebase security rules ALLOW-OUTBOUND-WEB service application-default
set rulebase security rules ALLOW-OUTBOUND-WEB action allow
set rulebase security rules ALLOW-OUTBOUND-WEB log-end yes
set rulebase security rules ALLOW-OUTBOUND-WEB profile-setting group CCDC-STRICT

# SMTP
set rulebase security rules ALLOW-OUTBOUND-SMTP from inside
set rulebase security rules ALLOW-OUTBOUND-SMTP to outside
set rulebase security rules ALLOW-OUTBOUND-SMTP source any
set rulebase security rules ALLOW-OUTBOUND-SMTP destination any
set rulebase security rules ALLOW-OUTBOUND-SMTP application smtp
set rulebase security rules ALLOW-OUTBOUND-SMTP service application-default
set rulebase security rules ALLOW-OUTBOUND-SMTP action allow
set rulebase security rules ALLOW-OUTBOUND-SMTP log-end yes
set rulebase security rules ALLOW-OUTBOUND-SMTP profile-setting group CCDC-STRICT

# NTP
set rulebase security rules ALLOW-OUTBOUND-NTP from inside
set rulebase security rules ALLOW-OUTBOUND-NTP to outside
set rulebase security rules ALLOW-OUTBOUND-NTP source any
set rulebase security rules ALLOW-OUTBOUND-NTP destination any
set rulebase security rules ALLOW-OUTBOUND-NTP application ntp
set rulebase security rules ALLOW-OUTBOUND-NTP service application-default
set rulebase security rules ALLOW-OUTBOUND-NTP action allow
set rulebase security rules ALLOW-OUTBOUND-NTP log-end yes

# ICMP
set rulebase security rules ALLOW-OUTBOUND-ICMP from inside
set rulebase security rules ALLOW-OUTBOUND-ICMP to outside
set rulebase security rules ALLOW-OUTBOUND-ICMP source any
set rulebase security rules ALLOW-OUTBOUND-ICMP destination any
set rulebase security rules ALLOW-OUTBOUND-ICMP application icmp
set rulebase security rules ALLOW-OUTBOUND-ICMP service application-default
set rulebase security rules ALLOW-OUTBOUND-ICMP action allow
set rulebase security rules ALLOW-OUTBOUND-ICMP log-end yes

# POP3 (scored per packet)
set rulebase security rules ALLOW-OUTBOUND-POP3 from inside
set rulebase security rules ALLOW-OUTBOUND-POP3 to outside
set rulebase security rules ALLOW-OUTBOUND-POP3 source any
set rulebase security rules ALLOW-OUTBOUND-POP3 destination any
set rulebase security rules ALLOW-OUTBOUND-POP3 application pop3
set rulebase security rules ALLOW-OUTBOUND-POP3 service application-default
set rulebase security rules ALLOW-OUTBOUND-POP3 action allow
set rulebase security rules ALLOW-OUTBOUND-POP3 log-end yes
set rulebase security rules ALLOW-OUTBOUND-POP3 profile-setting group CCDC-STRICT

# CATCH-ALL DENY — must be last
set rulebase security rules BLOCK-OUTBOUND-ALL from inside
set rulebase security rules BLOCK-OUTBOUND-ALL to outside
set rulebase security rules BLOCK-OUTBOUND-ALL source any
set rulebase security rules BLOCK-OUTBOUND-ALL destination any
set rulebase security rules BLOCK-OUTBOUND-ALL application any
set rulebase security rules BLOCK-OUTBOUND-ALL service any
set rulebase security rules BLOCK-OUTBOUND-ALL action deny
set rulebase security rules BLOCK-OUTBOUND-ALL log-end yes

# Order the rules correctly
move rulebase security rules ALLOW-OUTBOUND-DNS top
move rulebase security rules ALLOW-OUTBOUND-WEB after ALLOW-OUTBOUND-DNS
move rulebase security rules ALLOW-OUTBOUND-SMTP after ALLOW-OUTBOUND-WEB
move rulebase security rules ALLOW-OUTBOUND-NTP after ALLOW-OUTBOUND-SMTP
move rulebase security rules ALLOW-OUTBOUND-ICMP after ALLOW-OUTBOUND-NTP
move rulebase security rules ALLOW-OUTBOUND-POP3 after ALLOW-OUTBOUND-ICMP
move rulebase security rules BLOCK-OUTBOUND-ALL bottom

commit