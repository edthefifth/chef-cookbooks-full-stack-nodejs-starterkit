name              "aws"
maintainer        "Ed James"
maintainer_email  "ed@sullivation.com"
license           "Apache 2.0"
description       "Installs/Configures aws api"
version           "1.0.0"



recipe  "aws", "default recipe"
recipe  "aws::install", "recipe to install aws api commandline"

depends "yum"
depends "setup"
depends "nodejs"
