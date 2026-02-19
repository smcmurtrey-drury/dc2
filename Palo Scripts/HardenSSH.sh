configure
set deviceconfig system ssh ciphers mgmt aes256-ctr
set deviceconfig system ssh ciphers mgmt aes256-gcm@openssh.com
set deviceconfig system ssh mac-algorithms mgmt hmac-sha2-256
set deviceconfig system ssh mac-algorithms mgmt hmac-sha2-512
set deviceconfig system ssh kex-algorithms mgmt diffie-hellman-group14-sha256
set deviceconfig system ssh kex-algorithms mgmt diffie-hellman-group16-sha512
commit
