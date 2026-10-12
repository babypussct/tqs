
local yaowu = fk.CreateSkill{
  name = "nos__yaowu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["nos__yaowu"] = "耀武",
  [":nos__yaowu"] = "锁定技，当一名角色使用红色【杀】对你造成伤害时，其回复1点体力或摸一张牌。",

  ["$nos__yaowu1"] = "大人有大量，不和你计较！",
  ["$nos__yaowu2"] = "哼，先让你尝点甜头！",
}

yaowu:addEffect(fk.DamageCaused, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target and player:hasSkill(yaowu.name) and data.to == player and
      data.card and data.card.trueName == "slash" and data.card.color == Card.Red and not target.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"draw1"}
    if target:isWounded() then
      table.insert(choices, "recover")
    end
    local choice = room:askToChoice(target, {
      choices = choices,
      skill_name = yaowu.name,
    })
    if choice == "recover" then
      room:recover({
        who = target,
        num = 1,
        recoverBy = target,
        skillName = yaowu.name,
      })
    else
      target:drawCards(1, yaowu.name)
    end
  end,
})

return yaowu
