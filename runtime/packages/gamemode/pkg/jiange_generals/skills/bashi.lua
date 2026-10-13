local bashi = fk.CreateSkill {
  name = "jiange__bashi",
}

Fk:loadTranslationTable{
  ["jiange__bashi"] = "拔矢",
  [":jiange__bashi"] = "当你成为其他角色使用【杀】或普通锦囊牌的目标后，你可以将武将牌翻至背面朝上，令此牌对你无效。",

  ["#jiange__bashi-invoke"] = "拔矢：你可以翻面，令此%arg对你无效",
}

bashi:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(bashi.name) and
      data.from ~= player and (data.card:isCommonTrick() or data.card.trueName == "slash") and player.faceup
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = bashi.name,
      prompt = "#jiange__bashi-invoke:::"..data.card:toLogString(),
    })
  end,
  on_use = function(self, event, target, player, data)
    player:turnOver()
    data.use.nullifiedTargets = data.use.nullifiedTargets or {}
    table.insertIfNeed(data.use.nullifiedTargets, player)
  end,
})

return bashi
