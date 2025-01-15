import db_connector/db_sqlite
import std/strutils
import std/json
import ./types


template withTransaction*(db: DbConn, body: untyped) =
  db.exec(sql"BEGIN")
  try:
    body
  except Exception:
    db.exec(sql"ROLLBACK")
    raise
  db.exec(sql"COMMIT")


proc clearDatabase*(dbConn: DbConn) =
  withTransaction dbConn:
    for table in ["Ingredients", "Tags", "RecipeHasTag", "Recipes"]:
      dbConn.exec(sql"""DELETE FROM ?""", table)


proc initializeDatabase*(dbConn: DbConn) =
  withTransaction dbConn:
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
        instructions  TEXT NOT NULL,
        timeInMinutes INTEGER,
        servings      INTEGER
      )
    """
    dbConn.exec(recipeInitQuery)


proc getRecipeList*(dbConn: DbConn): seq[Recipe] =
  withTransaction dbConn:
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
    for row in dbConn.fastRows(getRecipesQuery):
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


proc insertRecipe*(recipe: Recipe, dbConn: DbConn) =
  withTransaction dbConn:
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
    let recipeId = dbConn.insertId(insertRecipeQuery,
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


proc deleteRecipeWithId*(recipeId: int, dbConn: DbConn) =
  withTransaction dbConn:
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
