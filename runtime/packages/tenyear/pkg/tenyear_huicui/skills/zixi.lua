local zixi = fk.CreateSkill {
  name = "zixi",
}

Fk:loadTranslationTable{
  ["zixi"] = "姊希",
  [":zixi"] = "出牌阶段开始时和结束时，你可以将至多两张“琴”置入一名角色的判定区。当你使用基本牌或普通锦囊牌指定唯一目标后，你可以根据"..
  "其判定区牌的张数执行效果：1张，此牌对其额外结算1次；2张，你摸两张牌；3张，获得其判定区和装备区所有牌，对其造成3点伤害。",

  ["#zixi-choose"] = "姊希：你可以将至多两张“琴”置入一名角色的判定区",
  ["#zixi-invoke1"] = "姊希：你可以令%arg对 %dest 额外结算一次",
  ["#zixi-invoke2"] = "姊希：你可以摸两张牌",
  ["#zixi-invoke3"] = "姊希：你可以获得 %dest 场上所有牌并对其造成3点伤害！",
  ["#zixi-name"] = "姊希：选择%arg置入 %dest 判定区的牌名",

  ["$zixi1"] = "日暮飞伯劳，倦梳头，坐看鸥鹭争舟。",
  ["$zixi2"] = "姊折翠柳寄江北，念君心悠悠。",
}

local delayedTrickNames = { "indulgence", "supply_shortage", "lightning" }

zixi:addAuxActiveSkill("#zixi_active", {
  prompt = function(self, player, selected_cards, selected_targets)
    if #selected_cards > 0 and #selected_targets > 0 then
      local i = 1 + #(self.interaction.data or {})
      if i <= #selected_cards then
        return "#zixi-name::" .. selected_targets[1].id .. ":" .. Fk:getCardById(selected_cards[i]):toLogString()
      end
    end
    return "#zixi-choose"
  end,
  min_card_num = 1,
  max_card_num = 2,
  target_num = 1,
  card_filter = function(self, player, to_select, selected, selected_targets)
    local max_num = 2
    if #selected_targets > 0 then
      local to = selected_targets[1]
      max_num = math.min(2, #table.filter(delayedTrickNames, function(name)
        return not to:hasDelayedTrick(name)
      end))
    end
    return #selected < max_num and Fk:getCardById(to_select, true):getMark("qiqin") > 0
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and not table.contains(to_select.sealedSlots, Player.JudgeSlot) and
    not table.every(delayedTrickNames, function(name)
      return to_select:hasDelayedTrick(name)
    end)
  end,
  update_interaction = function(self, player, selected_cards, selected_targets, extra_data)
    local spec = self.interaction.spec or {}
    local dat = self.interaction.data
    spec.UIrequest = table.simpleClone(dat)
    if dat.option then
      if dat.option == "Cancel" then
        --FIXME(邪道实现): 直接修改req来取消self.pendings选牌
        local handler = ClientInstance.current_request_handler
        if handler then
          handler.pendings = {}
        end
        spec.result = nil
      else
        if spec.result then
          table.insert(spec.result.options, dat.option )
        else
          spec.result = { options = { dat.option } }
        end
        spec.UIrequest.selected_targets = selected_targets
        dat.autoTarget = false
      end
    end
    self.interaction.data = (spec.result or {}).options
  end,
  refresh_interaction = function(self, player, selected_cards, selected_targets, extra_data)
    local spec = self.interaction.spec or {}
    local refresh_data = {}
    local tos = selected_targets
    local req = spec.UIrequest or {}
    if #tos == 0 and req.selected_targets and #req.selected_targets > 0 then
      --interaction.data变化会掉目标，要在这里补上
      local handler = ClientInstance.current_request_handler
      if handler then
        tos = req.selected_targets
        handler:selectTarget(tos[1].id, { selected = true })
      end
    end
    if spec.UIrequest == nil then
      --重选卡牌和目标均需要清除choices
      spec.result = nil
      self.interaction.data = nil
    end
    if #selected_cards > 0 and #tos > 0 then
      local to = tos[1]
      local op_spec = {   ---@class OptionBoxParams
        options = {},
        all_options = delayedTrickNames,
      }
      local selected = (spec.result or {}).options or {}
      if #selected_cards == #selected then
        local h = ClientInstance.current_request_handler
        if h then
          h:update("Button", "OK", "")
          h:_finish()
        end
        spec.UIrequest = nil
        return
      end
      op_spec.options = table.filter(delayedTrickNames, function(name)
        return not (table.contains(selected, name) or table.contains(to.sealedSlots, Player.JudgeSlot) or to:hasDelayedTrick(name))
      end)
      refresh_data.optionBox = UI.OptionBox(op_spec)
    end
    spec.UIrequest = nil
    return refresh_data
  end,
})

