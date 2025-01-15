import std/unittest
import ../src/db, ../src/utils
import db_connector/db_sqlite

suite "Test CRUD functionality":
  setup:
    let dbConn = open(":memory:", "", "", "")
    initializeDatabase(dbConn)

  teardown:
    dbConn.close()

  test "insert recipe":
    let testRecipe = readRecipeFile("data/recipe_files/test.json")
    insertRecipe(testRecipe, dbConn)
    let insertedItem: string = dbConn.getValue(sql"SELECT title FROM Recipes")

    check "Test Recipe" == insertedItem
