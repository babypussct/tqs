local yanzhu = fk.CreateSkill{
  name = "m_ex__yanzhu",
}

Fk:loadTranslationTable{
  ["m_ex__yanzhu"] = "宴诛",
  [":m_ex__yanzhu"] = "出牌阶段限一次，你可以令一名其他角色选择一项：1.令你获得其区域内的一张牌；2.令你获得其装备区里的所有牌（至少一张），然后你失去〖宴诛〗。",

  ["#m_ex__yanzhu-active"] = "宴诛：选择1名区域里有牌的其他角色",
  ["#m_ex__yanzhu-choice"] = "宴诛：选择令%src获得你区域里一张牌或令%src获得你装备区所有牌并失去宴诛",
  ["m_ex__yanzhu_choice1"] = "令其获得你区域里的一张牌",
  ["m_ex__yanzhu_choice2"] = "令其获得你装备区里所有牌并失去宴诛",

  ["$m_ex__yanzhu1"] = "计设辞阳宴，只为断汝头！",
  ["$m_ex__yanzhu2"] = "何需待午正？即刻送汝行！",
}

yanzhu:addEffect("active", {
  anim_type = "control",
  prompt = "#m_ex__yanzhu-active",
  max_phase_use_time = 1,
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and not to_select:isAllNude()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local choices = {"m_ex__yanzhu_choice1"}
    if #target.player_cards[Player.Equip] > 0 then
      table.insert(choices, "m_ex__yanzhu_choice2")
    end
    local choice = room:askToChoice(target, {
      choices = choices,
      skill_name = yanzhu.name,
      prompt = "#m_ex__yanzhu-choice:" .. player.id,
    })
    if choice == "m_ex__yanzhu_choice1" then
      local card = room:askToChooseCard(player, {
        target = target,
        flag = "hej",
        skill_name = yanzhu.name
      })
      room:obtainCard(player, card, false, fk.ReasonPrey, player, yanzhu.name)
    elseif choice == "m_ex__yanzhu_choice2" then
      room:obtainCard(player, target:getCardIds("e"), true, fk.ReasonPrey, player, yanzhu.name)
      if player.dead then return end
      room:handleAddLoseSkills(player, "-" .. self.name, nil, true, false)
    end
  end,
})

return yanzhu
