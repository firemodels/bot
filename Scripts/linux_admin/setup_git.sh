#!/bin/bash

user=`whoami`
email=$user@gmail.com

git config --global user.name $user
git config --global user.email $email
git config --global --add color.ui true
