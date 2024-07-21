################################################################################
# depegraph.cmake
#
# Author: [Himanshu Jangra]
# Date: [4-MArch-2024]
#
# Description:
#   	this dependecy graph will help to resolve the component dependency .
#
# Notes:
#       Please dont modify existing CMAKE function and commands unless highly required 
# 		 Additional notes
#
################################################################################
# [Contents of the file below]
# check for minimum cmake version to run this script
cmake_minimum_required(VERSION 3.2.1)


# @name depgraph_get_required_components     
#   
# @param0  comp_in  
# @param1  comp_out
# @note    used to get the required components based on the input components
#           this will traverse the dependecy graph and will search for usefull components
# @usage   usage  
# @scope  scope   
# scope tells where should this cmake function used 
# 
function(depgrah_get_required_components  comp_in comp_out)
    
endfunction()




# @name depgraph_sort_components     
#   
# @param0  comps_in
# @param1  comps_out
# @note    used to sort the components and also to remove the duplicates 
#           from it    
# @usage   usage  
# @scope  scope   
# scope tells where should this cmake function used 
# 
function(depegraph_sort_components comps_in comps_out)
    
endfunction()