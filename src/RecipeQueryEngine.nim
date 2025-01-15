import ./types, ./db, ./utils
import cligen
import jsony
import db_connector/db_sqlite

const DatabasePath = "data/recipes.db"
var dbConn* = open(DatabasePath, "", "", "")

proc readRecipeFile(filePath: string): Recipe =
  let content: string = readFile(filePath)
  let recipe = content.fromJson(Recipe)
  return recipe

# Add recipe
proc addRecipe(jsonFilePath: string) =
  let recipe = readRecipeFile(jsonFilePath)
  echo recipe
  recipe.insertRecipe(dbConn)

# Update recipe

# Delete recipe
proc deleteRecipe(recipeId: int) =
  withTimer:
    deleteRecipeWithId(recipeId, dbConn)

# Search recipes

# List recipes
proc listAllRecipes() =
  withTimer:
    let recipes = getRecipeList(dbConn)
    for recipe in recipes:
      echo recipe
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"


when isMainModule:
  initializeDatabase(dbConn)
  clearDatabase(dbConn)

  dispatchMulti(
    [addRecipe],
    [listAllRecipes],
    [deleteRecipe]
  )

  dbConn.close()
