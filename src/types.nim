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
