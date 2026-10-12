local anran = fk.CreateSkill {
  name = "anran",
}

Fk:loadTranslationTable {
  ["anran"] = "岸然",
  [":anran"] = "出牌阶段开始时或当你受到伤害后，你可以选择：1.摸X张牌；2.令至多X名角色各摸一张牌。然后以此法获得牌的角色本回合使用的下一张牌不能" ..
      "是这些牌（X为此技能发动次数，至多为4）。",

  ["#anran-invoke"] = "岸然：摸%arg张牌，或选择至多%arg名角色各摸一张牌",
  ["anran_draw"] = "摸%arg张牌",
  ["anran_choose"] = "至多%arg名角色各摸一张牌",
  ["@@anran-inhand-turn"] = "岸然",

  ["@[ol_anran]"] = "岸然",
  ["$anran1"] = "此身伟岸，何惧悠悠之口？",
  ["$anran2"] = "天时在彼，何故抱残守缺？",
}

Fk:addQmlMark {
  name = "ol_anran",
  qml_path = "",
  how_to_show = function(_, _, player)
    return tostring(math.min(player:usedSkillTimes(anran.name, Player.HistoryGame) + 1, 4))
  end,
}

anran:addAuxActiveSkill("anran_active", {
  interaction = function(self, player)
    local n = math.min(player:usedSkillTimes("anran", Player.HistoryGame) + 1, 4)
    return UI.OptionBox { options = { "anran_draw:::"..n, "anran_choose:::"..n }, direct_send = true }
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected < math.min(player:usedSkillTimes("anran", Player.HistoryGame) + 1, 4)
  end,
  refresh_interaction = function(self, player, selected_cards, selected_targets, extra_data)
    local n = math.min(player:usedSkillTimes("anran", Player.HistoryGame) + 1, 4)
    if #selected_targets > 0 then
      return { "anran_choose:::"..n }
    else
      return { "anran_draw:::"..n }
    end
  end
})

local spec = {
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "anran_active",
      prompt = "#anran-invoke:::" .. math.min(player:usedSkillTimes(anran.name, Player.HistoryGame) + 1, 4),
      cancelable = true,
    })
    if success and dat then
      local tos = dat.targets
      room:sortByAction(tos)
      event:setCostData(self, { tos = tos, choice = dat.interaction })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local n = math.min(player:usedSkillTimes(anran.name, Player.HistoryGame), 4)
    local choice = event:getCostData(self).choice
    if choice:startsWith("anran_draw") then
      player:drawCards(n, anran.name, "top", "@@anran-inhand-turn")
    else
      for _, p in ipairs(event:getCostData(self).tos) do
        if not p.dead then
          p:drawCards(1, anran.name, "top", "@@anran-inhand-turn")
        end
      end
    end
  end,
}

anran:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(anran.name) and player.phase == Player.Play
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})
anran:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(anran.name)
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})
anran:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return target == player and not player:isKongcheng()
  end,
  on_refresh = function(self, event, target, player, data)
    for _, id in ipairs(player:getCardIds("h")) do
      player.room:setCardMark(Fk:getCardById(id), "@@anran-inhand-turn", 0)
    end
  end,
})
anran:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    local subcards = card:isVirtual() and card.subcards or { card.id }
    return #subcards > 0 and table.find(subcards, function(id)
      return Fk:getCardById(id):getMark("@@anran-inhand-turn") > 0
    end)
  end,
})

anran:addAcquireEffect(function(self, player, is_start)
  player.room:setPlayerMark(player, "@[ol_anran]", math.min(player:usedSkillTimes(anran.name, Player.HistoryGame) + 1, 4))
end)

anran:addLoseEffect(function(self, player, is_death)
  player.room:setPlayerMark(player, "@[ol_anran]", 0)
end)
return anran
