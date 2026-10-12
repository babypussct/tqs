local dangxian = fk.CreateSkill{
  name = "m_ex__dangxian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["m_ex__dangxian"] = "当先",
  [":m_ex__dangxian"] = "锁定技，回合开始时，你从弃牌堆获得一张【杀】并执行一个额外的出牌阶段。",

  ["$m_ex__dangxian1"] = "谁言蜀汉已无大将？",
  ["$m_ex__dangxian2"] = "老将虽白发，宝刀刃犹锋！",
}

dangxian:addEffect(fk.TurnStart, {
  anim_type = "offensive",
  on_use = function(self, event, target, player, data)
    local cards = player.room:getCardsFromPileByRule("slash", 1, "discardPile")
    if #cards > 0 then
      player.room:obtainCard(player, cards[1], true, fk.ReasonJustMove, player, dangxian.name)
      if player.dead then return false end
    end
    player:gainAnExtraPhase(Player.Play, dangxian.name)
  end,
})

return dangxian
