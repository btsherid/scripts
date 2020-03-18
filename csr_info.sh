#!/bin/bash

################################
# csr_info.sh
#
# Usage: csr_info.sh <path to CSR>


openssl req -in $* -noout -text


