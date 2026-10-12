local wangzun = fk.CreateSkill{
  name = "mobile__wangzun",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["mobile__wangzun"] = "妄尊",
  [":mobile__wangzun"] = "锁定技，体力值大于你的角色的准备阶段，你摸一张牌（若其为主公或地主，你额外摸一张牌且其本回合的手牌上限-1）。",

  ["$mobile__wangzun1"] = "这玉玺，当然是能者居之。",
  ["$mobile__wangzun2"] = "我就是皇帝，我就是天！",
}

wangzun:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Start and player:hasSkill(wangzun.name) and target.hp > player.hp
  end,
  on_use = function(self, event, target, player, data)
    local isLord = target.role_shown and target.role == "lord"
    if isLord then
      player.room:addPlayerMark(target, MarkEnum.MinusMaxCardsInTurn)
    end
    player:drawCards(isLord and 2 or 1, self.name)
  end,
})

return wangzun
