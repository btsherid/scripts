#!/bin/bash

cd /tmp
sudo yum remove -y katello-ca-consumer-redhatsat.<redacted>
sudo curl -O http://redhatsat.<redacted>/pub/katello-ca-consumer-latest.noarch.rpm
sudo rpm -Uvh katello-ca-consumer-latest.noarch.rpm
sudo subscription-manager unregister
sudo subscription-manager register --org="ITS-Infrastructure" --activationkey="lccc-bioinformatics"

