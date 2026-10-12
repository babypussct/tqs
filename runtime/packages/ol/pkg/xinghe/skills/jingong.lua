local jingong = fk.CreateSkill{
  name = "jingong",
}

Fk:loadTranslationTable{
  ["jingong"] = "矜功",
  [":jingong"] = "出牌阶段限一次，你可以将一张装备牌或【杀】当一张锦囊牌使用（从两种随机普通锦囊牌和【美人计】、【笑里藏刀】随机一种中三选一）。",

  ["#jingong"] = "矜功：你可以将一张装备牌或【杀】当一张锦囊使用",

  ["$jingong1"] = "董贼旧部，可尽诛之！",
  ["$jingong2"] = "若无老夫之谋，尔等皆化为腐土也。",
}

jingong:addEffect("viewas", {
  anim_type = "control",
  prompt = "#jingong",
  handly_pile = true,
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = "slash;.|.|.|.|.|equip",
  },
  interaction_helper = function(self, player, selected_cards)
    local names = player:getMark("jingong-phase")
    if names == 0 then
      names = { "dismantlement", "ex_nihilo", "daggar_in_smile" }
    end
    return UI.CardNameBox {
      choices = player:getViewAsCardNames(jingong.name, names, selected_cards),
      all_choices = names
    }
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    return Fk:cloneCard(self.interaction.data, nil, nil, jingong.name, cards)
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(jingong.name, Player.HistoryPhase) == 0
  end,
})
jingong:addEffect(fk.EventPhaseStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(jingong.name, true) and player.phase == Player.Play
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local names = table.filter(Fk:getAllCardNames("t"), function(name)
      return not Fk:cloneCard(name).is_passive
    end)
    names = room:tableRandomPick(names, 2)
    table.insert(names, room:tableRandomPick({"honey_trap", "daggar_in_smile"}))
    player.room:setPlayerMark(player, "jingong-phase", names)
  end,
})

return jingong
