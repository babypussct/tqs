local yinshi = fk.CreateSkill {
  name = "yinship",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["yinship"] = "隐世",
  [":yinship"] = "锁定技，你只有摸牌、出牌和弃牌阶段；你不能被选择为延时锦囊牌的目标。",
}

yinshi:addEffect(fk.EventPhaseChanging, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yinshi.name) and
      table.contains({Player.Start, Player.Judge, Player.Finish}, data.phase) and not data.skipped
  end,
  on_use = function (self, event, target, player, data)
    data.skipped = true
  end,
})
yinshi:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return to:hasSkill(yinshi.name) and card and card.sub_type == Card.SubtypeDelayedTrick
  end,
})

return yinshi
