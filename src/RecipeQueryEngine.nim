import ./types, ./db, ./utils
import cligen
import jsony
import std/strutils

proc printRecipes(recipes: seq[Recipe]) =
  for recipe in recipes:
    echo recipe
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

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
  var recipes: seq[Recipe] = @[]

  case filter
  of FilterType.title:
    recipes = getRecipesByTitle(searchText)
  of FilterType.tag:
    recipes = getRecipesByTag(searchText)
  of FilterType.ingredient:
    echo "ingredient"
  of FilterType.time:
    echo "time"

  printRecipes(recipes)

# List recipes
proc listAllRecipes() =
  withTimer:
    let recipes = getAllRecipes()
    printRecipes(recipes)

when isMainModule:
  initializeDatabase()

  dispatchMulti(
    [addRecipe],
    [listAllRecipes],
    [deleteRecipe],
    [searchRecipes],
  )
