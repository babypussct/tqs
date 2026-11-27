
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
  ["#heg__liaoye-selected"] = "燎野：%from 选择了 %to",
  ["#heg__liaoye-selected-none"] = "燎野：%from 没有选择任何角色",
  ["#heg__liaoye-damage-choice"] = "燎野：%from 选择对“%arg”组造成伤害",
  ["#heg__liaoye-damage-auto"] = "燎野：%from 未确认，系统随机选择对“%arg”组造成伤害",
}

local damageChoices = { "heg__liaoye_chosen", "heg__liaoye_unchosen" }
liaoye:addAuxActiveSkill("#heg__liaoye_active", {
  card_num = 0,
  target_num = 0,
  interaction = UI.OptionBox { options = damageChoices },
  card_filter = Util.FalseFunc,
  feasible = function(self, player, selected, selected_cards)
    return #selected == 0 and #selected_cards == 0 and table.contains(damageChoices, self.interaction.data)
  end,
  target_tip = function (self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if to_select == player or not extra_data or not extra_data.targets then return end
    if table.contains(extra_data.targets, to_select.id) then
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
    local targetIds = table.map(targets, Util.IdMapper)
    if #targetIds > 0 then
      room:sendLog{ type = "#heg__liaoye-selected", from = target.id, to = targetIds }
    else
      room:sendLog{ type = "#heg__liaoye-selected-none", from = target.id }
    end
    local _, dat = room:askToUseActiveSkill(player, {
      skill_name = "#heg__liaoye_active",
      prompt = "#heg__liaoye-choice",
      cancelable = false,
      extra_data = {
        targets = targetIds,
      }
    })
    local choice = dat and dat.interaction
    local logType = "#heg__liaoye-damage-choice"
    if not table.contains(damageChoices, choice) then
      choice = room:tableRandomPick(damageChoices)
      logType = "#heg__liaoye-damage-auto"
    end

    room:sendLog{ type = logType, from = player.id, arg = choice, toast = true }
    local damageChosen = choice == "heg__liaoye_chosen"
    local damageTargets = table.filter(room:getOtherPlayers(player), function(p)
      return not p.dead and table.contains(targetIds, p.id) == damageChosen
    end)
    if #damageTargets > 0 then
      room:doIndicate(player, damageTargets)
    end
    for _, p in ipairs(damageTargets) do
      if not p.dead then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          skillName = liaoye.name,
        }
      end
    end
  end,
})

return liaoye
