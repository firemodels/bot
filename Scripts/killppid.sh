#!/bin/bash
echo killing process id: $1 and all children
pkill -P $1
