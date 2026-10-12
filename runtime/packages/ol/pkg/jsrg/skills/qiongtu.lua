local qiongtu = fk.CreateSkill {
  name = "ol__qiongtu",
  tags = { Skill.AttachedKingdom },
  attached_kingdom = {"qun"},
  derived_piles = "ol__qiongtu",
}

Fk:loadTranslationTable{
  ["ol__qiongtu"] = "穷途",
  [":ol__qiongtu"] = "群势力技，每回合限一次，你可以视为使用一张【无懈可击】并摸一张牌。"..
  "若此【无懈可击】生效，你将被响应牌置于你的武将牌上，否则你将势力变更至魏，并获得武将牌上的所有牌。",

  ["#ol__qiongtu"] = "穷途：你可视为使用一张【无懈可击】并摸一张牌",
  ["#ol__qiongtu-ask"] = "穷途：选择一张非基本牌置于你的武将牌上",

  ["$ol__qiongtu1"] = "箭倒辕门，徒无用也，今大势去矣。",
  ["$ol__qiongtu2"] = "前狼后虎，凶蛇两端，不知何处能归？",
}

qiongtu:addEffect("viewas", {
  anim_type = "control",
  pattern = "nullification",
  prompt = "#ol__qiongtu",
  card_num = 0,
  card_filter = Util.FalseFunc,
  view_as = function(self, player)
    local card = Fk:cloneCard("nullification")
    card.skillName = qiongtu.name
    return card
  end,
  after_use = function(self, player, use)
    if player.dead then return end
    player:drawCards(1, qiongtu.name)
    if player.dead then return end
    local room = player.room
    if use.extra_data and use.extra_data.ol__qiongtu then
      if #player:getPile(qiongtu.name) > 0 then
        room:obtainCard(player, player:getPile(qiongtu.name), true, fk.ReasonJustMove, player, qiongtu.name)
      end
      room:changeKingdom(player, "wei", true)
    elseif use.toCard and room:getCardArea(use.toCard) == Card.Processing then
      player:addToPile(qiongtu.name, use.toCard, true, qiongtu.name)
    end
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:usedSkillTimes(qiongtu.name, Player.HistoryTurn) == 0
  end,
})

qiongtu:addEffect(fk.CardEffectCancelledOut, {
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, qiongtu.name)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local e = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if e then
      local use = e.data
      use.extra_data = use.extra_data or {}
      use.extra_data.ol__qiongtu = true
    end
  end,
})

return qiongtu