local spec = { ---@type TrigSkelSpec<fun(self: TriggerSkill, event: PhaseEvent, target: ServerPlayer, player: ServerPlayer, data: PhaseData):any>
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zixi.name) and player.phase == Player.Play and
      not player:isNude() and
      table.find(player.room.alive_players, function(p)
        return not (table.contains(p.sealedSlots, Player.JudgeSlot) or table.every(delayedTrickNames, function(name)
          return p:hasDelayedTrick(name)
        end))
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local _, dat = room:askToUseActiveSkill(player, {
      skill_name = "#zixi_active",
      --prompt = "#zixi-choose",
      cancelable = true,
      extra_data = {
        skillName = zixi.name,
      }
    })
    if dat then
      event:setCostData(self, { tos = dat.targets, cards = dat.cards, extra_data = dat.interaction })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dat = event:getCostData(self)
    local to = dat.tos[1] ---@type ServerPlayer
    local cards = dat.cards ---@type integer[]
    local names = dat.extra_data ---@type string[]
    ---@type CardsMoveInfo[]
    local moves = {}
    for i = 1, #cards, 1 do
      local card = Fk:cloneCard(names[i], nil, nil, zixi.name, cards[i])
      -- 船新奇技淫巧，详见判定阶段代码
      ---@diagnostic disable-next-line
      card.skill = Fk.skills["default_card_skill"]
      ---@class CardsMoveInfo
      local move = {
        from = player,
        to = to,
        toArea = Player.Judge,
        ids = card.subcards,
        moveReason = fk.ReasonJustMove,
        skillName = zixi.name,
        proposer = player,
        virtualEquip = card,
        moveVisible = true,
      }
      table.insert(moves, move)
    end
    room:moveCards(table.unpack(moves))
  end,
}

zixi:addEffect(fk.EventPhaseStart, spec)
zixi:addEffect(fk.EventPhaseEnd, spec)

zixi:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zixi.name) and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      not table.contains(data.card.skillNames, zixi.name) and
      data:isOnlyTarget(data.to) and #data.to:getCardIds("j") > 0 and #data.to:getCardIds("j") < 4
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = zixi.name,
      prompt = "#zixi-invoke"..#data.to:getCardIds("j").."::"..data.to.id..":"..data.card:toLogString(),
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = #data.to:getCardIds("j")
    if x == 1 then
      data.extra_data = data.extra_data or {}
      data.extra_data.zixi = {
        from = player,
        to = data.to,
        subTos = data.use.subTos,
      }
    elseif x == 2 then
      room:drawCards(player, 2, zixi.name)
    elseif x == 3 then
      room:obtainCard(player, data.to:getCardIds("ej"), true, fk.ReasonPrey, player, zixi.name)
      if not data.to.dead then
        room:damage{
          from = player,
          to = data.to,
          damage = 3,
          skillName = zixi.name,
        }
      end
    end
  end,
})

zixi:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if data.extra_data and data.extra_data.zixi and not player.dead then
      local use = table.simpleClone(data.extra_data.zixi)
      if use.from == player then
        local card = Fk:cloneCard(data.card.name, data.card.suit, 0, zixi.name)
        card.color = data.card.color
        if player:prohibitUse(card) then return end
        use.card = card
        if not use.to.dead and not player:isProhibited(use.to, card) then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use = table.simpleClone(data.extra_data.zixi)
    local card = Fk:cloneCard(data.card.name, data.card.suit, 0, zixi.name)
    card.color = data.card.color
    room:useCard{
      from = player,
      tos = {use.to},
      card = card,
      extraUse = true,
      subTos = use.subTos,
    }
  end,
})

return zixi
