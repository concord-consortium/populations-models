require.register "species/white-brown-rabbits", (exports, require, module) ->

  Species = require 'models/species'
  BasicAnimal = require 'models/agents/basic-animal'
  Trait   = require 'models/trait'

  biologicaSpecies = require 'species/biologica/rabbits'

  class Rabbit extends BasicAnimal
    label: 'Rabbit'
    moving: false
    moveCount: 0

    makeNewborn: ->
      super()

      #so ugly
      sex = if model.env.agents.length and
        model.env.agents[model.env.agents.length-1].species.speciesName is "rabbits" and
        model.env.agents[model.env.agents.length-1].get("sex") is "female" then "male" else "female"

      @set 'sex', sex

    mate: ->
      nearest = @_nearestMate()
      if nearest?
        @chase(nearest)
        if nearest.distanceSq < Math.pow(@get('mating distance'), 2) and (not @species.defs.CHANCE_OF_MATING? or Math.random() < @species.defs.CHANCE_OF_MATING)
          max = @get('max offspring')
          @set 'max offspring', Math.max(max/2, 1)
          @reproduce(nearest.agent)
          @set 'max offspring', max
          @_timeLastMated = @environment.date
          nearest.agent._timeLastMated = @environment.date          # ADDED THIS LINE
      else
        @wander(@get('speed') * Math.random() * 0.75)

    resetGeneticTraits: ()->
      super()
      @set 'genome', @_genomeButtonsString()

    _genomeButtonsString: ()->
      alleles = @organism.getAlleleString().replace(/a:/g,'').replace(/b:/g,'').replace(/,/g, '')
      return alleles

  module.exports = new Species
    speciesName: "rabbits"
    agentClass: Rabbit
    geneticSpecies: biologicaSpecies
    defs:
      MAX_HEALTH: 1
      MATURITY_AGE: 9
      CHANCE_OF_MUTATION: 0
      INFO_VIEW_SCALE: 2.5
      INFO_VIEW_PROPERTIES:
        "Color: ": 'color'
        "Genome: ": 'genome'
    traits: [
      new Trait {name: 'speed', default: 30 }
      new Trait {name: 'prey', default: [{name: 'fast plants'}] }
      new Trait {name: 'predator', default: [{name: 'hawks'},{name: 'foxes'}] }
      new Trait {name: 'color', possibleValues: [''], isGenetic: true, isNumeric: false }
      new Trait {name: 'vision distance', default: 200 }
      new Trait {name: 'eating distance', default:  50 }
      new Trait {name: 'mating distance', default:  50 }
      new Trait {name: 'max offspring',   default:  6 }
      new Trait {name: 'resource consumption rate', default:  35 }
      new Trait {name: 'metabolism', default:  0.5 }
    ]
    imageRules: [
      {
        name: 'rabbit'
        rules: [
          {
            image:
              path: "images/agents/rabbits/sandrat-light.png"
              scale: 0.3
              anchor:
                x: 0.8
                y: 0.47
            useIf: (agent)-> agent.get('color') is 'white'
          }
          {
            image:
              path: "images/agents/rabbits/sandrat-dark.png"
              scale: 0.3
              anchor:
                x: 0.8
                y: 0.47
            useIf: (agent)-> agent.get('color') is 'brown'
          }
        ]
      }
    ]
