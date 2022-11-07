conf = require __dirname + '/../config'

_ = require('wegweg')({
  globals: on
  shelljs: on
})

axios = require 'axios'

cinfo = module.exports = {
  working: {}
}

# ironforge.pro lookup
cinfo.ifpro = ((charname,server=null,cb) ->
  _RETURNED = false

  charname = charname.trim().toLowerCase()

  if @working[charname]
    return cb new Error 'already working on character: ' + charname

  if !cb and _.type(server) is 'function'
    server = conf.DEFAULT_SERVER

  if server !in conf.SERVER_CASCADE
    if found = conf.SERVER_SHORTHAND[server]
      server = found
  
  if server !in conf.SERVER_CASCADE
    return cb new Error 'invalid server provided, valid servers: ' + conf.SERVER_CASCADE.join(', ').toLowerCase()

  server = server.toLowerCase()

  request_url = "https://ironforge.pro/api/pvp/player/#{server}/#{charname}"

  axios.request({
    timeout: 20000
    url: request_url
    method: 'get'
  })
    .catch (e) ->
      if _RETURNED then return false
      _RETURNED = 1
      return cb e
    .then (r) ->
      try r = r.data
      if !r?.info?.name
        if _RETURNED then return false
        _RETURNED = 1
        return cb new Error 'character was not found, try again?'

      ratings = []
      tbc_ratings = []

      result = {
        name: r.info.name
        info: r.info
        server: server
        seasonal: (do =>
          tmp = {}
          for season in [1..10]
            if cur = r['season' + season]
              if cur['2']?.top ? 0 > highest then highest = cur['2']?.top ? 0
              if cur['3']?.top ? 0 > highest then highest = cur['3']?.top ? 0
              if cur['5']?.top ? 0 > highest then highest = cur['5']?.top ? 0

              tmp['s' + season] = ssn_rtngs = {
                "2v2": cur['2']?.top ? 0
                "3v3": cur['3']?.top ? 0
                "5v5": cur['5']?.top ? 0
              }

              if season > 4
                ratings = ratings.concat _.vals(ssn_rtngs)
              else
                tbc_ratings = tbc_ratings.concat _.vals(ssn_rtngs)

          return tmp
        )
      }

      if _RETURNED then return false

      log /result/, result

      try delete result.info.name
      try delete result.info.region
      try delete result.info.server

      for k,v of result.info
        if !v then delete result.info[k]
        try result.info[k] = v.toLowerCase()

      if !result.class then delete result.class

      result.highest_wotlk = _.max ratings ? 0
      if !result.highest_wotlk then result.highest_wotlk = 0

      result.highest_tbc = _.max tbc_ratings ? 0
      if !result.highest_tbc then result.highest_tbc = 0

      result.highest_rating = _h = 0
      result.highest_bracket = null
      result.highest_season = null

      for season,obj of result.seasonal
        continue if season < 5
        for k,v of obj
          if v > _h
            _h = v
            result.highest_rating = v
            result.highest_bracket = k
            result.highest_season = season
      
      return cb null, result
)

# wrapper to lookup on multiple servers
cinfo.lookup = ((opt,cb) ->
  required = [
    'name'
  ]

  if !opt.name then return cb new error 'no character name provided'
  if opt.server then opt.server = [opt.server]
  if !opt.server then opt.server = conf.SERVER_CASCADE

  for server in opt.server
    await cinfo.ifpro opt.name, server, defer e,result
    if e then continue
    if result then break

  if !result
    return cb new Error 'character not found (tried servers: ' + opt.server.join(',').toLowerCase() + ')'

  return cb null, result
)

if !module.parent
  await cinfo.lookup {name:'lodash'}, defer e,r
  log /e/, e
  log /r/, r
  exit 0
