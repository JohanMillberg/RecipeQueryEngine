import std/[strutils, tables, sequtils, strformat]
import std/json
import norm/[sqlite, model]
import ./types

const databasePath = "data/recipes.db"

template withTransaction*(db: DbConn, body: untyped) =
  db.exec(sql"BEGIN")
  try:
    body
  except Exception:
    db.exec(sql"ROLLBACK")
    raise
  db.exec(sql"COMMIT")

template withConnection*(variableName: untyped, body: untyped) =
  let `variableName` {.inject.} = open(databasePath, "", "", "")
  try:
    body
  finally:
    variableName.close()

template withDb*(variableName: untyped, body: untyped) =
  ## Combines `withConnection` and `withTransaction` for convinience
  withConnection variableName:
    withTransaction variableName:
      body

proc clearDatabase*() =
  withDb dbConn:
    discard

proc initializeDatabase*() =
  withDb dbConn:
    dbConn.createTables(Tag())
    dbConn.createTables(Ingredient())
    dbConn.createTables(Recipe())
    dbConn.createTables(RecipeHasTag(tag: Tag(), recipe: Recipe()))
    dbConn.createTables(IngredientInRecipe(ingredient: Ingredient(), recipe: Recipe()))

proc getAllRecipes*(): seq[Recipe] =
  withDb dbConn:
    result = dbConn.selectAll(Recipe)

proc getRecipesByTitle*(filter: string): seq[Recipe] =
  withDb dbConn:
    discard

proc getRecipesByTag*(filter: string): seq[Recipe] =
  withDb dbConn:
    discard

proc insertRecipe*(prettyRecipe: PrettyRecipe) =
  withDb dbConn:
    var recipe = prettyRecipe.Recipe
    dbConn.insert(recipe)

    for ingredient in prettyRecipe.ingredients.mitems:
      dbConn.insert(ingredient)

      var ingredientInRecipe = IngredientInRecipe(
        ingredient: ingredient,
        recipe: recipe
      )

      dbConn.insert(ingredientInRecipe)

    for tag in prettyRecipe.tags.mitems:
      dbConn.insert(tag)

      var recipeHasTag = RecipeHasTag(
        tag: tag,
        recipe: recipe
      )

      dbConn.insert(recipeHasTag)
       
     

proc deleteRecipeWithId*(recipeId: int) =
  withDb dbConn:
    discard
