local sizi = fk.CreateSkill {
  name = "sizi",
  tags = { Skill.Charge },
}

Fk:loadTranslationTable{
  ["sizi"] = "肆恣",
  [":sizi"] = "蓄力技（4/4）。出牌阶段限一次，你可以减至少1点蓄力点，然后获得以下效果，直到X个回合结束后或你的回合开始（X为本次消耗的蓄力点）：" ..
  "1.当一名角色使用【杀】造成伤害时，此伤害+1；2.一名角色的回合结束时，你摸两张牌，然后于本回合内使用过【杀】的角色各失去1点体力。" ..
  "若X大于你的体力值，则额外获得以下效果：一名角色的回合结束时，若本回合没有角色使用过【杀】，当前回合角色失去1点体力。",

  ["#sizi-active"] = "肆恣：你可消耗蓄力点，在等量回合内具有特殊效果",
  ["@sizi_active"] = "肆恣",

  ["$sizi1"] = "昔韩信暗度陈仓，乃定三秦之地。",
  ["$sizi2"] = "今吾大军十万，岂惧蜀道之险？",
  ["$sizi3"] = "德彰功显，取之何愧。",
  ["$sizi4"] = "晋公既已疑我，吾等亦当早决。",
  ["$sizi5"] = "忍辱负重，只为今朝问鼎。",
  ["$sizi6"] = "公无忧天下，顾以康为虑耳。",
  ["$sizi7"] = "公命同乘，何以弃我而去？",
}

local U = require "packages.utility.utility"

sizi:addEffect("active", {
  prompt = "#sizi-active",
  card_num = 0,
  target_num = 0,
  interaction = function(self, player)
    return UI.Spin { from = 1, to = player:getMark("skill_charge") }
  end,
  can_use = function(self, player)
    return player:getMark("skill_charge") > 0 and player:usedSkillTimes(sizi.name) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local num = self.interaction.data

    U.skillCharged(player, -num)
    room:addPlayerMark(player, "@sizi_active", num)
    if num > player.hp then
      room:setPlayerMark(player, "sizi_upgrade", 1)
    end
  end,
})

sizi:addEffect(fk.DamageCaused, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return
      data.card and
      data.card.trueName == "slash" and
      not data.chain and
      player:isAlive() and
      player:getMark("@sizi_active") > 0
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

sizi:addEffect(fk.TurnEnd, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:isAlive() and player:getMark("@sizi_active") > 0
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = sizi.name
    local room = player.room

    player:drawCards(2, skillName)

    local playersSlashed = {}
    player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      local use = e.data
      if use.card.trueName == "slash" then
        table.insertIfNeed(playersSlashed, use.from)
      end
    end, Player.HistoryTurn)

    if #playersSlashed > 0 then
      room:sortByAction(playersSlashed)
      table.forEach(playersSlashed, function(p)
        if p:isAlive() then
          room:loseHp(p, 1, skillName, player)
        end
      end)
    end

    if #playersSlashed == 0 and player:getMark("sizi_upgrade") > 0 and room.current:isAlive() then
      room:loseHp(room.current, 1, skillName, player)
    end
  end,

  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return player:isAlive() and player:getMark("@sizi_active") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:removePlayerMark(player, "@sizi_active")
    if player:getMark("@sizi_active") == 0 then
      player.room:setPlayerMark(player, "sizi_upgrade", 0)
    end
  end,
})

sizi:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:isAlive() and player:getMark("@sizi_active") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@sizi_active", 0)
    player.room:setPlayerMark(player, "sizi_upgrade", 0)
  end,
})

sizi:addAcquireEffect(function (self, player)
  U.skillCharged(player, 4, 4)
end)

sizi:addLoseEffect(function (self, player)
  U.skillCharged(player, -4, -4)
end)

return sizi
