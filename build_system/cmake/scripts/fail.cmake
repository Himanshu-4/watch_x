################################################################################
# fail.cmake
#
# Author: [Himanshu Jangra]
# Date: [23-Feb-2024]
#
# Description:
#   	called when cmake wants to fail at build time and reruns .
#
# Notes:
#       Please dont modify existing CMAKE function and commands unless highly required 
# 		 Additional notes
#
################################################################################
# [Contents of the file below]
# check for minimum cmake version to run this script

# 'cmake -E' doesn't have a way to fail outright, so run this script
# with 'cmake -P' to fail a build.
message(FATAL_ERROR "$ENV{FAIL_MESSAGE}")
