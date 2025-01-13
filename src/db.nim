import db_connector/db_sqlite
import std/strutils
import std/json
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
  withDb db_conn:
    for table in ["Ingredients", "Tags", "RecipeHasTag", "Recipes"]:
      db_conn.exec(sql"""DELETE FROM ?""", table)


proc initializeDatabase*() =
  withDb db_conn:
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
        name TEXT NOT NULL UNIQUE
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
  withDb db_conn:
    let getRecipesQuery = sql"""
    WITH IngredientLists AS (
      SELECT
          recipeId
        , json_group_array(
            json_object(
            'id', id,
            'recipeId', recipeId,
            'name', name,
            'amount', amount,
            'unit', unit
            )
          ) as ingredients
      FROM Ingredients
      GROUP BY recipeId
    ),
    TagList AS (
      SELECT
          rht.recipeId
        , json_group_array(
            json_object(
              'id', t.id,
              'name', t.name
            )
          ) as tags
      FROM RecipeHasTag rht
      INNER JOIN Tags t on t.id = rht.tagId
      GROUP BY rht.recipeId
    )
    SELECT
      r.id
    , r.title
    , r.timeInMinutes
    , r.instructions
    , r.servings
    , il.ingredients
    , COALESCE(tl.tags, '[]') as tags
    FROM Recipes r
    INNER JOIN IngredientLists il ON il.recipeId = r.id
    INNER JOIN TagList tl ON tl.recipeId = r.id
    """

    var recipes: seq[Recipe] = @[]
    for row in db_conn.fastRows(getRecipesQuery):
      let recipe = Recipe(
        id: row[0].parseInt,
        title: row[1],
        preparationTime: row[2].parseInt,
        instructions: row[3].splitLines,
        servings: row[4].parseInt,
        ingredients: parseJson(row[5]).to(seq[Ingredient]),
        tags: parseJson(row[6]).to(seq[Tag])
      )

      recipes.add recipe

    return recipes

proc insertRecipe*(recipe: Recipe) =
  withDb db_conn:
    let insertRecipeQuery = sql"""
    INSERT INTO Recipes (
      title,
      instructions,
      timeInMinutes,
      servings
    )
    VALUES (
      ?,
      ?,
      ?,
      ?
    )
    """
    let recipeId = db_conn.insertId(insertRecipeQuery,
      recipe.title,
      recipe.instructions.join("\n"),
      recipe.preparationTime,
      recipe.servings
    )

    let insertIngredientQuery = sql"""
      INSERT INTO Ingredients (
        name,
        recipeId,
        amount,
        unit
      ) VALUES (
        ?,
        ?,
        ?,
        ?
      )
    """
    for ingredient in recipe.ingredients:
      discard db_conn.insertId(insertIngredientQuery,
        ingredient.name,
        recipeId,
        ingredient.amount,
        ingredient.unit
      )

    # insert tag if it doesn't already exist
    let insertTagQuery = sql"""
      INSERT OR IGNORE INTO Tags (name)
      VALUES (?)
    """
    let selectTagQuery = sql"""
      SELECT id
      FROM Tags
      WHERE name = (?)
    """
    let insertRecipeTagQuery = sql"""
      INSERT INTO RecipeHasTag (
        recipeId,
        tagId
      ) VALUES (
        ?,
        ?
      )
    """

    for tag in recipe.tags:
      db_conn.exec(insertTagQuery, tag.name)
      let tagId = db_conn.getRow(selectTagQuery, tag.name)[0].parseInt
      discard db_conn.insertId(insertRecipeTagQuery, recipeId, tagId)


