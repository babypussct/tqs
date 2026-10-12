local beini = fk.CreateSkill {
  name = "mobile__beini",
}

Fk:loadTranslationTable{
  ["mobile__beini"] = "悖逆",
  [":mobile__beini"] = "出牌阶段限一次，你可以选择一名体力值不小于你的角色，令你或其摸两张牌，然后未摸牌的角色选择一项："..
  "1.视为对摸牌的角色使用一张无距离次数限制的【杀】；2.获得摸牌的角色场上的一张牌。",

  ["#mobile__beini"] = "悖逆：选择一名体力值不小于你的角色，一方摸两张牌，另一方对其使用杀或获得牌",
  ["mobile__beini_own"] = "你摸两张牌，其选一项",
  ["mobile__beini_other"] = "其摸两张牌，你选一项",
  ["mobile__beini_slash"] = "视为对 %dest 使用【杀】",
  ["mobile__beini_prey"] = "获得 %dest 场上一张牌",

  ["$mobile__beini1"] = "今日污无用清名，明朝自得新圣褒嘉。",
  ["$mobile__beini2"] = "吾佐奉朝日暖旭，又何惮落月残辉？",
}

beini:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#mobile__beini",
  can_use = function(self, player)
    return player:usedSkillTimes(beini.name, Player.HistoryPhase) < 1
  end,
  target_num = 1,
  interaction = UI.ComboBox { choices = {"mobile__beini_own", "mobile__beini_other"} },
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and to_select.hp >= player.hp
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local to = self.interaction.data == "mobile__beini_own" and player or target
    local from = self.interaction.data == "mobile__beini_other" and player or target
    to:drawCards(2, beini.name)
    if to.dead or from.dead then return end
    local all_choices = {"mobile__beini_slash::"..to.id, "mobile__beini_prey::"..to.id}
    local choices = {}
    if from:canUseTo(Fk:cloneCard("slash"), to, {
      bypass_distances = true,
      bypass_times = true,
    }) then
      table.insert(choices, all_choices[1])
    end
    if #to:getCardIds("ej") > 0 then
      table.insert(choices, all_choices[2])
    end
    if #choices == 0 then return end
    local choice = room:askToChoice(from, {
      choices = choices,
      skill_name = beini.name,
      all_choices = all_choices,
    })
    if choice == all_choices[1] then
      room:useVirtualCard("slash", nil, from, to, beini.name, true)
    else
      local card = room:askToChooseCard(from, {
        target = to,
        flag = "ej",
        skill_name = beini.name,
      })
      room:obtainCard(from, card, true, fk.ReasonPrey, from, beini.name)
    end
  end,
})

return beini
