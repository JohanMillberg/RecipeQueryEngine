import ./types, ./db, ./utils
import cligen
import jsony
import std/strutils

proc readRecipeFile(filePath: string): Recipe =
  let content: string = readFile(filePath)
  let recipe = content.fromJson(Recipe)
  return recipe

# Add recipe
proc addRecipe(jsonFilePath: string) =
  let recipe = readRecipeFile(jsonFilePath)
  echo recipe
  recipe.insertRecipe

# Delete recipe
proc deleteRecipe(recipeId: int) =
  withTimer:
    deleteRecipeWithId(recipeId)

# Search recipes
proc searchRecipes(searchText: string, filterType: string) =
  let filter = parseEnum[FilterType](filterType)
  case filter
  of FilterType.title:
    echo "title"
  of FilterType.tag:
    echo "tag"
  of FilterType.ingredient:
    echo "ingredient"
  of FilterType.time:
    echo "time"

# List recipes
proc listAllRecipes() =
  withTimer:
    let recipes = getRecipeList()
    for recipe in recipes:
      echo recipe
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

when isMainModule:
  initializeDatabase()

  dispatchMulti(
    [addRecipe],
    [listAllRecipes],
    [deleteRecipe],
    [searchRecipes],
  )
