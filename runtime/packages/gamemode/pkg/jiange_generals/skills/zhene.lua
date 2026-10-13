local zhene = fk.CreateSkill {
  name = "jiange__zhene",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiange__zhene"] = "震恶",
  [":jiange__zhene"] = "锁定技，当你于出牌阶段使用牌指定目标后，若目标角色手牌数不大于你，其不能响应。",
}

zhene:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhene.name) and player.phase == Player.Play and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      data.to:getHandcardNum() <= player:getHandcardNum()
  end,
  on_use = function(self, event, target, player, data)
    data.use.disresponsiveList = data.use.disresponsiveList or {}
    table.insertIfNeed(data.use.disresponsiveList, data.to)
  end,
})

return zhene
