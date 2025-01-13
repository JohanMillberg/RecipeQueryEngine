import ./types, ./db
import cligen

# Add recipe

# Update recipe

# Delete recipe

# Search recipes

# List recipes

when isMainModule:
  initializeDatabase()
  let recipes = getRecipeList()
  for recipe in recipes:
    echo "Recipe: ", recipe.title
