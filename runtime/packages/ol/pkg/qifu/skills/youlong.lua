local youlong = fk.CreateSkill{
  name = "youlong",
  tags = { Skill.Switch },
  max_branches_use_time = {
    ["yang"] = {
      [Player.HistoryRound] = 1
    },
    ["yin"] = {
      [Player.HistoryRound] = 1
    },
  }
}

Fk:loadTranslationTable{
  ["youlong"] = "游龙",
  [":youlong"] = "转换技，每轮各限一次，你可以废除一个装备栏并视为使用一张未以此法使用过的：阳：普通锦囊牌；阴：基本牌。",

  ["@$youlong"] = "游龙",
  ["#youlong-choice"] = "游龙: 请选择废除一个装备栏",
  ["#youlong-yang"] = "游龙：你可以废除一个装备栏，视为使用一张未以此法使用过的普通锦囊牌",
  ["#youlong-yin"] = "游龙：你可以废除一个装备栏，视为使用一张未以此法使用过的基本牌",

  ["$youlong1"] = "赤壁献策，再谱春秋！",
  ["$youlong2"] = "卧龙出山，谋定万古！",
}

youlong:addEffect("viewas", {
  anim_type = "switch",
  pattern = ".",
  prompt = function(self, player, selected_cards, selected)
    return "#youlong-"..player:getSwitchSkillState(youlong.name, false, true)
  end,
  filter_pattern = {
    min_num = 0,
    max_num = 0,
    pattern = "",
    subcards = {}
  },
  card_filter = Util.FalseFunc,
  interaction_helper = function(self, player)
    local all_names = Fk:getAllCardNames(player:getSwitchSkillState(youlong.name) == fk.SwitchYang and "t" or "b")
    local names = player:getViewAsCardNames(youlong.name, all_names, {})
    local used = player:getTableMark("@$youlong")
    names = table.filter(names, function(name) return not table.contains(used, name) end)
    return UI.CardNameBox { choices = names, all_choices = all_names }
  end,
  update_interaction = function(self, player, selected_cards, selected_targets, extra_data)
    ViewAsSkill.update_interaction(self, player, selected_cards, selected_targets)
    local spec = self.interaction.spec
    if spec.result then
      local req = spec.UIrequest
      if req.elemType == "OptionBox" and req.option ~= "Cancel" then
        spec.result.option = req.option
      end
      self.interaction.data = spec.result
    end
  end,
  refresh_interaction = function(self, player, selected_cards, selected_targets, extra_data)
    local spec = self.interaction.spec
    local refresh_data = {}
    if spec.result == nil then
      local op_spec = {   ---@class OptionBoxParams
        options = player:getAvailableEquipSlots()
      }
      refresh_data.optionBox = UI.OptionBox(op_spec)
      return refresh_data
    end
    return ViewAsSkill.refresh_interaction(self, player, selected_cards, selected_targets)
  end,
  view_as = function(self, player, cards)
    local name = (self.interaction.data or {}).name
    if name == nil then return end
    return Fk:cloneCard(name, nil, nil, youlong.name)
  end,
  history_branch = function(self, player, data)
    return player:getSwitchSkillState(youlong.name, false, true)
  end,
  on_use = function(self, room, skillUseEvent, card, params)
    local player = skillUseEvent.from
    room:addTableMark(player, "@$youlong", card.name)
    room:abortPlayerArea(player, skillUseEvent.interaction_data.option)
    return {
      from = skillUseEvent.from,
      tos = skillUseEvent.tos,
      card = card,
    }
  end,
  enabled_at_play = function(self, player)
    local state = player:getSwitchSkillState(youlong.name, false, true)
    return youlong:withinBranchTimesLimit(player, state, Player.HistoryRound) and #player:getAvailableEquipSlots() > 0
  end,
  enabled_at_response = function(self, player, response)
    if response or #player:getAvailableEquipSlots() == 0 then return end
    local state = player:getSwitchSkillState(youlong.name, false, true)
    if not youlong:withinBranchTimesLimit(player, state, Player.HistoryRound) then return end
    local names = player:getViewAsCardNames(youlong.name, Fk:getAllCardNames(state == "yang" and "t" or "b"), {})
    local used = player:getTableMark("@$youlong")
    return table.find(names, function(name) return not table.contains(used, name) end) ~= nil
  end,
  enabled_at_nullification = function(self, player, data)
    return #player:getAvailableEquipSlots() > 0 and
      player:getSwitchSkillState(youlong.name, false) == fk.SwitchYang and
      youlong:withinBranchTimesLimit(player, "yang", Player.HistoryRound) and
      not table.contains(player:getTableMark("@$youlong"), "nullification")
  end,
}, { check_skill_limit = true })

return youlong
