import std/[strformat, strutils, sequtils]
import norm/[model, pragmas]

type
  Ingredient* = ref object of Model
    name*: string
    amount*: int
    unit*: string

  Tag* = ref object of Model
    name* {.unique.}: string

  Recipe* = ref object of Model
    title*: string
    instructions*: string
    link*: string
    preparationTime*: int
    servings*: int

  RecipeHasTag* = ref object of Model
    tag* {.uniqueGroup.}: Tag
    recipe* {.uniqueGroup.}: Recipe

  IngredientInRecipe* = ref object of Model
    ingredient*: Ingredient
    recipe*: Recipe

  PrettyRecipe* = ref object of Recipe
    ingredients*: seq[Ingredient] 
    tags*: seq[Tag] 

  FilterType* = enum
    title = "title"
    tag = "tag"
    ingredient = "ingredient"
    time = "time"

proc `$`*(ingredient: Ingredient): string =
  result = &"{ingredient.amount} {ingredient.unit} {ingredient.name}"

proc `$`*(recipe: PrettyRecipe): string =
  const
    Separator = " | "
    IndentSize = 6
    BulletPoint = "* "

  let ingredients = recipe.ingredients.mapIt($it)
  let tagNames = recipe.tags.mapIt(it.name)
  let indent = " ".repeat(IndentSize)

  let idString =
    if recipe.id == 0:
      ""
    else:
      &"(Id: {recipe.id})"

  let instructionString =
      &"""
{indent}{BulletPoint}{join(recipe.instructions.splitLines, "\n" & indent & BulletPoint)}
      """

  let linkString =
    if recipe.link == "":
      ""
    else:
      &"Link: {recipe.link}"

  result = &"""
    Recipe: {recipe.title} {idString}
    Preparation Time: {recipe.preparationTime} minutes
    Servings: {recipe.servings}

    Ingredients:
{indent}{BulletPoint}{join(ingredients, "\n" & indent & BulletPoint)}
    Instructions:
{instructionString}
    {linkString}
    Tags: {join(tagNames, Separator)}
  """
