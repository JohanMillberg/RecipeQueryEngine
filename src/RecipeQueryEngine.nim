import ./types, ./db
import cligen

# Add recipe

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
  exampleRecipe.addRecipe

when isMainModule:
  initializeDatabase()
  clearDatabase()
  addExampleRecipe()
  let recipes = getRecipeList()
  for recipe in recipes:
    echo "Recipe: ", recipe.title
