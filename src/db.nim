import db_connector/db_sqlite
import std/[strutils, tables]
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
  withDb dbConn:
    for table in ["Ingredients", "Tags", "RecipeHasTag", "Recipes"]:
      dbConn.exec(sql"""DELETE FROM ?""", table)

proc initializeDatabase*() =
  withDb dbConn:
    let ingredientsInitQuery = sql"""
      CREATE TABLE IF NOT EXISTS Ingredients (
        id       INTEGER PRIMARY KEY,
        name     TEXT NOT NULL,
        recipeId INTEGER NOT NULL,
        amount   INTEGER NOT NULL,
        unit     TEXT
      )
    """
    dbConn.exec(ingredientsInitQuery)

    let tagInitQuery = sql"""
      CREATE TABLE IF NOT EXISTS Tags (
        id   INTEGER PRIMARY KEY,
        name TEXT NOT NULL UNIQUE
      )
    """
    dbConn.exec(tagInitQuery)

    let recipeTagInitQuery = sql"""
      CREATE TABLE IF NOT EXISTS RecipeHasTag (
        id       INTEGER PRIMARY KEY,
        recipeId INTEGER NOT NULL,
        tagId    INTEGER NOT NULL
      )
    """
    dbConn.exec(recipeTagInitQuery)

    let recipeInitQuery = sql"""
      CREATE TABLE IF NOT EXISTS Recipes (
        id            INTEGER PRIMARY KEY,
        title         TEXT NOT NULL,
        instructions  TEXT,
        link          TEXT,
        timeInMinutes INTEGER,
        servings      INTEGER
      )
    """
    dbConn.exec(recipeInitQuery)

proc getIngredients(dbConn: DbConn, recipeIds: seq[int]): Table[int, seq[Ingredient]] =
  # CURRENTLY RETURNS EMPTY TABLE, FIX
  let ingredientQuery = sql"""
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
    WHERE recipeId IN (?)
    GROUP BY recipeId
  """

  var ingredientMap = initTable[int, seq[Ingredient]]()
  for row in dbConn.fastRows(ingredientQuery, recipeIds.join(", ")):
    let currentId = row[0].parseInt
    let ingredients = parseJson(row[1]).to(seq[Ingredient])
    ingredientMap[currentId] = ingredients

  return ingredientMap

proc getTags(dbConn: DbConn, recipeIds: seq[int]): Table[int, seq[Tag]] =
  let tagQuery = sql"""
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
    WHERE rht.recipeId IN (?)
    GROUP BY rht.recipeId
  """

  var tagMap = initTable[int, seq[Tag]]()
  for row in dbConn.fastRows(tagQuery, recipeIds.join(", ")):
    let currentId = row[0].parseInt
    let tags = parseJson(row[1]).to(seq[Tag])
    tagMap[currentId] = tags

  return tagMap

proc getRecipeList*(): seq[Recipe] =
  withDb dbConn:
    var recipeIds: seq[int] = @[]
    for row in dbConn.fastRows(sql"SELECT id FROM Recipes"):
      recipeIds.add(row[0].parseInt)

    let ingredientMap = getIngredients(dbConn, recipeIds)
    let tagMap = getTags(dbConn, recipeIds)

    echo ingredientMap
    echo tagMap

    let getRecipesQuery = sql"""
      SELECT
          r.id
        , r.title
        , r.timeInMinutes
        , r.instructions
        , r.link
        , r.servings
      FROM Recipes r
    """

    var recipes: seq[Recipe] = @[]
    for row in dbConn.fastRows(getRecipesQuery):
      let currentId = row[0].parseInt
      let recipe = Recipe(
        id: currentId,
        title: row[1],
        preparationTime: row[2].parseInt,
        instructions: row[3].splitLines,
        link: row[4],
        servings: row[5].parseInt,
        ingredients: ingredientMap[currentId],
        tags: tagMap[currentId]
      )

      recipes.add recipe

    return recipes

proc insertRecipe*(recipe: Recipe) =
  withDb dbConn:
    let insertRecipeQuery = sql"""
    INSERT INTO Recipes (
      title,
      instructions,
      link,
      timeInMinutes,
      servings
    )
    VALUES (
      ?,
      ?,
      ?,
      ?,
      ?
    )
    """
    let recipeId = dbConn.insertId(insertRecipeQuery,
      recipe.title,
      recipe.instructions.join("\n"),
      recipe.link,
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
      discard dbConn.insertId(insertIngredientQuery,
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
      dbConn.exec(insertTagQuery, tag.name)
      let tagId = dbConn.getRow(selectTagQuery, tag.name)[0].parseInt
      discard dbConn.insertId(insertRecipeTagQuery, recipeId, tagId)

proc deleteRecipeWithId*(recipeId: int) =
  withDb dbConn:
    let deleteQueryRecipes = sql"""
      DELETE FROM Recipes
      WHERE id = (?)
    """
    let deleteQueryIngredients = sql"""
      DELETE FROM Ingredients
      WHERE recipeId = (?)
    """
    let deleteQueryTags = sql"""
      DELETE FROM RecipeHasTag
      WHERE recipeId = (?);

      DELETE FROM Tags
      WHERE id NOT IN (
        SELECT DISTINCT tagId
        FROM RecipeHasTag
      )
    """

    let queries = @[
      deleteQueryRecipes,
      deleteQueryIngredients,
      deleteQueryTags
    ]

    for query in queries:
      dbConn.exec(query, recipeId)
