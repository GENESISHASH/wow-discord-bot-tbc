conf = require __dirname + '/config'

_ = require('wegweg')({
  globals: on
  shelljs: on
})

swift = require('swiftly.js')
client = new swift.Client()
token = conf.TOKEN

Table = require 'ascii-table'
cinfo = require __dirname + '/lib/character-info'

##
client.on 'ready', =>
  log /connected/, conf.TOKEN

##
client.on 'message', (msg) =>
  if msg.content.startsWith(conf.COMMAND + ' ')
    player_name = msg.content.substr(conf.COMMAND.length).trim()

    # ironforge.pro lookup
    await cinfo.ifpro player_name, defer e,result
    if e
      return msg.channel.send(e.toString())

    # format ifpro data
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
