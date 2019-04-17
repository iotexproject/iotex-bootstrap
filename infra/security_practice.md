# Best Security Practice

Any server exposed to the public can become a potential target to hackers. This guide provides basic instructions and tips for securing the nodes.

## System Updates
Keeping the system updated is vital before starting anything on your system. This will prevent people to use known vulnerabilities to enter in your system.
```
sudo apt-get update
sudo apt-get upgrade
sudo apt-get autoremove
sudo apt-get autoclean
```

## Enable Firewall
A good place to start is to install a Firewall. UFW - Uncomplicated Firewall is a basic firewall that works very well.
```
sudo apt-get install ufw
sudo ufw allow ssh
# allow P2P and metrics ports
sudo ufw enable
sudo ufw status verbose
```

## Identify and Verify Open Ports
NMAP ("Network Mapper") is a free and open source utility for network discovery and security auditing. It would be useful to understand if certain ports are open as expected.
```
sudo apt-get install nmap
nmap -v -sT [NODE IP]
```

## SSH Hardening
SSH can be very helpful when configuring your server, and it also one of the first point of entry of hackers. This is why it is very important to secure your SSH. The basic rules of hardening SSH are:

- No password for SSH access (use private key)
- Don't allow root to SSH (the appropriate users should SSH in, then su or sudo)
- Use sudo for users so commands are logged
- Log unauthorised login attempts (and consider software to block/ban users who try to access your server too many times, like fail2ban)
- Lock down SSH to only the ip range your require (if you feel like it)


## Prevent IP Spoofing
```
sudo vi /etc/host.conf
order bind,hosts
nospoof on
```

## Secure Shared Memory
Shared memory allows data to be passed between applications. Sometimes, multiple processes can share the same memory space and this can lead to exploitation. To secure shared memory,
```
sudo nano /etc/fstab
# add the below line at the end of your file
tmpfs /run/shm tmpfs defaults,noexec,nosuid 0 0
```

## Defending Network Attacks
To prevent a source routing attack on your server,
```
sudo nano  /etc/sysctl.conf
```
 and make sure the following values are set:
```
# IP Spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
# Ignore ICMP broadcast requests
net.ipv4.icmp_echo_ignore_broadcasts = 1
# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0
# Ignore send redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
# Block SYN attacks
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5
# Log Martians
net.ipv4.conf.all.log_martians = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
# Ignore Directed pings
net.ipv4.icmp_echo_ignore_all = 1
```
then restart the service with `sudo systctl -p`.
