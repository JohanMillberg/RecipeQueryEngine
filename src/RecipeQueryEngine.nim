import ./types, ./db
import cligen
import jsony

proc readRecipeFile(file_path: string): Recipe =
  let content: string = readFile(file_path)
  let recipe = content.fromJson(Recipe)
  return recipe

# Add recipe
proc addRecipe(text_file_path: string) =
  let recipe = readRecipeFile(text_file_path)
  echo recipe
  recipe.insertRecipe

# Update recipe

# Delete recipe

# Search recipes

# List recipes

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
  clearDatabase()

  dispatchMulti([
    addRecipe
  ])
