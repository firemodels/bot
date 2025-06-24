#!/bin/bash
#SBATCH -J matlab_hello
#SBATCH -o matlab_hello.o%j
#SBATCH -e matlab_hello.e%j
#SBATCH -t 00:01:00
#SBATCH -n 1
#SBATCH -p debug

module load matlab

matlab -batch "hello_world"
