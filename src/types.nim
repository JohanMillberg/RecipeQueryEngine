import std/[strformat, strutils, sequtils]

type
  Ingredient* = object
    id*: int
    recipeId*: int
    name*: string
    amount*: int
    unit*: string

  Tag* = object
    id*: int
    name*: string

  Recipe* = object
    id*: int
    title*: string
    ingredients*: seq[Ingredient]
    instructions*: seq[string]
    link*: string
    preparationTime*: int
    servings*: int
    tags*: seq[Tag]

  FilterType* = enum
    title = "title"
    tag = "tag"
    ingredient = "ingredient"
    time = "time"

proc `$`*(ingredient: Ingredient): string =
  result = &"{ingredient.amount} {ingredient.unit} {ingredient.name}"

proc `$`*(recipe: Recipe): string =
  const
    Separator = " | "
    IndentSize = 4
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
    if recipe.instructions == @[]:
      ""
    else:
      &"""Instructions:
    {BulletPoint}{join(recipe.instructions, "\n" & indent & BulletPoint)}
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
    {BulletPoint}{join(ingredients, "\n" & indent & BulletPoint)}
    {instructionString}
    {linkString}
    Tags: {join(tagNames, Separator)}
  """
