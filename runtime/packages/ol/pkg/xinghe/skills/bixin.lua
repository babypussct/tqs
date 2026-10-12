local bixin = fk.CreateSkill{
  name = "bixin",
  dynamic_desc = function(self, player)
    local x = player:usedSkillTimes("ximo", Player.HistoryGame)
    local text = "bixin_inner:"
    for i = 1, 3, 1 do
      text = text .. (i <= x and "" or "bixin_piece"..i) .. ":"
    end
    if x >= 3 then
      text = text .. "1:3"
    else
      text = text .. "3:1"
    end
    return text
  end,
}

Fk:loadTranslationTable{
  ["bixin"] = "笔心",
  [":bixin"] = "每名角色的准备阶段和结束阶段，你可以声明一种牌的类型并摸3张牌（每种类型限1次），将所有此类型手牌当你本轮未使用过的基本牌使用。",

  ["#bixin"] = "笔心：你可以声明一种牌的类型并摸%arg张牌，将所有此类型手牌当一种基本牌使用",
  ["bixin_choice"] = "%arg（还剩%arg2次）",

  [":bixin_inner"] = "{1}{2}{3}你可以声明一种牌的类型并摸{4}张牌（每种类型限{5}次），将所有此类型手牌当你本轮未使用过的基本牌使用。",
  ["bixin_piece1"] = "每名角色的",
  ["bixin_piece2"] = "准备阶段和",
  ["bixin_piece3"] = "结束阶段，",

  ["$bixin1"] = "携笔落云藻，文书剖纤毫。",
  ["$bixin2"] = "执纸抒胸臆，挥笔涕汍澜。",
}

bixin:addEffect("viewas", {
  pattern = ".|.|.|.|.|basic",
  prompt = function(self, player, selected_cards, selected)
    return "#bixin:::".. tostring(player:usedSkillTimes("ximo", Player.HistoryGame) >= 3 and 1 or 3)
  end,
  filter_pattern = {
    min_num = 1,
    max_num = math.huge,
    pattern = ".|.|.|hand",
  },
  card_filter = Util.FalseFunc,
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
    local req = spec.UIrequest or {}

    if req.elemType == "OptionBox" then
      if req.option == "Cancel" then
        --回归选牌步骤
        refresh_data.expandItems = {}
      else
        local items = {}
        local i = 1
        local ban_names = player:getTableMark("bixin-round")
        for _, name in ipairs(Fk:getAllCardNames("b")) do
          local card = Fk:cloneCard(name, nil, nil, bixin.name)
          --此时仍未确定实体牌的逆天技能！
          card:setVSPattern(nil, nil, ".|.|.|hand|" .. card.name)
          table.insert(items, {
            prop = {
              type = "card",
              card = card,
              additional_prop = {
                selectable = (not table.contains(ban_names, card.name) and player:canUseOrResponseInCurrent(card))
              }
            },
            name = name,
            cid = i,
          })
          i = i + 1
        end
        refresh_data.expandItems = items
      end
    elseif req.elemType == "ExpandItem" then
      refresh_data.pendings = spec.pendings
    end

    if spec.result == nil then
      local types, choices, all_choices = {"basic", "trick", "equip"}, {}, {}
      local x = 0
      local choice = ""
      for _, card_type in ipairs(types) do
        x = (player:usedSkillTimes("ximo", Player.HistoryGame) >= 3 and 3 or 1) - player:getMark("bixin_" .. card_type)
        choice = "bixin_choice:::"..card_type..":"..x
        table.insert(all_choices, choice)
        if x > 0 then
          table.insert(choices, choice)
        end
      end
      local op_spec = {   ---@class OptionBoxParams
        options = choices,
        all_options = all_choices
      }
      refresh_data.optionBox = UI.OptionBox(op_spec)
    else
      local handler = ClientInstance.current_request_handler
      if handler and handler.class.name == "ReqActiveSkill" then
        --在读条中使用的情况直接使用自带的确定取消即可（因为可以反复操作）
        local op_spec = {   ---@class OptionBoxParams
          options = {},
          all_options = { "OK" },
          direct_send = true,
          cancelable = true
        }
        local card = self:viewAs(player, selected_cards)
        if card and card:getSkill(player):feasible(player, selected_targets, { }, card) then
          op_spec.options = { "OK" }
        end
        refresh_data.optionBox = UI.OptionBox(op_spec)
      end
    end
    return refresh_data
  end,
  view_as = function(self, player, cards)
    local name = (self.interaction.data or {}).name
    if name == nil then return end
    local card = Fk:cloneCard(name)
    card.skillName = bixin.name
    return card
  end,
  on_use = function(self, room, skillUseEvent, card, params)
    local player = skillUseEvent.from
    local card_type = string.split(skillUseEvent.interaction_data.option, ":")[4]
    room:addPlayerMark(player, "bixin_" .. card_type)
    player:drawCards(1, bixin.name)
    if player.dead then return "" end
    local cards = table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id):getTypeString() == card_type
    end)
    if #cards > 0 then
      card:addSubcards(cards)
      if not player:prohibitUse(card) then
        if card.is_passive then
          local use = {
            from = player,
            tos = skillUseEvent.tos,
            card = card,
          }
          return use
        else
          --只知道会进行合法性检测，但是逻辑不明，暂且只判prohibit
          local tos = table.filter(card:getFixedTargets(player, (params or {}).extra_data) or skillUseEvent.tos, function(p)
            return not player:isProhibited(p, card)
          end)
          if #tos > 0 then
            ---@type UseCardDataSpec
            local use = {
              from = player,
              tos = tos,
              card = card,
            }
            return use
          end
        end
      end
    end
    --响应使用每次读条只能发动一次，出牌阶段不受限制
    return params and bixin.name or ""
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes("ximo", Player.HistoryGame) == 3 and
      (player:getMark("bixin_basic") < 3 or player:getMark("bixin_trick") < 3 or player:getMark("bixin_equip") < 3)
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:usedSkillTimes("ximo", Player.HistoryGame) == 3 and
      (player:getMark("bixin_basic") < 3 or player:getMark("bixin_trick") < 3 or player:getMark("bixin_equip") < 3)
  end,
})

