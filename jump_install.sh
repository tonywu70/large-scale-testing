#!/bin/bash
echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
service sshd restart
