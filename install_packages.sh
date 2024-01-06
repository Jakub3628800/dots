#!/bin/bash
ansible-playbook ansible/install-packages.yaml -i ansible/hosts --ask-become-pass
