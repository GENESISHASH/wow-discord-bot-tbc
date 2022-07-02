conf = require __dirname + '/config'

_ = require('wegweg')({
  globals: on
  shelljs: on
})

swift = require('swiftly.js')
client = new swift.Client()
token = conf.TOKEN

Table = require 'ascii-table'

##
client.on 'ready', =>
  log /connected/, conf.TOKEN
  msg.channel.send "`discord_bot_connected`"

##
client.on 'message', (msg) =>
  if msg.content.startsWith(conf.COMMAND + ' ')
    player_name = msg.content.substr(conf.COMMAND.length).trim()
    await _.get "https://ironforge.pro/api/players?player=#{player_name}-#{conf.SERVER}", defer e,raw,r
    return if e

    if e
      return msg.channel.send "```generic_error```"

    if !r?.info?.name
      return msg.channel.send "```character_noexists```"

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
    
    ###
    bulk = JSON.stringify(result,null,2)
    output = "```#{bulk}```"
    ###

    # seasons
    t = new Table "#{result.name} (#{result.highest})"
    t.setBorder('-')
    t.setHeading 'season', '2s', '3s', '5s'

    for season, ratings of result.seasonal
      t.addRow season, ratings['2v2'], ratings['3v3'], ratings['5v5']

    output = "\n```#{t.toString()}```"
    output += """```
      https://www.tbcarmory.com/character/us/#{conf.SERVER.toLowerCase()}/#{result.name}
      https://ironforge.pro/armory/player/#{conf.SERVER}/#{result.name}/```
    """

    return msg.channel.send(output.trim())

##
client.login(token)
