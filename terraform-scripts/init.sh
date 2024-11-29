#!/bin/bash
sleep 10

sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get install -y build-essential || exit 1
sudo apt-get install -y openmpi-bin openmpi-doc libopenmpi-dev libsdl2-dev || exit 1
cd /home/davide/ 
git clone https://github.com/ferraridavide/aca-project
cd aca-project/c-ray 
make || exit 1
make lib || exit 1
export LD_LIBRARY_PATH=../c-ray/lib:$LD_LIBRARY_PATH
mkdir /home/davide/data/
mkdir /home/davide/data/output/
cd /home/davide/aca-project/src-cray-demo
make || exit 1