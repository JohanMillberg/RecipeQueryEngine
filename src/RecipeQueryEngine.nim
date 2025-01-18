import ./types, ./db, ./utils
import cligen
import jsony

proc readRecipeFile(filePath: string): Recipe =
  let content: string = readFile(filePath)
  let recipe = content.fromJson(Recipe)
  return recipe

# Add recipe
proc addRecipe(jsonFilePath: string) =
  let recipe = readRecipeFile(jsonFilePath)
  echo recipe
  recipe.insertRecipe

# Update recipe

# Delete recipe
proc deleteRecipe(recipeId: int) =
  withTimer:
    deleteRecipeWithId(recipeId)

# Search recipes

# List recipes
proc listAllRecipes() =
  withTimer:
    let recipes = getRecipeList()
    for recipe in recipes:
      echo recipe
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

when isMainModule:
  initializeDatabase()
  clearDatabase()

  dispatchMulti(
    [addRecipe],
    [listAllRecipes],
    [deleteRecipe]
  )
