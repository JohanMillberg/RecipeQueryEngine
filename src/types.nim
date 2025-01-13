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
    preparationTime*: int
    servings*: int
    tags*: seq[Tag]

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
  result = &"""
    Recipe: {recipe.title}
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    Preparation Time: {recipe.preparationTime} minutes
    Servings: {recipe.servings}

    Ingredients:
    {BulletPoint}{join(ingredients, "\n" & indent & BulletPoint)}

    Instructions:
    {BulletPoint}{join(recipe.instructions, "\n" & indent & BulletPoint)}

    Tags: {join(tagNames, Separator)}
  """
