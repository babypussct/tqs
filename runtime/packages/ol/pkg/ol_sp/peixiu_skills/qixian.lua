local qixian = fk.CreateSkill {
  name = "peixiu_qixian",
}

Fk:loadTranslationTable {
  ["peixiu_qixian"] = "祁县",
  [":peixiu_qixian"] = "你获得此技能后，你可以重铸一张装备牌，视为使用一张【杀】或【过河拆桥】（每回合限一次）。",

  ["#peixiu_qixian-invoke"] = "祁县：重铸一张装备牌，视为使用一张【杀】或【过河拆桥】",
}

qixian:addEffect(fk.EventAcquireSkill, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(qixian.name) and data.skill.name == qixian.name and
      not player:isNude() and player:usedSkillTimes(qixian.name, Player.HistoryTurn) == 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local use = room:askToUseVirtualCard(player, {
      name = "slash,dismantlement",
      skill_name = qixian.name,
      prompt = "#peixiu_qixian-invoke",
      cancelable = true,
      skip = true,
      card_filter = {
        n = 1,
        pattern = ".|.|.|.|.|equip",
        fake_subcards = true,
      },
    })
    if use then
      event:setCostData(self, { extra_data = use })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local use = event:getCostData(self).extra_data
    room:recastCard(use.card.fake_subcards, player, qixian.name)
    room:useCard(use)
  end
})

return qixian
