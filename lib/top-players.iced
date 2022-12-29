conf = require __dirname + '/../config'

_ = require('wegweg')({
  globals: on
  shelljs: on
})

axios = require 'axios'

EventEmitter = (require 'events').EventEmitter
util = require 'util'

CYCLE_INTERVAL_SECS = _.secs('5 minutes')

similar = require 'string-similarity'

top = module.exports = {
  events: new EventEmitter()
  "2v2": []
  "3v3": []
  "5v5": []
}

top.refresh = (cb=null) ->
  if !cb then cb = -> 1

  await
    top.refresh_bracket 2, defer e
    top.refresh_bracket 3, defer e
    top.refresh_bracket 5, defer e

  if e then return cb e

  return cb null, true

top.refresh_bracket = ((bracket="2",cb) ->
  try bracket = bracket.toString()
  bracket = bracket.substr(0,1)
  bracket_full = "#{bracket}v#{bracket}"

  request_url = "https://ironforge.pro/api/pvp/leaderboards/#{conf.CURRENT_SEASON}/US/#{bracket}/"

  axios.request({
    timeout: 30000
    url: request_url
    method: 'get'
  })
    .catch (e) ->
      return cb e
    .then (r) =>
      data = r.data.data

      top[bracket_full] = data

      @events.emit 'top-bracket-update', {
        bracket: bracket
        bracket_full: bracket_full
      }

      return cb null, data
)

top.parse_query = ((str) ->
  limit = false

  if str.startsWith('.top')
    str = str.substr(4)

  str = str.trim().toLowerCase()

  garbage = ['of','the','in','on','at','to','a','is','and']

  for k,v of conf.OPT_TYPES
    for x in v
      if x.includes(' ') and str.includes(x)
        while str.includes(x)
          str = str.split(x).join(x.split(' ').join(''))

  parts = str.trim().toLowerCase().split(' ')
  parts = _.cmap parts, (x) -> if x !in garbage then return x

  if parts[0] and +parts[0] in [3..100]
    limit = +parts[0]
    parts.shift()

  scores = {}

  for part in parts
    scores[part] = tmp = []

    for type,examples of conf.OPT_TYPES
      sim = similar.findBestMatch(part,examples).bestMatch
      tmp.push {type:type,bestMatch:sim.rating}

  relevant = {}

  for part,arr of scores
    max = _.first(_.sortBy(arr,(x) -> -x.bestMatch))
    if max.bestMatch >= 0.7
      relevant[max.type] ?= []
      relevant[max.type].push {value:part,score:max.bestMatch}

  for k,v of relevant
    v = _.sortBy v, (x) -> -x.score
    relevant[k] = v

  result = {}

  for k,v of relevant
    result[k] = _.uniq _.map v, (x) -> x.value

  result.limit = limit if limit
  result.input = str

  return result
)

