local yizhi = fk.CreateSkill {
  name = "yizhil",
  tags = { Skill.Lord },
}

Fk:loadTranslationTable{
  ["yizhil"] = "益治",
  [":yizhil"] = "主公技，出牌阶段限一次，你可以视为对群势力角色使用一张【五谷丰登】。",

  ["#yizhil"] = "益治：你可以视为对群势力角色使用一张【五谷丰登】",

  ["$yizhil1"] = "此岁丰稔，当与诸君共浮一大白！",
  ["$yizhil2"] = "凡入我益州之士，皆为我座上之宾。",
}

yizhi:addEffect("active", {
  anim_type = "support",
  prompt = "#yizhil",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    if player:usedSkillTimes(yizhi.name, Player.HistoryPhase) == 0 then
      local ag = Fk:cloneCard("amazing_grace")
      ag.skillName = yizhi.name
      return not player:prohibitUse(ag) and
        table.find(Fk:currentRoom().alive_players, function(p)
          return p.kingdom == "qun" and not player:isProhibited(p, ag)
        end)
    end
  end,
  fix_targets = function(self, player, selected_cards, card, extra_data)
    local ag = Fk:cloneCard("amazing_grace")
    ag.skillName = yizhi.name
    if player:prohibitUse(ag) then return {} end
    return table.filter(Fk:currentRoom().alive_players, function(p)
      return p.kingdom == "qun" and not player:isProhibited(p, ag)
    end)
  end,
  on_use = function(self, room, effect)
    room:useVirtualCard("amazing_grace", effect.cards, effect.from, effect.tos, yizhi.name)
  end,
})

return yizhi
