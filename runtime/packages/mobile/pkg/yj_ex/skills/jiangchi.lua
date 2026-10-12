local jiangchi = fk.CreateSkill {
  name = "m_ex__jiangchi",
}

Fk:loadTranslationTable{
  ["m_ex__jiangchi"] = "将驰",
  [":m_ex__jiangchi"] = "出牌阶段开始时，你可以选择一项：1.摸一张牌，此阶段不能使用【杀】；2.弃置一张牌，本阶段使用【杀】无距离限制且可以多使用一张【杀】。",

  ["#m_ex__jiangchi-invoke"] = "将驰：你可以摸一张牌，本阶段不能出杀；或选择一张牌弃置，本阶段可多使用一张杀",
  ["m_ex__jiangchi_draw"] = "摸1牌，不能使用杀",
  ["m_ex__jiangchi_discard"] = "弃1牌，用杀无视距离且次数+1",
  ["@@m_ex__jiangchi_targetmod-phase"] = "将驰 多出杀",
  ["@@m_ex__jiangchi_prohibit-phase"] = "将驰 不出杀",

  ["$m_ex__jiangchi1"] = "将飞翼伏，三军整肃。",
  ["$m_ex__jiangchi2"] = "策马扬鞭，奔驰万里。",
}

local U = require "packages.utility.utility"

jiangchi:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiangchi.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local cards, choice = U.askForCardByMultiPatterns(
      player,
      {
        { ".", 0, 0, "m_ex__jiangchi_draw" },
        { ".", 1, 1, "m_ex__jiangchi_discard" }
      },
      self.name,
      true,
      "#m_ex__jiangchi-invoke",
      {
        discard_skill = true
      }
    )
    if choice == "" then return false end
    event:setCostData(self, {cards = cards})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards
    if #cards > 0 then
      room:notifySkillInvoked(player, jiangchi.name, "offensive")
      player:broadcastSkillInvoke(jiangchi.name, 2)
      room:throwCard(cards, jiangchi.name, player)
      if player.dead then return false end
      room:addPlayerMark(player, "@@m_ex__jiangchi_targetmod-phase")
    else
      room:notifySkillInvoked(player, jiangchi.name, "drawcard")
      player:broadcastSkillInvoke(jiangchi.name, 1)
      player:drawCards(1, jiangchi.name)
      if player.dead then return false end
      room:addPlayerMark(player, "@@m_ex__jiangchi_prohibit-phase")
    end
  end,
})

jiangchi:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope, card)
    if card and card.trueName == "slash" and player:getMark("@@m_ex__jiangchi_targetmod-phase") > 0 then
      return 1
    end
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return card and card.trueName == "slash" and player:getMark("@@m_ex__jiangchi_targetmod-phase") > 0
  end,
})

jiangchi:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return player:getMark("@@m_ex__jiangchi_prohibit-phase") > 0 and card.trueName == "slash"
  end,
})

return jiangchi
