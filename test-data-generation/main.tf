locals {
  
  tags = {
    "region" : local.settings.region
    "env" : local.settings.env
    "nukeoptout" : true
    "Owner" : "rahul.grover@slalom.com"
  }
  
}