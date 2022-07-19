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
cinfo.ifpro = ((charname,cb) ->
  charname = charname.trim().toLowerCase()

  if @working[charname]
    return cb new Error 'Already working on character: ' + charname

  @working[charname] = 1

  request_url = "https://ironforge.pro/api/players?player=#{charname}-#{conf.SERVER}"

  axios.request({
    timeout: 30000
    url: request_url
    method: 'get'
  })
    .catch (e) ->
      cinfo.working[charname] = undefined
      return cb e
    .then (r) ->
      cinfo.working[charname] = undefined

      try r = r.data
      if !r?.info?.name
          return cb new Error 'Character was not found'

      ratings = []

      result = {
        name: r.info.name
        race: r.info.race.toLowerCase()
        class: r.info.clas?.toLowerCase?() ? undefined
        highest: 0
        seasonal: (do =>
          tmp = {}
          for season in [0..500]
            if cur = r['season' + season]
              tmp['s' + season] = ssn_rtngs = {
                "2v2": cur['2']?.top ? 0
                "3v3": cur['3']?.top ? 0
                "5v5": cur['5']?.top ? 0
              }

              ratings = ratings.concat _.vals(ssn_rtngs)

          return tmp
        )
      }

      if !result.class then delete result.class

      result.highest_rating = result.highest = _h = 0
      result.highest_bracket = null
      result.highest_season = null

      for season,obj of result.seasonal
        for k,v of obj
          if v > _h
            _h = v
            result.highest_rating = v
            result.highest_bracket = k
            result.highest_season = season

      return cb null, result
)

if !module.parent
  await cinfo.ifpro 'botnet', defer e,r
  log /e/, e
  log /r/, r
  exit 0
