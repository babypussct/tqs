
local xiongnve = fk.CreateSkill {
  name = "xiongnve",
}

Fk:loadTranslationTable {
  ["xiongnve"] = "凶虐",
  [":xiongnve"] = "准备阶段，你可以将你的副将变更为一张“戮”，然后你摸两张牌且本回合对此“戮”相同势力的角色造成的伤害+1。",

  ["#xiongnve-invoke"] = "凶虐：将副将变更为一张“戮”，摸两张牌，本回合对此势力角色造成伤害+1",
  ["@xiongnve-turn"] = "凶虐",

  ["$xiongnve1"] = "当今天子乃我所立，他敢怎样？",
  ["$xiongnve2"] = "我兄弟三人同掌禁军，有何所惧？",
}

local U = require "packages.utility.utility"
local H = require "packages.hegemony.util"

xiongnve:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xiongnve.name) and player.phase == Player.Start and
      #player:getTableMark("@&massacre") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local generals, choice = U.askToChooseGeneralsAndChoice(player, {
      skill_name = xiongnve.name,
      generals = player:getMark("@&massacre"),
      prompt = "#xiongnve-invoke",
      cancelable = true,
      max_num = 1,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, { generals = generals })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local general = event:getCostData(self).generals[1]
    room:returnToGeneralPile({ general })
    room:removeTableMark(player, "@&massacre", general)
    local mark = player:getTableMark("@xiongnve-turn")
    table.insertIfNeed(mark, Fk.generals[general].kingdom)
    if Fk.generals[general].subkingdom then
      table.insertIfNeed(mark, Fk.generals[general].subkingdom)
    end
    room:setPlayerMark(player, "@xiongnve-turn", mark)
    room:changeHero(player, general, false, true, false, false, false)
    room:setPlayerMark(player, "__heg_deputy", general)
    if not player.dead then
      player:drawCards(2, xiongnve.name)
    end
  end,
})

xiongnve:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and
      table.contains(player:getTableMark("@xiongnve-turn"), H.getKingdom(data.to))
  end,
  on_use = function(self, event, target, player, data)
      data:changeDamage(1)
  end,
})

return xiongnve
