local qingjian = fk.CreateSkill{
  name = "m_ex__qingjian",
}

Fk:loadTranslationTable{
  ["m_ex__qingjian"] = "清俭",
  [":m_ex__qingjian"] = "每回合限一次，当你于摸牌阶段外获得牌后，你可以将任意张手牌扣置于你的武将牌上；一名角色的结束阶段，若你的武将牌上"..
  "有“清俭”牌，你将这些牌分配给其他角色，若交出的牌大于一张，你摸一张牌。",

  ["$m_ex__qingjian"] = "清俭",
  ["#m_ex__qingjian-ask"] = "清俭：你可以将任意张手牌扣置为“清俭”牌，结束阶段分配这些牌给其他角色",

  ["$m_ex__qingjian1"] = "俭而有度，志在千里！",
  ["$m_ex__qingjian2"] = "戒奢宁俭，以聚军心！",
}

qingjian:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(qingjian.name) and player:usedEffectTimes(qingjian.name, Player.HistoryTurn) == 0 and
      player.phase ~= Player.Draw and not player:isKongcheng() then
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Player.Hand and move.skillName ~= qingjian.name then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 999,
      include_equip = false,
      skill_name = qingjian.name,
      prompt = "#m_ex__qingjian-ask",
      cancelable = true,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:addToPile("$m_ex__qingjian", event:getCostData(self).cards, false, qingjian.name)
  end,
})
qingjian:addEffect(fk.EventPhaseStart, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(qingjian.name) and target.phase == Player.Finish and
      #player:getPile("$m_ex__qingjian") > 0 and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getPile("$m_ex__qingjian")
    room:askToYiji(player, {
      min_num = #cards,
      max_num = #cards,
      skill_name = qingjian.name,
      targets = room:getOtherPlayers(player, false),
      cards = cards,
      prompt = "#guandu__sushou-give",
      expand_pile = cards,
    })
    if #cards > 1 and not player.dead then
      player:drawCards(1, qingjian.name)
    end
  end,
})

return qingjian
