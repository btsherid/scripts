#!/bin/bash

################################
# cert_info.sh
#
# Usage: certificate_info.sh <path to cert>


openssl x509 -in $* -noout -text


