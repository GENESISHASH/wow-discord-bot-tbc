conf = require __dirname + '/config'

_ = require('wegweg')({
  globals: on
  shelljs: on
})

# find all bots
files = ls __dirname + '/bots/*.iced'

bots = (_.map files, (x) ->
  arr = []

  obj = require(x)

  if _.type(obj) isnt 'array'
    obj = [obj]

  arr = _.map obj, (y) ->
    if !y.token or !y.client
      throw new Error 'exports.token and exports.client required'
      exit 1
    y.name = _.base(x)
    y

  return arr
)

for arr in bots
  _enable = ((bot) =>
    if !bot.enabled
      log 'Skipping bot (disabled)', bot.name
      return

    log 'Connecting bot', bot.name
    bot.client.login(bot.token)
  )

  for item in arr
    do (item) -> _enable(item)

