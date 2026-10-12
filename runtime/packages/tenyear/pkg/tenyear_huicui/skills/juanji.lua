local juanji = fk.CreateSkill {
  name = "juanji",
}

Fk:loadTranslationTable{
  ["juanji"] = "狷急",
  [":juanji"] = "出牌阶段每项限一次，你可以：<br>"..
  "1.与一名其他角色各回复X点体力，然后对你与其各造成X点伤害；<br>"..
  "2.弃置至多X名其他角色各一张牌，然后你翻面；<br>"..
  "3.摸X张牌，然后弃置等量的牌。<br>"..
  "（X为本回合发动此技能次数）",

  ["#juanji"] = "狷急：你可以执行一项",
  ["juanji_recover"] = "与一名角色各回复%arg点体力，然后对你与其各造成%arg点伤害",
  ["juanji_discard"] = "弃置至多%arg名角色各一张牌，然后你翻面",
  ["juanji_draw"] = "摸%arg张牌，然后弃等量的牌",

  ["$juanji1"] = "野雀飞上枝头，真当自己是凤凰了。",
  ["$juanji2"] = "鹦哥学舌，本是禽兽，装个甚的人模样。",
}

juanji:addEffect("active", {
  anim_type = "control",
  prompt = "#juanji",
  interaction = function (self, player)
    local n = player:usedSkillTimes(juanji.name, Player.HistoryTurn) + 1
    local all_choices = { "juanji_recover:::"..n, "juanji_discard:::"..n, "juanji_draw:::"..n }
    local choices = table.filter(all_choices, function (choice)
      return not table.contains(player:getTableMark("juanji-phase"), string.split(choice, ":")[1])
    end)
    return UI.ComboBox { choices = choices, all_choices = all_choices}
  end,
  card_num = 0,
  min_target_num = 0,
  can_use = function(self, player)
    return #player:getTableMark("juanji-phase") < 3
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected, selected_cards)
    if self.interaction.data:startsWith("juanji_recover") then
      return #selected == 0 and to_select ~= player
    elseif self.interaction.data:startsWith("juanji_discard") then
      return #selected <= player:usedSkillTimes(juanji.name, Player.HistoryTurn) and
        to_select ~= player
    elseif self.interaction.data:startsWith("juanji_draw") then
      return false
    end
  end,
  feasible = function (self, player, selected, selected_cards, card)
    if self.interaction.data:startsWith("juanji_recover") then
      return #selected == 1
    elseif self.interaction.data:startsWith("juanji_discard") then
      return #selected > 0 and #selected <= player:usedSkillTimes(juanji.name, Player.HistoryTurn) + 1
    elseif self.interaction.data:startsWith("juanji_draw") then
      return #selected == 0
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local choice = string.split(self.interaction.data, ":")[1]
    room:addTableMark(player, "juanji-phase", choice)
    local n = player:usedSkillTimes(juanji.name, Player.HistoryTurn)
    if choice == "juanji_recover" then
      local target = effect.tos[1]
      room:recover{
        who = player,
        num = n,
        recoverBy = player,
        skillName = juanji.name,
      }
      if not target.dead then
        room:recover{
          who = target,
          num = n,
          recoverBy = player,
          skillName = juanji.name,
        }
      end
      if not player.dead then
        room:damage{
          from = player,
          to = player,
          damage = n,
          skillName = juanji.name,
        }
      end
      if not target.dead then
        room:damage{
          from = player,
          to = target,
          damage = n,
          skillName = juanji.name,
        }
      end
    elseif choice == "juanji_discard" then
      room:sortByAction(effect.tos)
      for _, p in ipairs(effect.tos) do
        if player.dead then return end
        if not p.dead and not p:isNude() then
          local card = room:askToChooseCard(player, {
            target = p,
            flag = "he",
            skill_name = juanji.name,
          })
          room:throwCard(card, juanji.name, p, player)
        end
      end
      if not player.dead then
        player:turnOver()
      end
    elseif choice == "juanji_draw" then
      player:drawCards(n, juanji.name)
      if not player.dead then
        room:askToDiscard(player, {
          min_num = n,
          max_num = n,
          include_equip = true,
          skill_name = juanji.name,
          cancelable = false,
        })
      end
    end
  end,
})

return juanji
