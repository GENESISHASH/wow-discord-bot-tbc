conf = require __dirname + '/../config'

_ = require('wegweg')({
  globals: on
  shelljs: on
})

swift = require('swiftly.js')
client = new swift.Client()

Table = require 'ascii-table'

cutoffs = require __dirname + '/../lib/gladiator-cutoffs'

client_2v2 = new swift.Client() # 2v2
client_3v3 = new swift.Client() # 3v3
client_5v5 = new swift.Client() # 5v5

client_2v2.on 'ready', ->
  cutoffs.cycle()
  @user.setActivity "loading..", {type:'PLAYING'}

  cutoffs.events.on 'bracket-update', (d) =>
    if d.bracket_full is '2v2'
      @user.setActivity """
        glad=#{cutoffs.gladiator['2v2']}
        r1=#{cutoffs.rank1['2v2']}
      """, {type:'PLAYING'}

client_3v3.on 'ready', ->
  cutoffs.cycle()
  @user.setActivity "loading..", {type:'PLAYING'}

  cutoffs.events.on 'bracket-update', (d) =>
    if d.bracket_full is '3v3'
      @user.setActivity """
        glad=#{cutoffs.gladiator['3v3']}
        r1=#{cutoffs.rank1['3v3']}
      """, {type:'PLAYING'}

client_5v5.on 'ready', ->
  cutoffs.cycle()
  @user.setActivity "loading..", {type:'PLAYING'}

  cutoffs.events.on 'bracket-update', (d) =>
    if d.bracket_full is '5v5'
      @user.setActivity """
        glad=#{cutoffs.gladiator['5v5']}
        r1=#{cutoffs.rank1['5v5']}
      """, {type:'PLAYING'}

client_3v3.on 'message', (msg) =>

  # `cutoffs`
  if msg.content.startsWith(start = conf.PREFIX + 'cutoffs')

    # format ifpro data
    t = new Table()
    t.setBorder('-')

    t.setHeading 'bracket', 'duel', 'glad', 'r1'

    q = ['2v2','3v3','5v5']

    q.shift() if conf.DISABLE_2V2

    for x in q
      t.addRow x, cutoffs.duelist[x], cutoffs.gladiator[x], cutoffs.rank1[x]

    output_cutoffs = "\n```#{t.toString()}```"

    links = """
      [if.pro (2v2)](https://ironforge.pro/pvp/leaderboards/US/2/)
      [if.pro (3v3)](https://ironforge.pro/pvp/leaderboards/US/3/)
      [if.pro (5v5)](https://ironforge.pro/pvp/leaderboards/US/5/)
    """.split '\n'

    links.shift() if conf.DISABLE_2V2

    output_links = """#{links.join('\n')}"""

    msg_obj = {
      embed: {
        color: 5138715
        title: "title cutoffs"
        fields: [{
          name: "brackets"
          value: output_cutoffs
        },{
          name: "links"
          value: output_links
        }]
      }
    }

    return msg.channel.send(msg_obj)

##
module.exports = [{
  enabled: !conf.DISABLE_2V2
  client: client_2v2
  token: conf.TOKENS.cutoffs["2v2"]
},{
  enabled: true
  client: client_3v3
  token: conf.TOKENS.cutoffs["3v3"]
},{
  enabled: true
  client: client_5v5
  token: conf.TOKENS.cutoffs["5v5"]
}]

