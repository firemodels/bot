#!/bin/bash

user=`whoami`
email=$user@gmail.com
echo user=$user
echo email=$email
git config --global user.name $user
git config --global user.email $email
git config --global --add color.ui true
git config --global core.editor vim
