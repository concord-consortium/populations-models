helpers     = require 'helpers'

Environment = require 'models/environment'
Species     = require 'models/species'
Agent       = require 'models/agent'
Rule        = require 'models/rule'
Trait       = require 'models/trait'
Interactive = require 'ui/interactive'
Events      = require 'events'
ToolButton  = require 'ui/tool-button'

plantSpecies  = require 'species/fast-plants-roots'
env           = require 'environments/dam'

window.model =
  showMessage: (message, callback) ->
    helpers.showMessage message, @env.getView().view.parentElement, callback

  run: ->
    @interactive = new Interactive
      environment: env
      speedSlider: false
      addOrganismButtons: [
        {
          species: plantSpecies
          imagePath: "images/agents/grass/medgrass.png"
          traits: [
            new Trait {name: "population size modifier", default: 0.0, float: true}
            new Trait {name: "roots", possibleValues: [1,2,3] }
          ]
          limit: 140
          scatter: 140
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

    @_reset()
    Events.addEventListener Environment.EVENTS.RESET, =>
      @_reset()

  _reset: ->
    @env.setBackground("images/environments/dam-year0.png")
    @_setEnvironmentProperty('water', 10)
    @damCreated = false
    @_setEnvironmentProperty('water', 10, true)

  chartData1: null
  chartData2: null
  chart1: null
  chart2: null
  setupCharts: ->
    # setup chart data
    @chartData1 = new google.visualization.DataTable()
    @chartData2 = new google.visualization.DataTable()
    @_setupChartData(@chartData1)
    @_setupChartData(@chartData2)

    # Instantiate and draw our chart, passing in some options.
    options1 = @_getChartOptions("top")
    options2 = @_getChartOptions("bottom")
    @chart1 = new google.visualization.ColumnChart(document.getElementById('chart1'));
    @chart2 = new google.visualization.ColumnChart(document.getElementById('chart2'));
    @chart1.draw(@chartData1, options1)
    @chart2.draw(@chartData2, options2)

    updateCharts = () =>
      counts =
        top: [0,0,0,0]
        bottom: [0,0,0,0]

      for agent in @env.agents
        if agent.species is @plantSpecies
          if agent.getLocation().y < (@env.rows * @env._rowHeight)/2
            counts.top[agent.get('roots')] += 1
          else
            counts.bottom[agent.get('roots')] += 1

      for i in [0..2]
        @chartData1.setValue(i, 1, (counts.top[i+1])*2)
        @chartData2.setValue(i, 1, (counts.bottom[i+1])*2)

      # if counts[1] > 10 or counts[5] > 10 or counts[9] > 10
      #   options.vAxis.gridlines.count = -1

      @chart1.draw(@chartData1, options1)
      @chart2.draw(@chartData2, options2)

    Events.addEventListener Environment.EVENTS.STEP, updateCharts
    $(".button:nth-child(3)").on('click', updateCharts);

  _setupChartData: (chartData)->
    chartData.addColumn('string', 'Plant types')
    chartData.addColumn('number', 'Number of plants')
    chartData.addColumn({ type: 'string', role: 'style' })
    chartData.addRows [
      ["Small",  0, "color: #00FF00"]
      ["Medium", 0, "color: #00CC00"]
      ["Big",    0, "color: #008800"]
    ]

  _getChartOptions: (titleMod)->
    # Set chart options
    return options =
      title: 'Plants in '+titleMod+' half of the field'
      hAxis:
        title: 'Plant types'
      vAxis:
        title: 'Number of plants'
        minValue: 0
        maxValue: 50
        gridlines:
          count: 6
      legend:
        position: 'none'
      width: 300
      height: 250

  _agentsOfSpecies: (species)->
    set = []
    for a in @env.agents
      set.push a if a.species is species
    return set

  damCreated: false
  setupControls: ->
    createDamButton = document.getElementById('build-button')
    createDamButton.onclick = =>
      unless @damCreated
        @damCreated = true
        # fast-forward to the beginning of the first year
        @env.date = Math.floor(10000/Environment.DEFAULT_RUN_LOOP_DELAY)-1

    noneHighlightRadio = document.getElementById('highlight-none')
    smallHighlightRadio = document.getElementById('highlight-small')
    mediumHighlightRadio = document.getElementById('highlight-medium')
    bigHighlightRadio = document.getElementById('highlight-big')

    noneHighlightRadio.onclick = =>
      @_highlight -1
    smallHighlightRadio.onclick = =>
      @_highlight 1
    mediumHighlightRadio.onclick = =>
      @_highlight 2
    bigHighlightRadio.onclick = =>
      @_highlight 3

    Events.addEventListener Environment.EVENTS.RESET, =>
      noneHighlightRadio.click()

  _highlight: (size)->
    for agent in @env.agents
      if agent.species is @plantSpecies
        agent.set 'glow', (agent.get('roots') is size)

  setupTimer: ->
    backgroundChangeable = false
    changeInterval = 5
    waterLevel = 10
    yearSpan = document.getElementById('year')
    waterLevelIndicator = document.getElementById('water-level-indicator')
    Events.addEventListener Environment.EVENTS.STEP, =>
      unless @damCreated
        # time doesn't pass until the dam is built
        @env.date = 0
        return
      t = Math.floor(@env.date * Environment.DEFAULT_RUN_LOOP_DELAY / 1000) # this will calculate seconds at default speed

      year = t/changeInterval
      waterLevel = 11-Math.min(11, year)
      waterLevelPct = waterLevel*10
      @_setEnvironmentProperty('water', waterLevel)
      # Update vertical bar level indicator in page
      waterLevelIndicator.style.height = ""+waterLevelPct+"%"
      if t % changeInterval is 0 and backgroundChangeable
        @_changeBackground(year)
        yearSpan.innerHTML = ""+year
        backgroundChangeable = false
      else if t % changeInterval isnt 0
        backgroundChangeable = true

    Events.addEventListener Environment.EVENTS.RESET, =>
      backgroundChangeable = false
      yearSpan.innerHTML = "1"
      waterLevelIndicator.style.height = "100%"

  _changeBackground: (n)->
    return unless 0 < n < 11
    @env.setBackground("images/environments/dam-year"+n+".png")

  _setAgentProperty: (agents, prop, val)->
    for a in agents
      a.set prop, val

  _setAgentProperty: (agents, prop, val)->
    for a in agents
      a.set prop, val

  _setEnvironmentProperty: (prop, val, all=false)->
    for row in [0..(@env.rows)]
      if all or row > @env.rows/2
        for col in [0..(@env.columns)]
          @env.set col, row, prop, val

  _addAgent: (species, properties=[])->
    agent = species.createAgent()
    agent.setLocation @env.randomLocation()
    for prop in properties
      agent.set prop[0], prop[1]
    @env.addAgent agent

  setupPopulationMonitoring: ->
    Events.addEventListener Environment.EVENTS.STEP, =>
      # Check population levels and adjust accordingly
      @_setPlantGrowthRate()
      if Math.random() < 0.1
        @_makeLandFertile()


  _plantsExist: false
  _setPlantGrowthRate: ->
    allPlants = @_agentsOfSpecies @plantSpecies
    if allPlants.length < 1
      @_plantsExist = false
      return;
    else
      @_plantsExist = true

    varieties = [[], [], [], [], [], []]
    for plant in allPlants
      rootSize = plant.get("roots")
      adder = if plant.getLocation().y > 250 then 3 else 0
      varieties[((rootSize - 1) + adder)].push(plant)

    for variety in varieties
      @_setGrowthRateForVariety(variety)

  _setGrowthRateForVariety: (plants)->
    plantSize = plants.length
    populationSizeModifier = 0.0
    if plantSize < 10
      populationSizeModifier = 0.7
    else if plantSize < 15
      populationSizeModifier = 0.4
    else if plantSize < 40
      populationSizeModifier = 0.1
    else if plantSize < 60
      populationSizeModifier = 0.0
    else if plantSize < 160
      populationSizeModifier = -0.02
    else if plantSize < 190
      populationSizeModifier = -0.03
    else if plantSize < 230
      populationSizeModifier = -0.05
    else
      i = plantSize-1
      while i > 0
        plants[i].die()
        i -= 5

    for plant in plants
      plant.set "population size modifier", populationSizeModifier

  _makeLandFertile: ->
    # TODO Implment this!
    # env.replenishResources()
    return
    # FIXME What does this do?
    # allPlants = @_agentsOfSpecies @plantSpecies
    # for plant in allPlants
    #   loc = plant.getLocation()
    #   if loc.y > 228 && loc.y < 260
    #     plant.die()

  preload: [
    "images/agents/grass/medgrass.png",
    "images/environments/dam-year0.png",
    "images/environments/dam-year1.png",
    "images/environments/dam-year2.png",
    "images/environments/dam-year3.png",
    "images/environments/dam-year4.png",
    "images/environments/dam-year5.png",
    "images/environments/dam-year6.png",
    "images/environments/dam-year7.png",
    "images/environments/dam-year8.png",
    "images/environments/dam-year9.png",
    "images/environments/dam-year10.png"
  ]

window.onload = ->
  helpers.preload [model, env, plantSpecies], ->
    model.run()
    model.setupControls()
    model.setupCharts()
    model.setupTimer()
    model.setupPopulationMonitoring()

    if iframePhone
      phone = iframePhone.getIFrameEndpoint()
      phone.initialize()

      log = (action, data) ->
        data ?= {}
        data.model = "Dam Model Plants"
        console.log("%c Logging:", 'color: #f99a00', action, JSON.stringify(data));
        phone.post 'log', {action: action, data: data}

      Events.addEventListener Environment.EVENTS.START, ->
        log('Model Start')
      Events.addEventListener Environment.EVENTS.RESET, ->
        log('Model Reset')
      Events.addEventListener Environment.EVENTS.STOP, ->
        log('Model Stop')
      $("#build-button").on 'click', ->
        log('Build Dam')
      $(".button:nth-child(3)").on 'click', ->
        log('Add Plants')
      $(".button:nth-child(4)").on 'click', ->
        log('Use Magnifying Glass')


      $('#highlight-none').on 'click', ->
        log('Remove Highlight')
      $('#highlight-small').on 'click', ->
        log('Add Highlight', {organisms: "Small Plants"})
      $('#highlight-medium').on 'click', ->
        log('Add Highlight', {organisms: "Medium Plants"})
      $('#highlight-big').on 'click', ->
        log('Add Highlight', {organisms: "Big Plants"})
