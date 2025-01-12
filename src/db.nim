import db_connector/db_sqlite
import std/tables
import ./types
import std/strutils
import std/sequtils

const databasePath = "data/recipes.db"

let db_conn = open(databasePath, "", "", "")

proc initializeDatabase*() =
  let ingredientsInitQuery = sql"""
    CREATE TABLE IF NOT EXISTS Ingredients (
      id       INTEGER PRIMARY KEY,
      name     TEXT NOT NULL,
      recipeId INTEGER NOT NULL,
      amount   INTEGER NOT NULL,
      unit     TEXT
    )
  """
  db_conn.exec(ingredientsInitQuery)

  let tagInitQuery = sql"""
    CREATE TABLE IF NOT EXISTS Tags (
      id   INTEGER PRIMARY KEY,
      name TEXT NOT NULL
    )
  """
  db_conn.exec(tagInitQuery)

  let recipeTagInitQuery = sql"""
    CREATE TABLE IF NOT EXISTS RecipeHasTag (
      id       INTEGER PRIMARY KEY,
      recipeId INTEGER NOT NULL,
      tagId    INTEGER NOT NULL
    )
  """
  db_conn.exec(recipeTagInitQuery)

  let recipeInitQuery = sql"""
    CREATE TABLE IF NOT EXISTS Recipes (
      id            INTEGER PRIMARY KEY,
      title         TEXT NOT NULL,
      instructions  TEXT NOT NULL,
      timeInMinutes INTEGER,
      servings      INTEGER
    )
  """
  db_conn.exec(recipeInitQuery)

proc getRecipeList*(): seq[Recipe] =
  let getRecipesQuery = sql"""
  SELECT 
     r.id
   , r.title
   , r.timeInMinutes
   , r.instructions
   , r.servings
   , i.name
   , i.amount
   , i.unit
  FROM Recipes r
  INNER JOIN Ingredients i ON i.recipeId = r.id
  """

  var recipes: Table[int, Recipe]
  for row in db_conn.fastRows(getRecipesQuery):
    let id = row[0].parseInt
    if id notin recipes:
      recipes[id] = Recipe(
        id: id,
        title: row[1],
        preparationTime: row[2].parseInt,
        instructions: splitLines(row[3]),
        servings: row[4].parseInt,
      )
    let ingredient = Ingredient(
      name: row[5],
      amount: row[6].parseInt,
      unit: row[7]
    )

    recipes[id].ingredients.add ingredient

  return recipes.values.toSeq
