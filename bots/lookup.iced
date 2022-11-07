conf = require __dirname + '/../config'

_ = require('wegweg')({
  globals: on
  shelljs: on
})

swift = require('swiftly.js')
client = new swift.Client()

Table = require 'ascii-table'
cinfo = require __dirname + '/../lib/character-info'

##
client.on 'ready', =>
  client.user.setActivity (conf.PREFIX + 'lookup <charname> <server>'), {
    type: 'PLAYING'
  }

##
client.on 'message', (msg) =>

  # `help`
  if msg.content.startsWith(conf.PREFIX + 'help')
    return msg.channel.send """```
    commands:
      .help
        - displays help menu
      .lookup <charname> [server]
          - looks up a character's arena ratings on if.pro
            - if no server is selected it will attempt to cascade from faerlina -> benediction -> grobbulus
            - you can use shorthand to refer to the server, i.e. "bene", "faer", or "grob"
          examples:
            .lookup lodash faer
            .lookup soupoftheday grob
      .cutoffs
        - displays current arena cutoffs for title rewards
    ```"""

  # `lookup <name>`
  if msg.content.startsWith(start = conf.PREFIX + 'lookup' + ' ')
    name = msg.content.substr(start.length).trim()

    if name.includes(' ')
      [name,server] = name.split(' ')

    opt = {name}
    if server then opt.server = server

    # ironforge.pro lookup
    await cinfo.lookup opt, defer e,result
    if e
      return msg.channel.send("`" + e.toString() + "`")

    log result

    # chad/virgin images
    image = (do =>
      if result.highest_wotlk >= 2000
        return __dirname + '/../images/chad-' + _.rand(1,2) + '.png'
      if result.highest_wotlk <= 1700
        return __dirname + '/../images/virgin-' + _.rand(2,2) + '.png'
      return null
    )

    image = null

    # format ifpro data
    t = new Table()
    t.setBorder('-')
    t.setHeading 'season', '2s', '3s', '5s'

    for season, ratings of result.seasonal
      t.addRow season, ratings['2v2'], ratings['3v3'], ratings['5v5']

    output_history = "\n```#{t.toString()}```"

    links = """
      [if.pro](https://ironforge.pro/pvp/player/#{result.server}/#{result.name}/)
    """.split '\n'

    output_links = """#{links.join('\n')}"""

    image_file = null

    if image
      image_file = new swift.MessageAttachment(image)

    msg_obj = {
      embed: {
        color: 12733254
        image: (do =>
          if image then return {
            url: "attachment://#{_.base(image)}"
          }
          return undefined
        )
        title: "#{result.name} @ #{result.server} (#{result.highest_wotlk ? 0})"
        fields: [{
          name: "details"
          value: (do =>
            return _.vals(result.info).join('/')
          )
        },{
          name: "wotlk cr"
          value: result.highest_wotlk ? 0
        },{
          name: "tbc cr"
          value: result.highest_tbc ? 0
        },{
          name: "history"
          value: output_history
        },{
          name: "links"
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
      files: [__dirname + '/../images/test.png']
    })

##
module.exports = {
  enabled: true
  client: client
  token: conf.TOKENS.main
}

