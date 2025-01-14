import ./types, ./db, ./utils
import cligen
import jsony

proc readRecipeFile(filePath: string): Recipe =
  let content: string = readFile(filePath)
  let recipe = content.fromJson(Recipe)
  return recipe

# Add recipe
proc addRecipe(textFilePath: string) =
  let recipe = readRecipeFile(textFilePath)
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

proc addExampleRecipe() =
  let exampleRecipe = Recipe(
    title: "Test recipe",
    instructions: @["Instruction1", "Instruction2"],
    preparationTime: 20,
    servings: 4,
    tags: @[Tag(name: "Tag1"), Tag(name: "Tag2")],
    ingredients: @[
      Ingredient(name: "Sugar", amount: 2, unit: "dl"),
      Ingredient(name: "Eggs", amount: 1000)
    ]
  )
  exampleRecipe.insertRecipe

when isMainModule:
  initializeDatabase()
  # clearDatabase()

  dispatchMulti(
    [addRecipe],
    [listAllRecipes],
    [deleteRecipe]
  )
