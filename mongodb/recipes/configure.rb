# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.




include_recipe "mongodb::init_repl"
include_recipe "mongodb::security"
include_recipe "mongodb::secure_reconfigure" 
#include_recipe "mongodb::backup_configure"
include_recipe "mongodb::reindex"