# wrapper to lookup on multiple servers
top.query = ((opt,cb) ->
  opt.class ?= null
  opt.bracket ?= "3v3"
  opt.server ?= null
  opt.title ?= null
  opt.limit ?= 25
  opt.limit = +opt.limit
  if opt.limit == 0 then opt.limit = 50
  if opt.limit > 100 then opt.limit = 100

  _filters = {}

  if opt.servers and !opt.server
    opt.server = opt.servers

  if opt.server
    if _.type(opt.server) isnt 'array'
      opt.server = [opt.server]

    opt.server = _.ucmap opt.server, (server) ->
      if server in conf.SERVER_CASCADE
        return server
      if found = conf.SERVER_SHORTHAND[server]
        return found
      return null

  if opt.server
    _filters.servers = _.uniq opt.server
  else
    opt.server = null

  if opt.bracket and _.type(opt.bracket) is 'array'
    opt.bracket = _.first opt.bracket

  bracket = opt.bracket.substr(0,1)
  bracket = +bracket

  bracket_full = "#{bracket}v#{bracket}"

  if bracket !in [2,3,5]
    return cb new Error 'invalid bracket provided, valid brackets: ' + ['2s','3s','5s'].join(', ')

  if opt.classes and !opt.class
    opt.class = opt.classes

  if opt.class
    if _.type(opt.class) isnt 'array'
      opt.class = [opt.class]
      
    opt.class = _.ucmap opt.class, (x) ->
      x = _.ucfirst(x.toLowerCase())

      # check slang
      if x !in (_class_list = _.keys(conf.CLASSES_SHORTHAND))
        for class_name, slang_arr of conf.CLASSES_SHORTHANDS
          if slang in slang_arr
            if x is slang or x is slang + 's'
              return class_name
            
        x = similar.findBestMatch(x,_class_list).bestMatch.target
      return x

    for x in opt.class
      _filters.classes ?= []
      _filters.classes.push x

  title_map = {
    'Rank 1': 0
    'Gladiator': 1
    'Duelist': 2
    'Rival': 3
    'Challenger': 4
  }

  if opt.title
    if _.type(opt.title) isnt 'array'
      opt.title = [opt.title]

    opt.title = _.ucmap opt.title, (x) ->
      x = _.ucfirst(x.toLowerCase())
      if x !in _.keys(title_map)
        x = similar.findBestMatch(x,_.keys(title_map)).bestMatch.target
      return x

    for x in opt.title
      _filters.titles ?= []
      _filters.titles.push x

  factions = [
    'Alliance'
    'Horde'
  ]

  if opt.faction
    if _.type(opt.faction) isnt 'array'
      opt.faction = [opt.faction]

    opt.faction = _.ucmap opt.faction, (x) ->
      x = _.ucfirst(x.toLowerCase())
      if x !in factions
        x = similar.findBestMatch(x,factions).bestMatch.target
      return x

    for x in opt.faction
      _filters.factions ?= []
      _filters.factions.push x

  # filter bracket data for query
  items = _.clone(top[bracket_full])

  items = _.map items, (x) ->
    if x.title?
      x.title_int = x.title
      for k,v of title_map
        if v is +x.title
          x.title_full = k
          break
    if !x.title_full
      try delete x.title
    return x

  items = _.cmap items, (x) ->
    if v_arr = _filters.servers
      if x.server !in v_arr then return null

    if v_arr = _filters.classes
      if x.class !in v_arr then return null

    if v_arr = _filters.factions
      if x.faction !in v_arr then return null

    if v_arr = _filters.titles
      if !x.title_full then return null
      if x.title_full !in v_arr then return null

    return x

  # sort by rating
  items = _.sortBy items, (x) -> -x.rating

  last_rating = _.first(items).rating
  last_rank = 1

  # add relative ranks and title strings
  items = _.map items, (x) ->
    x.ranking_bracket = x.ranking

    if x.rating < last_rating
      x.ranking_filtered = last_rank + 1
      last_rating = x.rating
      last_rank = x.ranking_filtered
      return x

    if x.rating is last_rating
      x.ranking_filtered = last_rank

    return x

  # trim to limit
  if items.length > opt.limit
    items = items.slice(0,opt.limit)

  result = {
    items: items
    query: {
      options: opt
      filters: _filters ? {}
      count: items?.length ? 0
    }
  }

  return cb null, result
)

top.cycle = (->
  return false if @_cycling
  @_cycling = 1

  top.refresh ->
    setInterval top.refresh, (CYCLE_INTERVAL_SECS * 1000)
)

if !module.parent
  await top.refresh defer e
  if e then throw e

  log /refresh finished/

  #log top.parse_query('.top 10 lock rog and dks 2v2z and 3v3 and 5v5z bene and fuck my life lmfaooo')
  #log top.parse_query('.top 5 locks and mages on bene and grob in 5s')
  #log top.parse_query('.top list of the best dks on faer')

  options = top.parse_query('.top 25 best dks bene')
  log /options/, options

  await top.query options, defer e,r
  if e then throw e

  log /r/, r
  log JSON.stringify r, null, 2
  exit 0

