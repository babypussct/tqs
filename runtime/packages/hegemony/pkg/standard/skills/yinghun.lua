local yinghun = fk.CreateSkill{
  name = "hs__yinghun",
}
local U = require "packages.utility.utility"
yinghun:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yinghun.name) and player.phase == Player.Start and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = player.room:getOtherPlayers(player, false),
      skill_name = yinghun.name,
      prompt = "#hs__yinghun-choose:::"..U.ConvertNumber(player:getLostHp()),
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local n = player:getLostHp()
    local choice = room:askToChoice(player, {
      choices = {"#hs__yinghun-draw:::" .. U.ConvertNumber(n),  "#hs__yinghun-discard:::" .. U.ConvertNumber(n)},
      skill_name = yinghun.name
    })
    if choice:startsWith("#hs__yinghun-draw") then
      player:broadcastSkillInvoke(yinghun.name, 1)
      room:notifySkillInvoked(player, yinghun.name, "support")
      to:drawCards(n, yinghun.name)
      if to:isAlive() then
        room:askToDiscard(to, {
          skill_name = yinghun.name,
          cancelable = false,
          min_num = 1,
          max_num = 1,
          include_equip = true,
        })
      end
    else
      player:broadcastSkillInvoke(yinghun.name, 2)
      room:notifySkillInvoked(player, yinghun.name, "control")
      to:drawCards(1, yinghun.name)
      if to:isAlive() then
        room:askToDiscard(to, {
          skill_name = yinghun.name,
          cancelable = false,
          min_num = n,
          max_num = n,
          include_equip = true,
        })
      end
    end
  end,
})

Fk:loadTranslationTable{
  ["hs__yinghun"] = "英魂",
  [":hs__yinghun"] = "准备阶段，你可选择一名其他角色并选择一项：1.令其摸X张牌，然后弃置一张牌；2.令其摸一张牌，然后弃置X张牌（X为你已损失的体力值）。",

  ["#hs__yinghun-choose"] = "英魂：你可以令一名其他角色：摸%arg张牌然后弃置一张牌，或摸一张牌然后弃置%arg张牌",
  ["#hs__yinghun-draw"] = "摸%arg张牌，弃置一张牌",
  ["#hs__yinghun-discard"] = "摸一张牌，弃置%arg张牌",

  ["$hs__yinghun1"] = "以吾魂魄，保佑吾儿之基业。",
  ["$hs__yinghun2"] = "不诛此贼三族，则吾死不瞑目！",
}

return yinghun
