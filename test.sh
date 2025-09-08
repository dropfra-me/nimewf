#!/bin/bash

#this is wrapper for lima development virtual machine, use this to test the library in proper environment

limactl shell ubuntu rm -rf /tmp/nimewf_*
limactl shell ubuntu nimble test --verbose
