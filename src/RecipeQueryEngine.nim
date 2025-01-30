import ./types, ./db, ./utils
import cligen
import jsony
import std/strutils

proc printRecipes(recipes: seq[PrettyRecipe]) =
  for recipe in recipes:
    echo recipe
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

proc readRecipeFile(filePath: string): PrettyRecipe =
  let content: string = readFile(filePath)
  let recipe = content.fromJson(PrettyRecipe)
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
  var recipes: seq[PrettyRecipe] = @[]

  case filter
  of FilterType.title:
    echo "title"
  of FilterType.tag:
    echo "tag"
  of FilterType.ingredient:
    echo "ingredient"
  of FilterType.time:
    echo "time"

  printRecipes(recipes)

# List recipes
proc listAllRecipes() =
  withTimer:
    let recipes = getAllRecipes()
    # printRecipes(recipes)

when isMainModule:
  initializeDatabase()

  dispatchMulti(
    [addRecipe],
    [listAllRecipes],
    [deleteRecipe],
    [searchRecipes],
  )
