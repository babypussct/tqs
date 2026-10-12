local muzhen = fk.CreateSkill {
  name = "os__muzhen",
  max_branches_use_time = {
    ["os__muzhen1"] = {
      [Player.HistoryPhase] = 1
    },
    ["os__muzhen2"] = {
      [Player.HistoryPhase] = 1
    },
    ["os__muzhen3"] = {
      [Player.HistoryPhase] = 1
    },
  }
}

Fk:loadTranslationTable{
  ["os__muzhen"] = "睦阵",
  [":os__muzhen"] = "出牌阶段各限一次，你可以："..
  "1.交给一名装备区内有牌的其他角色至多两张牌，然后获得其装备区内一张牌；"..
  "2.将一张装备牌置入一名其他角色的装备区，然后获得其一张手牌；"..
  "3.选择任意名其他角色，这些角色手牌数和装备区牌数每有一项与你相同，其便摸一张牌，若你选择的角色均摸了两张牌，你摸选择角色数的牌。",

  ["os__muzhen1"] = "交给至多两张牌，获得一张装备",
  ["os__muzhen2"] = "置入一张装备，获得一张手牌",
  ["os__muzhen3"] = "选择角色，根据牌数其摸牌",
  ["#os__muzhen1"] = "睦阵：交给一名角色至多两张牌，获得其一张装备",
  ["#os__muzhen2"] = "睦阵：将一张装备牌置于一名其他角色装备区，获得其一张手牌",
  ["#os__muzhen3"] = "睦阵：选择任意名其他角色，根据手牌数和装备区牌数与你相同的项数摸牌",

  ["$os__muzhen1"] = "行阵和睦，方可优劣得所。",
  ["$os__muzhen2"] = "识时达务，才可上和下睦。",
}

muzhen:addEffect("active", {
  anim_type = "control",
  prompt = function(self)
    return "#"..self.interaction.data
  end,
  interaction = function(self, player)
    local choices = {}
    for i = 1, 3 do
      if muzhen:withinBranchTimesLimit(player, "os__muzhen"..i, Player.HistoryPhase) then
        table.insert(choices, "os__muzhen"..i)
      end
    end
    return UI.ComboBox { choices = choices }
  end,
  can_use = function(self, player)
    for i = 1, 3 do
      if muzhen:withinBranchTimesLimit(player, "os__muzhen"..i, Player.HistoryPhase) then
        return true
      end
    end
  end,
  card_filter = function(self, player, to_select, selected)
    if self.interaction.data == "os__muzhen1" then
      return #selected < 2
    elseif self.interaction.data == "os__muzhen2" then
      return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip
    elseif self.interaction.data == "os__muzhen3" then
      return false
    end
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected == 0 and to_select ~= player then
      if self.interaction.data == "os__muzhen1" then
        return #selected_cards < 3 and #selected_cards > 0 and #to_select:getCardIds("e") > 0
      elseif self.interaction.data == "os__muzhen2" then
        return #selected_cards == 1 and to_select:canMoveCardIntoEquip(selected_cards[1], false)
      end
    end

    if self.interaction.data == "os__muzhen3" then
      return #selected_cards == 0 and to_select ~= player
    end
  end,
  feasible = function (self, player, selected, selected_cards, card)
    if self.interaction.data == "os__muzhen1" then
      return #selected_cards < 3 and #selected_cards > 0 and #selected == 1
    elseif self.interaction.data == "os__muzhen2" then
      return #selected_cards == 1 and #selected == 1
    elseif self.interaction.data == "os__muzhen3" then
      return #selected_cards == 0 and #selected > 0
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    player:addSkillBranchUseHistory(muzhen.name, self.interaction.data, 1)
    if self.interaction.data == "os__muzhen1" then
      local target = effect.tos[1]
      room:obtainCard(target, effect.cards, false, fk.ReasonGive, player, muzhen.name)
      if not (player.dead or target.dead or #target:getCardIds("e") == 0) then
        local id = room:askToChooseCard(player, {
          target = target,
          flag = "e",
          skill_name = muzhen.name,
        })
        room:obtainCard(player, id, true, fk.ReasonPrey)
      end
    elseif self.interaction.data == "os__muzhen2" then
      local target = effect.tos[1]
      room:moveCardIntoEquip(target, effect.cards[1], muzhen.name, false, player)
      if not (player.dead or target.dead or target:isKongcheng()) then
        local id = room:askToChooseCard(player, {
          target = target,
          flag = "h",
          skill_name = muzhen.name,
        })
        room:obtainCard(player, id, false, fk.ReasonPrey, player, muzhen.name)
      end
    elseif self.interaction.data == "os__muzhen3" then
      local targets = effect.tos
      room:sortByAction(targets)
      local n1, n2 = player:getHandcardNum(), #player:getCardIds("e")
      local dat, yes = {}, true
      for _, p in ipairs(targets) do
        local n = 0
        if p:getHandcardNum() == n1 then
          n = n + 1
        end
        if #p:getCardIds("e") == n2 then
          n = n + 1
        end
        dat[p] = n
        if n ~= 2 then
          yes = false
        end
      end
      for _, p in ipairs(targets) do
        if not p.dead and dat[p] > 0 then
          p:drawCards(dat[p], muzhen.name)
        end
      end
      if not player.dead and yes then
        player:drawCards(#targets, muzhen.name)
      end
    end
  end,
})

return muzhen
