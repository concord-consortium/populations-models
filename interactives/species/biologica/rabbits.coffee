require.register "species/biologica/rabbits", (exports, require, module) ->

  module.exports =

    name: 'Rabbit'

    chromosomeNames: ['1', '2', 'XY']

    chromosomeGeneMap:
      '1': ['B']
      '2': []
      'XY': []

    chromosomesLength:
      '1': 100000000
      '2': 100000000
      'XY': 70000000

    geneList:
      'color':
        alleles: ['B', 'b']
        weights: [0.8, 0.2]
        start: 10000000
        length: 10584

    alleleLabelMap:
      'B': 'Brown'
      'b': 'White'
      ''  : ''

    traitRules:
      'color':
        'white': [['b','b']]
        'brown': [['B','b'],['B','B']]

    ###
      Images are handled via the populations.js species
    ###
    getImageName: (org) ->
      undefined

    ###
      no lethal characteristics
    ###
    makeAlive: (org) ->
      undefined
