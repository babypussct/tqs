local threatenEmperorSkill = fk.CreateSkill{
  name = "threaten_emperor_skill",
}

local H = require "packages.hegemony.util"

threatenEmperorSkill:addEffect("cardskill", {
  prompt = "#threaten_emperor_skill",
  mod_target_filter = function(self, player, to_select, selected)
    return to_select == player and H.isBigKingdomPlayer(player)
  end,
  can_use = function(self, player, card)
    return not player:isProhibited(player, card) and H.isBigKingdomPlayer(player)
  end,
  on_use = function(self, room, use)
    if not use.tos or #use.tos == 0 then
      use.tos = { use.from }
    end
  end,
  on_effect = function(self, room, effect)
    local target = effect.to
    room:setPlayerMark(target, "_TEeffect-turn", 1)
    target:endPlayPhase()
  end,
})

threatenEmperorSkill:addEffect(fk.EventPhaseEnd, {
  name = "#threaten_emperor_extra",
  global = true,
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Discard and player:getMark("_TEeffect-turn") > 0 and player.room.current == target
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askToDiscard(player,{ min_num = 1, max_num = 1, include_equip = false, skill_name = self.name, prompt = "#TE-ask", skip = true})
    if #card > 0 then
      event:setCostData(self, { cards = card })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, self.name, player, player)
    player:gainAnExtraTurn()
  end,
})

threatenEmperorSkill:addTest(function (room, me)
  local card = room:printCard("threaten_emperor")
  local comp = table.find(room.alive_players, function(p) return not H.isBigKingdomPlayer(p) end)
  if comp then lu.assertIsFalse(comp:canUse(card)) end

  comp = table.find(room.alive_players, function(p) return H.isBigKingdomPlayer(p) end)
  if comp then
    FkTest.runInRoom(function()
      room:obtainCard(comp, 1)
      room:obtainCard(comp, card)
    end)

    FkTest.setNextReplies(comp, {
      json.encode {
        card = card.id, targets = { comp.id },
      },
      "", "1",
    })
    FkTest.runInRoom(function()
      comp:gainAnExtraTurn()
    end)
  end
end)

Fk:loadTranslationTable{
  ["threaten_emperor"] = "挟天子以令诸侯",
  [":threaten_emperor"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：为大势力角色的你<br/><b>效果</b>：目标角色结束出牌阶段，此回合的弃牌阶段结束时，若其为当前回合角色，其可弃置一张手牌，然后其获得一个额外回合。",
  ["#TE-ask"] = "受到【挟天子以令诸侯】影响，你可以弃置一张手牌，获得一个额外回合",
  ["threaten_emperor_skill"] = "挟天子以令诸侯",
  ["#threaten_emperor_extra"] = "挟天子以令诸侯",
  ["#threaten_emperor_skill"] = "你结束出牌阶段，此回合弃牌阶段结束时，你可弃置一张手牌，然后获得一个额外回合",
}

return threatenEmperorSkill
