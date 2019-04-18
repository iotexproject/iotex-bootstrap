# 安全配置指导

任何公开的服务器都可能成为黑客的潜在目标。本指南提供了保护节点的基本说明和方法。

## 系统升级
在系统上启动任何操作之前，保持系统更新至关重要。这将阻止人们使用已知漏洞进入您的系统。
```
sudo apt-get update
sudo apt-get upgrade
sudo apt-get autoremove
sudo apt-get autoclean
```

## 使用防火墙
一个好的方法是安装防火墙。 UFW-防火墙是一个非常好用的基本防火墙。
```
sudo apt-get install ufw
sudo ufw allow ssh
# allow P2P and metrics ports
sudo ufw enable
sudo ufw status verbose
```

## 识别并验证开放端口
NMAP（“网络映射器”）是一种用于网络发现和安全审计的免费开源实用程序。了解某些端口是否按预期打开会很有用。
```
sudo apt-get install nmap
nmap -v -sT [NODE IP]
```

## SSH 强化
配置服务器时SSH非常有用，它也是黑客进入的第一站。这就是为什么保护SSH非常重要的原因。加强SSH的基本规则是：

- 不设置SSH访问密码（使用私钥）
- 不允许root用户进入SSH（相应的用户应该SSH，然后使用su或sudo）
- 为用户使用sudo，以便记录命令
- 记录未经授权的登录尝试（并考虑阻止/禁止试图访问您的服务器太多次的用户的软件，例如fail2ban）
- 将SSH锁定到您需要的ip范围（如果您愿意的话）

## 防止IP欺骗
```
sudo vi /etc/host.conf
order bind,hosts
nospoof on
```

## 保护共享内存
共享内存允许数据在应用程序之间传递。有时，多个进程可以共享相同的内存空间，这可能会导致漏洞利用。为了保护共享内存，
```
sudo nano /etc/fstab
# add the below line at the end of your file
tmpfs /run/shm tmpfs defaults,noexec,nosuid 0 0
```

## 防御网络攻击
为了防御服务器上的源路由攻击，
```
sudo nano  /etc/sysctl.conf
```
请确保设置以下命令：
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
之后使用`sudo systctl -p`重启服务
