conf = require __dirname + '/../config'

_ = require('wegweg')({
  globals: on
  shelljs: on
})

swift = require('swiftly.js')
client = new swift.Client()

Table = require 'ascii-table'

cinfo = require __dirname + '/../lib/character-info'
top = require __dirname + '/../lib/top-players'

##
client.on 'ready', =>
  top.cycle()

  client.user.setActivity (conf.PREFIX + 'help'), {
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
        - you can use shorthand to refer to the server
          - i.e. "bene", "faer", or "grob"
        examples:
          .lookup lodash faer
          .lookup soupoftheday grob
      .cutoffs
        - displays current arena cutoffs for title rewards
      .top <query>
        - looks up the top rated players given an open-ended query
        examples:
          .top 10 locks and rogues on bene
          .top 3 horde mages
          .top rank1 or glad locks on ally bene
      
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
      if result.highest_wotlk >= 2400
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

  # `top <query>`
  if msg.content.startsWith(start = conf.PREFIX + 'top' + ' ')
    query = msg.content.substr(start.length).trim()

    # ironforge.pro lookup
    try
      query_opt = top.parse_query(query)
    catch e
      return msg.channel.send("`" + e.toString() + "`")

    await top.query query_opt, defer e,result
    if e
      return msg.channel.send("`" + e.toString() + "`")

    log result

    t = new Table()
    #t.setBorder('-')
    t.setHeading 'name', 'cr', 'class', 'server', 'faction'

    for x in result.items
      t.addRow x.name, x.rating, x.class, x.server, x.faction

    output = "\n```\n#{t.toString()}```"

    log output

    msg_obj = {
      embed: {
        color: 5138715
        title: result.query.options.input
        fields: [{
          name: "bracket"
          value: result.query.options.bracket
        }]
      }
      ###
      files: (do =>
        if image then return [image_file]
        return []
      )
      ###
    }

    log output

    return msg.channel.send(output)

##
module.exports = {
  enabled: true
  client: client
  token: conf.TOKENS.main
}

