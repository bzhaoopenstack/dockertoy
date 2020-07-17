#!/bin/bash

wget https://raw.githubusercontent.com/bzhaoopenstack/dockertoy/master/tests/ai/examples/train.py
wget https://raw.githubusercontent.com/bzhaoopenstack/dockertoy/master/tests/ai/examples/inference.py

python3 ./train.py -o ./test/ -e 5 -m testModel
python3 ./inference.py -m ./test/testModel
