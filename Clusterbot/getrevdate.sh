#!/bin/bash
ls -l --time-style=long-iso /etc/redhat-release | awk '{print $6}'
