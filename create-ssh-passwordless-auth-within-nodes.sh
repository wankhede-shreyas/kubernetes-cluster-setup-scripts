#!/bin/bash

# This script sets up a simple CentOS cluster with passwordless SSH access between nodes.

# Setup SSH key for passwordless access (optional but recommended)
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
for node in centos2 centos3; do
  ssh-copy-id vagrant@$node
done