helpers     = require 'helpers'

Environment = require 'models/environment'
Species     = require 'models/species'
Agent       = require 'models/agent'
Rule        = require 'models/rule'
Trait       = require 'models/trait'
Interactive = require 'ui/interactive'
Events      = require 'events'
ToolButton  = require 'ui/tool-button'
BasicAnimal = require 'models/agents/basic-animal'

plantSpecies  = require 'species/fast-plants-roots'
rabbitSpecies = require 'species/white-brown-rabbits'
hawkSpecies   = require 'species/hawks'
env           = require 'environments/snow'

window.model =
  brownness: 0
  run: ->
    @interactive = new Interactive
      environment: env
      speedSlider: true
      addOrganismButtons: [
        {
          species: plantSpecies
          imagePath: "images/agents/grass/tallgrass.png"
          traits: [          ]
          limit: 180
          scatter: 45
        }
        {
          species: rabbitSpecies
          imagePath: "images/agents/rabbits/sandrat-light.png"
          traits: [
            new Trait {name: "mating desire bonus", default: -20}
            new Trait {name: "hunger bonus", default: -10}
            new Trait {name: "age", default: 3}
            new Trait {name: "resource consumption rate", default: 10}
          ]
          limit: 30
          scatter: 30
        }
        {
          species: hawkSpecies
          imagePath: "images/agents/hawks/hawk.png"
          traits: [
            new Trait {name: "mating desire bonus", default: -10}
          ]
          limit: 2
          scatter: 2
        }
      ]
      toolButtons: [
        {
          type: ToolButton.INFO_TOOL
        }
      ]

    document.getElementById('environment').appendChild @interactive.getEnvironmentPane()

    @env = env
    @plantSpecies = plantSpecies
    @hawkSpecies = hawkSpecies
    @rabbitSpecies = rabbitSpecies

    env.addRule new Rule
      action: (agent) =>
        if agent.species is rabbitSpecies
          if agent.get('color') is 'brown'
            agent.set 'chance of being seen', (0.6 - (@brownness*0.6))
          else
            agent.set 'chance of being seen', (@brownness*0.6)

  setupGraph: ->
    outputOptions =
      title:  "Number of rabbits"
      xlabel: "Time (s)"
      ylabel: "Number of rabbits"
      xmax:   100
      xmin:   0
      ymax:   50
      ymin:   0
      xTickCount: 10
      yTickCount: 10
      xFormatter: "2d"
      yFormatter: "2d"
      realTime: false
      fontScaleRelativeToParent: true
      sampleInterval: (Environment.DEFAULT_RUN_LOOP_DELAY/1000)
      dataType: 'samples'
      dataColors: [
        [153, 153, 153]
        [153,  85,   0]
        [255,   0,   0]
      ]

    @outputGraph = LabGrapher '#graph', outputOptions

    Events.addEventListener Environment.EVENTS.RESET, =>
      @outputGraph.reset()

    Events.addEventListener Environment.EVENTS.STEP, =>
      @outputGraph.addSamples @countRabbits()

  agentsOfSpecies: (species)->
    set = []
    for a in @env.agents
      set.push a if a.species is species
    return set

  countRabbits: ->
    whiteRabbits = 0
    brownRabbits = 0
    for a in @agentsOfSpecies(@rabbitSpecies)
      whiteRabbits++ if a.get('color') is 'white'
      brownRabbits++ if a.get('color') is 'brown'
    return [whiteRabbits, brownRabbits]

  changeBackground: (n)->
    return unless 0 < n < 10
    @env.setBackground("images/environments/snow-#{n}.png")

  showMessage: (message, callback) ->
    helpers.showMessage message, @env.getView().view.parentElement, callback

  setupPopulationControls: ->
    Events.addEventListener Environment.EVENTS.STEP, =>
      @checkPlants()
      @checkRabbits()
      @checkHawks()

  setupControls: ->
    switchButton = document.getElementById('switch-env')
    switchButton.onclick = =>
      if @brownness
        @brownness = 0
        @env.setBackground("images/environments/snow.png")
      else
        @brownness = 1
        @env.setBackground("images/environments/snow-9.png")

  setProperty: (agents, prop, val)->
    for a in agents
      a.set prop, val

  addAgent: (species, properties=[], traits=[])->
    agent = species.createAgent(traits)
    agent.setLocation @env.randomLocation()
    for prop in properties
      agent.set prop[0], prop[1]
    @env.addAgent agent


  addedRabbits: false
  addedHawks: false
  numRabbits: 0
  checkRabbits: ->
    allRabbits = @agentsOfSpecies(@rabbitSpecies)
    allPlants  = @agentsOfSpecies(@plantSpecies)

    @numRabbits = allRabbits.length

    if @numRabbits is 0
      if @addedRabbits and not @addedHawks
        @env.stop()
        @showMessage "Uh oh, all the rabbits have died!<br/>Did you add any plants? Reset the model and try it again."
        return
    numPlants = allPlants.length

    if not @addedRabbits and @numRabbits > 0
      @addedRabbits = true

    if @addedRabbits and numPlants > 0 and @numRabbits < 9
      colorTrait = new Trait {name: "color", default: @getRandomClone(allRabbits), isGenetic: true}
      @addAgent(@rabbitSpecies, [["resource consumption rate", 10]], [colorTrait])
      @addAgent(@rabbitSpecies, [["resource consumption rate", 10]], [colorTrait])
      @addAgent(@rabbitSpecies, [["resource consumption rate", 10]], [colorTrait])
      @addAgent(@rabbitSpecies, [["resource consumption rate", 10]], [colorTrait])

    if @numRabbits < 16
      @setProperty(allRabbits, "min offspring", 2)
      @setProperty(allRabbits, "speed", 70)
    else
      # @setProperty(allRabbits, "metabolism", 1)
      @setProperty(allRabbits, "mating desire bonus", -20)
      @setProperty(allRabbits, "hunger bonus", -10)
      @setProperty(allRabbits, "min offspring", 1)
      @setProperty(allRabbits, "speed", 50)

    if @numRabbits > 50
      @setProperty(allRabbits, "mating desire bonus", -40)

  # Returns a random allele string from rabbits currently on screen
  getRandomClone: (allRabbits) ->
    randomRabbit = allRabbits[Math.floor(Math.random() * allRabbits.length)]
    console.log(randomRabbit.organism.alleles)
    return randomRabbit.organism.alleles

  checkHawks: ->
    allHawks = @agentsOfSpecies(@hawkSpecies)
    numHawks = allHawks.length

    if numHawks is 0
      if @addedHawks
        if @addedRabbits
          @env.stop()
          @showMessage "Uh oh, all the animals have died!<br/>Was there any food for the rabbits to eat? Reset the model and try it again."
        else
          @env.stop()
          @showMessage "Uh oh, all the hawks have died!<br/>Were there any rabbits for them to eat? Reset the model and try it again."
      return

    if not @addedHawks and numHawks > 0
      @addedHawks = true

    if @addedHawks and @numRabbits > 0 and numHawks < 2
      @addAgent @hawkSpecies

    if numHawks < 3 and @numRabbits > 0
      @setProperty(allHawks, "is immortal", true)
      @setProperty(allHawks, "mating desire bonus", -10)
      @setProperty(allHawks, "hunger bonus", 5)
    else
      if allHawks[0].get("is immortal")
        @setProperty(allHawks, "is immortal", false)

      if numHawks > 4
        @setProperty(allHawks, "mating desire bonus", -30)
        @setProperty(allHawks, "hunger bonus", -40)
      else
        @setProperty(allHawks, "mating desire bonus", -15)
        @setProperty(allHawks, "hunger bonus", -5)

  checkPlants: ->
    allPlants  = @agentsOfSpecies(@plantSpecies)
    if allPlants.length < 100
      @setProperty(allPlants, 'growth rate', 0.007)
    else if allPlants.length < 300
      @setProperty(allPlants, 'growth rate', 0.0035)
    else
      @setProperty(allPlants, 'growth rate', 0.0005)

  preload: [
    "images/agents/grass/tallgrass.png",
    "images/agents/rabbits/rabbit2.png",
    "images/agents/hawks/hawk.png",
    "images/environments/snow.png",
    "images/environments/snow-1.png",
    "images/environments/snow-2.png",
    "images/environments/snow-3.png",
    "images/environments/snow-4.png",
    "images/environments/snow-5.png",
    "images/environments/snow-6.png",
    "images/environments/snow-7.png",
    "images/environments/snow-8.png",
    "images/environments/snow-9.png"
  ]

window.onload = ->
  helpers.preload [model, env, plantSpecies, rabbitSpecies, hawkSpecies], ->
    model.run()
    model.setupControls()
    model.setupGraph()
    model.setupPopulationControls()
