local yanxi = fk.CreateSkill{
  name = "heg__yanxi",
}

Fk:loadTranslationTable{
  ["heg__yanxi"] = "宴戏",
  [":heg__yanxi"] = "准备阶段，你可以选择至多三名其他势力的角色各一张手牌，这些角色依次声明一个牌名，然后你展示并获得其中一张牌，"..
  "若获得的牌与其声明的牌名不同，你再获得其余被选择的牌。",

  ["#heg__yanxi-choose"] = "宴戏：选择至多三名角色各一张手牌",
  ["#heg__yanxi-choice"] = "宴戏：%src 选择了你的%arg，请声明一个牌名",
  ["#heg__yanxi-prey"] = "宴戏：获得其中一张你选择的牌，若与其声明的牌名不同，你获得所有选择的牌",

  ["$heg__yanxi1"] = "宴会嬉趣，其乐融融。",
  ["$heg__yanxi2"] = "宴中趣玩，得遇知己。",
}

local U = require "packages.utility.utility"
local H = require "packages.hegemony.util"

yanxi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yanxi.name) and player.phase == Player.Start and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not p:isKongcheng() and H.compareKingdomWith(p, player, true)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not p:isKongcheng() and H.compareKingdomWith(p, player, true)
    end)
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 3,
      targets = targets,
      skill_name = yanxi.name,
      prompt = "#heg__yanxi-choose",
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getCostData(self).tos
    local ids, choices = {}, {}
    for _, to in ipairs(targets) do
      local card = room:askToChooseCard(player, {
        target = to,
        flag = "h",
        skill_name = yanxi.name,
      })
      table.insert(ids, card)
    end
    for _, to in ipairs(targets) do
      local name = U.askForChooseCardNames(room, to, Fk:getAllCardNames("btde", true), 1, 1, yanxi.name,
        "#heg__yanxi-choice:"..player.id.."::"..Fk:getCardById(ids[table.indexOf(targets, to)]):toLogString())
      room:sendLog{
        type = "#Choice",
        from = to.id,
        arg = name[1],
        toast = true,
      }
      table.insert(choices, name[1])
    end
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = yanxi.name,
      prompt = "#heg__yanxi-prey",
      cancelable = false,
    })[1]
    local id = ids[table.indexOf(targets, to)]
    room:showCards({id}, to)
    room:moveCardTo(id, Card.PlayerHand, player, fk.ReasonPrey, yanxi.name, nil, true, player)
    if #targets == 1 or Fk:getCardById(id).trueName == choices[table.indexOf(targets, to)] or player.dead then return end
    table.removeOne(ids, id)
    table.removeOne(targets, to)
    local moves = {}
    for i = 1, #ids do
      if table.contains(targets[i]:getCardIds("h"), ids[i]) then
        table.insert(moves, {
          ids = {ids[i]},
          from = targets[i],
          to = player,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonPrey,
          skillName = yanxi.name,
          proposer = player,
          moveVisible = true,
        })
      end
    end
    if #moves > 0 then
      room:moveCards(table.unpack(moves))
    end
  end,
})

return yanxi
