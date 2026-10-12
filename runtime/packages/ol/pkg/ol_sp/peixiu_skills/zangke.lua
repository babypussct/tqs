local zangke = fk.CreateSkill {
  name = "peixiu_zangke",
}

Fk:loadTranslationTable {
  ["peixiu_zangke"] = "牂牁",
  [":peixiu_zangke"] = "你受到伤害后，你可以弃置你与伤害来源各一张牌。",

  ["#peixiu_zangke-invoke"] = "牂牁：是否弃置你与 %dest 各一张牌？",
}

zangke:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return  target == player and player:hasSkill(zangke.name) and
      data.from and not data.from.dead
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = zangke.name,
      prompt = "#peixiu_zangke-invoke::" .. data.from.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = zangke.name,
      cancelable = false,
    })
    if not player.dead and not target:isNude() then
      local id = room:askToChooseCard(player, {
        target = data.from,
        flag = "he",
        skill_name = zangke.name,
      })
      room:throwCard(id, zangke.name, data.from, player)
    end
  end,
})

return zangke
