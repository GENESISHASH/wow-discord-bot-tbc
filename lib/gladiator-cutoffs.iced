conf = require __dirname + '/../config'

_ = require('wegweg')({
  globals: on
  shelljs: on
})

axios = require 'axios'

EventEmitter = (require 'events').EventEmitter
util = require 'util'

CYCLE_INTERVAL_SECS = _.secs('15 seconds')

module.exports = cutoffs = {
  events: new EventEmitter()
  rank1:
    "2v2": 0
    "3v3": 0
    "5v5": 0
  gladiator:
    "2v2": 0
    "3v3": 0
    "5v5": 0
  duelist:
    "2v2": 0
    "3v3": 0
    "5v5": 0
}

cutoffs.refresh_bracket = ((bracket="2",cb) ->
  try bracket = bracket.toString()
  bracket = bracket.substr(0,1)
  bracket_full = "#{bracket}v#{bracket}"

  request_url = "https://ironforge.pro/api/pvp/cutoff/US/" + bracket

  axios.request({
    timeout: 30000
    url: request_url
    method: 'get'
  })
    .catch (e) ->
      return cb e
    .then (r) =>
      data = r.data?.cutoff

      if data?.length > 1 and data[0]?[0] > 1
        cutoffs.rank1[bracket_full] = data[0][0]
        cutoffs.gladiator[bracket_full] = data[1][0]
        cutoffs.duelist[bracket_full] = data[2][0]

      @events.emit 'bracket-update', {
        bracket: bracket
        bracket_full: bracket_full
      }

      return cb null, data
)

cutoffs.refresh = (cb=null) ->
  if !cb then cb = -> 1

  if !conf.DISABLE_2V2
    await
      cutoffs.refresh_bracket 2, defer e
      cutoffs.refresh_bracket 3, defer e
      cutoffs.refresh_bracket 5, defer e
  else
    await
      cutoffs.refresh_bracket 3, defer e
      cutoffs.refresh_bracket 5, defer e

  if e then return cb e

  return cb null, true

cutoffs.cycle = (->
  return false if @_cycling
  @_cycling = 1

  cutoffs.refresh ->
    setInterval cutoffs.refresh, (CYCLE_INTERVAL_SECS * 1000)
)

if !module.parent
  await cutoffs.refresh defer e,r
  log /e/, e
  log /r/, r
  exit 0
