local pingyuan = fk.CreateSkill {
  name = "pingyuan",
}

Fk:loadTranslationTable{
  ["pingyuan"] = "平垣",
  [":pingyuan"] = "游戏开始时或回合开始时，若你的装备区没有<a href=':ol__catapult'>【霹雳车】</a>，你可以将之置入装备区（替换原装备）并摸一张牌；"..
  "若你的装备区有【霹雳车】，你可以移动之或视为使用一张【杀】。",

  ["#pingyuan-invoke"] = "平垣：你可以装备【霹雳车】并摸一张牌",
  ["#pingyuan-choice"] = "平垣：你可以移动【霹雳车】或视为使用一张【杀】",
  ["pingyuan_move"] = "移动【霹雳车】",
  ["pingyuan_slash"] = "视为使用一张【杀】",
  ["#pingyuan-choose"] = "平垣：将【霹雳车】移动给一名其他角色",
  ["#pingyuan-slash"] = "平垣：视为使用一张【杀】",

  ["$pingyuan1"] = "发石为锋，夷平敌军土山。",
  ["$pingyuan2"] = "献此奇械，山石壁垒何足惧！",
}

pingyuan:addEffect(fk.GameStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(pingyuan.name) then
      local catapult = table.find(player.room:prepareDeriveCards({{ "ol__catapult", Card.Diamond, 9 }}, pingyuan.name), function (id)
        return player.room:getCardArea(id) == Card.Void
      end)
      return catapult and player:canMoveCardIntoEquip(catapult, true)
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = pingyuan.name,
      prompt = "#pingyuan-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local catapult = table.find(room:prepareDeriveCards({{"ol__catapult", Card.Diamond, 9}}, pingyuan.name), function (id)
      return player.room:getCardArea(id) == Card.Void
    end)
    if catapult then
      room:setCardMark(Fk:getCardById(catapult), MarkEnum.DestructOutEquip, 1)
      room:moveCardIntoEquip(player, catapult, pingyuan.name, true, player)
      if not player.dead then
        player:drawCards(1, pingyuan.name)
      end
    end
  end,
})

pingyuan:addEffect(fk.TurnStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(pingyuan.name) then
      local cards = table.filter(player:getEquipments(Card.SubtypeWeapon), function(id)
        return Fk:getCardById(id).name == "ol__catapult"
      end)
      if #cards > 0 then
        return player:canUse(Fk:cloneCard("slash"), { bypass_times = true }) or
          table.find(cards, function (id)
            return table.find(player.room:getOtherPlayers(player, false), function (p)
              return player:canMoveCardInBoardTo(p, id)
            end) ~= nil
          end)
      else
        local catapult = table.find(player.room:prepareDeriveCards({{"ol__catapult", Card.Diamond, 9}}, pingyuan.name), function (id)
          return player.room:getCardArea(id) == Card.Void
        end)
        return catapult and player:canMoveCardIntoEquip(catapult, true)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getEquipments(Card.SubtypeWeapon), function(id)
      return Fk:getCardById(id).name == "ol__catapult"
    end)
    if #cards > 0 then
      local choices = {}
      if table.find(cards, function (id)
        return table.find(room:getOtherPlayers(player, false), function (p)
          return p:canMoveCardIntoEquip(id)
        end) ~= nil
      end) then
        table.insert(choices, "pingyuan_move")
      end
      if player:canUse(Fk:cloneCard("slash"), { bypass_times = true }) then
        table.insert(choices, "pingyuan_slash")
      end
      table.insert(choices, "Cancel")
      local choice = room:askToChoice(player, {
        skill_name = pingyuan.name,
        choices = choices,
        all_choices = { "pingyuan_move", "pingyuan_slash", "Cancel" }
      })
      if choice ~= "Cancel" then
        if choice == "pingyuan_move" then
          local targets = table.filter(room:getOtherPlayers(player, false), function (p)
            return table.find(cards, function (id)
              return player:canMoveCardInBoardTo(p, id)
            end) ~= nil
          end)
          local to = room:askToChoosePlayers(player, {
            targets = targets,
            min_num = 1,
            max_num = 1,
            prompt = "#pingyuan-choose",
            skill_name = pingyuan.name,
            cancelable = true,
          })
          if #to > 0 then
            event:setCostData(self, { tos = to })
            return true
          end
        else
          local use = room:askToUseVirtualCard(player, {
            name = "slash",
            skill_name = pingyuan.name,
            prompt = "#pingyuan-slash",
            cancelable = true,
            extra_data = {
              bypass_times = true,
              extraUse = true,
            },
            skip = true,
          })
          if use then
            event:setCostData(self, { extra_data = use })
            return true
          end
        end
      end
    elseif room:askToSkillInvoke(player, {
        skill_name = pingyuan.name,
        prompt = "#pingyuan-invoke",
      }) then
      event:setCostData(self, nil)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if (event:getCostData(self) or {}).tos then
      local to = event:getCostData(self).tos[1]
      local cards = table.filter(player:getEquipments(Card.SubtypeWeapon), function(id)
        return Fk:getCardById(id).name == "ol__catapult" and player:canMoveCardInBoardTo(to, id)
      end)
      if #cards == 1 then
        room:moveCardIntoEquip(to, cards, pingyuan.name, false, player)
      else
        local card = room:askToChooseCard(player, {
          target = player,
          flag = { card_data = {{ player.general, cards }} },
          skill_name = pingyuan.name,
        })
        room:moveCardIntoEquip(to, card, pingyuan.name, false, player)
      end
    elseif (event:getCostData(self) or {}).extra_data then
      room:useCard(event:getCostData(self).extra_data)
    else
      local catapult = table.find(room:prepareDeriveCards({{"ol__catapult", Card.Diamond, 9}}, pingyuan.name), function (id)
        return player.room:getCardArea(id) == Card.Void
      end)
      if catapult then
        room:setCardMark(Fk:getCardById(catapult), MarkEnum.DestructOutEquip, 1)
        room:moveCardIntoEquip(player, catapult, pingyuan.name, true, player)
        if not player.dead then
          player:drawCards(1, pingyuan.name)
        end
      end
    end
  end,
})

pingyuan:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = Util.TrueFunc,
})

return pingyuan
