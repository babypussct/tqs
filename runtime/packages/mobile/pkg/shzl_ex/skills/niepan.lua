local niepan = fk.CreateSkill{
  name = "m_ex__niepan",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["m_ex__niepan"] = "涅槃",
  [":m_ex__niepan"] = "限定技，出牌阶段，或当你处于濒死状态时，你可以弃置你区域里所有的牌，摸三张牌，将体力值回复至3点，复原武将牌。",

  ["#m_ex__niepan"] = "涅槃：是否弃置区域里所有的牌，摸三张牌，将体力值回复至3点，复原武将牌？",

  ["$m_ex__niepan1"] = "凤凰折翅，涅槃再生。",
  ["$m_ex__niepan2"] = "九天之志，展翅翱翔。",
}

niepan:addEffect("active", {
  anim_type = "defensive",
  prompt = "#m_ex__niepan",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(niepan.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    player:throwAllCards("hej", niepan.name)
    if player.dead then return end
    player:drawCards(3, niepan.name)
    if not player.dead and math.min(3, player.maxHp) > player.hp then
      room:recover{
        who = player,
        num = math.min(3, player.maxHp) - player.hp,
        recoverBy = player,
        skillName = niepan.name,
      }
    end
    if not player.dead then
      player:reset()
    end
  end,
})
niepan:addEffect(fk.AskForPeaches, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(niepan.name) and player.dying and
      player:usedSkillTimes(niepan.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(niepan.name)
    room:notifySkillInvoked(player, niepan.name, "support")
    Fk.skills[niepan.name]:onUse(room, {
      from = player,
    })
  end,
})

return niepan
