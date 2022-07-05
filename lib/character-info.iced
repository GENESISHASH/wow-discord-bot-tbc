conf = require __dirname + '/../config'

_ = require('wegweg')({
  globals: on
  shelljs: on
})

axios = require 'axios'

cinfo = module.exports = {}

# ironforge.pro lookup
cinfo.ifpro = ((charname,cb) ->
  charname = charname.trim().toLowerCase()

  request_url = "https://ironforge.pro/api/players?player=#{charname}-#{conf.SERVER}"

  axios.request({
    timeout: 15000
    url: request_url
    method: 'get'
  })
    .catch (e) -> return cb e
    .then (r) ->
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

              ratings = ratings.concat _.vals(ssn_rtngs)

          return tmp
        )
      }

      if !result.class then delete result.class

      result.highest = _.max ratings ? 0

      return cb null, result
)

if !module.parent
  await cinfo.ifpro 'botnet', defer e,r
  log /e/, e
  log /r/, r
  exit 0
