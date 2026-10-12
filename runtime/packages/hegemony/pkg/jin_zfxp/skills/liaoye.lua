
local liaoye = fk.CreateSkill {
  name = "heg__liaoye",
}

Fk:loadTranslationTable {
  ["heg__liaoye"] = "燎野",
  [":heg__liaoye"] = "出牌阶段限一次，你可以令一名其他角色选择任意名角色，然后你对所有其本次选择或未选择的其他角色依次造成1点伤害。",

  ["#heg__liaoye"] = "燎野：选择一名角色，其选择任意名角色，你对其选择或未选择角色各造成1点伤害",
  ["#heg__liaoye-choose"] = "燎野：选择任意名角色，%src 对你选择或未选择角色各造成1点伤害",
  ["#heg__liaoye-choice"] = "燎野：对被选择或未选择角色各造成1点伤害",
  ["heg__liaoye_chosen"] = "被选择",
  ["heg__liaoye_unchosen"] = "未被选择",
}

liaoye:addAuxActiveSkill("#heg__liaoye_active", {
  card_num = 0,
  target_num = 0,
  interaction = UI.OptionBox { options = { "heg__liaoye_chosen", "heg__liaoye_unchosen" }, direct_send = true },
  card_filter = Util.FalseFunc,
  target_tip = function (self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if to_select == player then return end
    if table.contains(self.targets, to_select) then
      return "heg__liaoye_chosen"
    else
      return "heg__liaoye_unchosen"
    end
  end,
})

liaoye:addEffect("active", {
  anim_type = "offensive",
  prompt = "#heg__liaoye",
  can_use = function(self, player)
    return player:usedSkillTimes(liaoye.name, Player.HistoryPhase) == 0
  end,
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local targets = room:askToChoosePlayers(target, {
      targets = room.alive_players,
      min_num = 1,
      max_num = #room.alive_players,
      prompt = "#heg__liaoye-choose:"..player.id,
      skill_name = liaoye.name,
    })
    local _, dat = room:askToUseActiveSkill(player, {
      skill_name = "#heg__liaoye_active",
      prompt = "#heg__liaoye-choice",
      cancelable = false,
      extra_data = {
        targets = targets,
      }
    })
    if dat.interaction == "heg__liaoye_chosen" then
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if not p.dead and table.contains(targets, p) then
          room:damage{
            from = player,
            to = p,
            damage = 1,
            skillName = liaoye.name,
          }
        end
      end
    else
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if not p.dead and not table.contains(targets, p) then
          room:damage{
            from = player,
            to = p,
            damage = 1,
            skillName = liaoye.name,
          }
        end
      end
    end
  end,
})

return liaoye
