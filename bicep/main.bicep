/*
  This is the main bicep entry file.

  10.19.22: Initial Version
--------------------------------
  - Establishing the Pipelines
*/

@description('Specify the Azure region to place the application definition.')
param location string = resourceGroup().location


@description('The region location.')
output greeting string = 'Region ${location}!'
