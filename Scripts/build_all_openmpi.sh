#!/bin/bash 
./build_openmpi.sh -r -c intel15 -e -m 1.8.4 
./build_openmpi.sh -r -c intel16 -e -m 1.8.4 
./build_openmpi.sh -r -c intel17 -e -m 1.8.4 
./build_openmpi.sh -r -c intel15 -i -m 1.8.4 
./build_openmpi.sh -r -c intel16 -i -m 1.8.4 
./build_openmpi.sh -r -c intel17 -i -m 1.8.4 
./build_openmpi.sh -r -c intel15 -e -m 2.0.1
./build_openmpi.sh -r -c intel16 -e -m 2.0.1
./build_openmpi.sh -r -c intel17 -e -m 2.0.1
./build_openmpi.sh -r -c intel15 -i -m 2.0.1
./build_openmpi.sh -r -c intel16 -i -m 2.0.1
./build_openmpi.sh -r -c intel17 -i -m 2.0.1