bixin:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(bixin.name) and
      (player:getMark("bixin_basic") == 0 or player:getMark("bixin_trick") == 0 or player:getMark("bixin_equip") == 0) then
      if player:usedSkillTimes("ximo", Player.HistoryGame) == 2 then
        return target == player and player.phase == Player.Finish
      elseif player:usedSkillTimes("ximo", Player.HistoryGame) == 1 then
        return target == player and (player.phase == Player.Start or player.phase == Player.Finish)
      elseif player:usedSkillTimes("ximo", Player.HistoryGame) == 0 then
        return target.phase == Player.Start or target.phase == Player.Finish
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = bixin.name,
      prompt = "#bixin:::3",
      skip = true
    })
    if success and dat then
      event:setCostData(self, { extra_data = dat })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dat = table.simpleClone(event:getCostData(self).extra_data)
    local card_type = string.split(dat.interaction.option, ":")[4]
    room:addPlayerMark(player, "bixin_" .. card_type)
    player:drawCards(3, bixin.name)
    if player.dead then return false end
    local cards = table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id):getTypeString() == card_type
    end)
    if #cards == 0 then return false end
    local card = Fk:cloneCard(dat.interaction.name)
    card.skillName = bixin.name
    card:addSubcards(cards)
    if player:prohibitUse(card) then return false end
    --只知道会进行合法性检测，但是逻辑不明，暂且只判prohibit
    local tos = table.filter(card:getFixedTargets(player) or dat.targets, function(p)
      return not player:isProhibited(p, card)
    end)
    if #tos > 0 then
      room:useCard{
        from = player,
        tos = dat.targets,
        card = card,
        extraUse = true,
      }
    end
  end,
})

bixin:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(bixin.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMark(player, "bixin-round", data.card.name)
  end,
})

bixin:addAcquireEffect(function(self, player, is_start)
  if not is_start then
    local room = player.room
    local names = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      local use = e.data
      if use.from == player then
        table.insertIfNeed(names, use.card.name)
      end
    end, Player.HistoryRound)
    room:setPlayerMark(player, "bixin-round", names)
  end
end)

bixin:addLoseEffect(function(self, player, is_death)
  local room = player.room
  for _, card_type in ipairs({"basic", "trick", "equip"}) do
    room:setPlayerMark(player, "bixin_" .. card_type, 0)
  end
end)

return bixin
