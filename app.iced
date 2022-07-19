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

  # lookup <name>
  if msg.content.startsWith('lookup' + ' ')
    player_name = msg.content.substr(conf.COMMAND.length).trim()

    # ironforge.pro lookup
    await cinfo.ifpro player_name, defer e,result
    if e
      return msg.channel.send("`" + e.toString() + "`")

    # chad/virgin images
    image = (do =>
      if result.highest_rating >= 2000
        return __dirname + '/images/chad-' + _.rand(1,2) + '.png'
      if result.highest_rating <= 1700
        return __dirname + '/images/virgin-' + _.rand(2,2) + '.png'
      return null
    )

    # format ifpro data
    t = new Table()
    t.setBorder('-')
    t.setHeading 'season', '2s', '3s', '5s'

    for season, ratings of result.seasonal
      t.addRow season, ratings['2v2'], ratings['3v3'], ratings['5v5']

    output_history = "\n```#{t.toString()}```"

    links = """
      [tbcarmory.com](https://www.tbcarmory.com/character/us/#{conf.SERVER.toLowerCase()}/#{result.name})
      [ironforge.pro](https://ironforge.pro/armory/player/#{conf.SERVER}/#{result.name}/)
    """.split '\n'

    output_links = """#{links.join('\n')}"""

    image_file = null

    if image
      image_file = new swift.MessageAttachment(image)

    msg_obj = {
      embed: {
        color: 12733254
        timestamp: new Date().toISOString()
        image: (do =>
          if image then return {
            url: "attachment://#{_.base(image)}"
          }
          return undefined
        )
        fields: [{
          name: "#{result.name} - #{conf.SERVER}"
          value: """```#{result.highest_rating} CR (#{result.highest_bracket} #{result.highest_season.toUpperCase()})```"""
        },{
          name: "History"
          value: output_history
        },{
          name: "Links"
          value: output_links
        }]
      }
      files: (do =>
        if image then return [image_file]
        return []
      )
    }

    return msg.channel.send(msg_obj)

  # imgtest
  if msg.content.startsWith('imgtest')
    return msg.channel.send({
      content: 'test response'
      files: [__dirname + '/images/test.png']
    })

##
client.login(token)
