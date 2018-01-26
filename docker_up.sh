#!/bin/bash
docker run -p 9990:9990 -v `pwd`/start.sh:/usr/local/beringei/start.sh --rm --privileged \
  tylermzeller/beringei_server:2016.11.07.00_1.1.1
