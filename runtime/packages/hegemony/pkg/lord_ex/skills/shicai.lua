local shicai = fk.CreateSkill {
  name = "ld__shicai",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable {
  ["ld__shicai"] = "恃才",
  [":ld__shicai"] = "锁定技，当你受到伤害后，若此伤害为1点，你摸一张牌，否则你弃置两张牌。",

  ["$ld__shicai1"] = "吾才满腹，袁本初竟不从之。",
  ["$ld__shicai2"] = "阿瞒有我良计，取冀州便是易如反掌。",
}

shicai:addEffect(fk.Damaged, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shicai.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(shicai.name)
    if data.damage == 1 then
      room:notifySkillInvoked(player, shicai.name, "masochism")
      player:drawCards(1, shicai.name)
    else
      room:notifySkillInvoked(player, shicai.name, "negative")
      room:askToDiscard(player, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = shicai.name,
        cancelable = false,
      })
    end
  end,
})

return shicai
