# Package

version       = "0.1.0"
author        = "JohanMillberg"
description   = "Recipe Management System written in Nim"
license       = "MIT"
srcDir        = "src"
bin           = @["RecipeQueryEngine"]



# Dependencies

requires "nim >= 2.0.0"
requires "db_connector"
requires "cligen"
requires "jsony"
requires "norm"
