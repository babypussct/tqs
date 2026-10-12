local mojin = fk.CreateSkill {
  name = "mojin",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["mojin"] = "摸金",
  [":mojin"] = "锁定技，游戏开始时，你进行一次<a href='mojin_href'>“摸金”</a>。每当“摸金”成功后，你获得奖励并重新进行一次“摸金”。"..
  "回合开始时，将<a href=':luoyang_shovel'>【洛阳铲】</a>置入你的武器栏。",

  ["@mojin"] = "摸金",

  ["mojin_href"] = "从以下随机三个任务中选择一个，完成后获得一张奖励牌（山河图牌，若为基本牌或锦囊牌则带有随机增益）：<br>"..
  "使用至少三张非基本牌<br>"..
  "本回合因弃置失去至少两张牌<br>"..
  "使用至少两张装备牌<br>"..
  "使用三张基本牌<br>"..
  "使用两张锦囊牌<br>"..
  "造成至少2点伤害<br>"..
  "令一名角色进入濒死状态<br>"..
  "造成属性伤害<br>"..
  "获得一名角色的至少一张牌<br>"..
  "本回合使用【酒】【杀】<br>"..
  "连续使用牌指定一名角色为目标<br>"..
  "本回合获得至少4张牌<br>"..
  "装备区内的牌变为全场最多<br>"..
  "使用一张延时锦囊牌<br>"..
  "一名其他角色失去所有手牌",

  ["mojin_choice1"] = "使用三张非基本牌",
  ["mojin_choice2"] = "一回合弃置两张牌",
  ["mojin_choice3"] = "使用两张装备牌",
  ["mojin_choice4"] = "使用三张基本牌",
  ["mojin_choice5"] = "使用两张锦囊牌",
  ["mojin_choice6"] = "造成至少2点伤害",
  ["mojin_choice7"] = "令角色进入濒死状态",
  ["mojin_choice8"] = "造成属性伤害",
  ["mojin_choice9"] = "获得角色一张牌",
  ["mojin_choice10"] = "使用酒杀",
  ["mojin_choice11"] = "连续使用牌指定一名目标",
  ["mojin_choice12"] = "一回合获得四张牌",
  ["mojin_choice13"] = "装备变为全场最多",
  ["mojin_choice14"] = "使用延时锦囊牌",
  ["mojin_choice15"] = "其他角色失去所有手牌",

  ["@@mojin_recover"] = "回复+1",
  ["@@mojin_disresponsive"] = "不可响应",

  ["$mojin1"] = "此山是我开，此宝是我财，今日从此过，带着兄弟来，哈哈哈哈！",
  ["$mojin2"] = "兄弟此来，只为钱财不伤人。",
}

local rewards = {
  matchless_halberd = { Card.Diamond, 12 },
  ghost_dragon_blade = { Card.Spade, 5 },
  blood_sword = { Card.Spade, 6 },
  iron_double_halberd = { Card.Diamond, 13 },
  baipi_blade = { Card.Spade, 2 },
  xingtian_axe = { Card.Diamond, 5 },
  crow_bow = { Card.Heart, 5 },
  fire_string = { Card.Diamond, 1 },
  luanfeng_double_swords = { Card.Spade, 2 },
  lion_belt = { Card.Spade, 2 },
  red_robe = { Card.Club, 1 },
  sage_cloak = { Card.Spade, 9 },
  mystical_diagram = { Card.Spade, 2 },
  golden_coronet = { Card.Diamond, 1 },
  illusory_coronet = { Card.Club, 4 },
  eq_sanshou = { Card.Diamond, 12 },
  three_strategies = { Card.Spade, 5 },
  bone_mirror = { Card.Diamond, 1 },
  lightning_cutter = { Card.Club, 1 },
  douji_kiriyasu = { Card.Spade, 2 },
  muramasa_blade = { Card.Spade, 6 },
  shuriken = { Card.Heart, 5 },
  hook_loop = { Card.Spade, 2 },
  mukashi_gusoku = { Card.Club, 2 },
  hasshaku_keikogyoku = { Card.Heart, 5 },
  omamori = { Card.Diamond, 13 },
  black_chain = { Card.Diamond, 12 },
  five_elements_fan = { Card.Diamond, 1 },
  dark_armor = { Card.Club, 2 },
  wonder_map = { Card.Club, 12 },
  taigong_tactics = { Card.Spade, 1 },
  seven_stars_sword = { Card.Spade, 6 },
}

mojin.rewards = rewards

local function mojin_choice(player)
  local room = player.room
  local choices = {}
  for i = 1, 15 do
    table.insert(choices, "mojin_choice"..i)
  end
  local choice = room:askToChoice(player, {
    choices = room:tableRandomPick(choices, 3),
    skill_name = mojin.name,
  })
  room:setPlayerMark(player, "@mojin", choice)
end

local function mojin_reward(player)
  local room = player.room
  local card, names, name = nil, {}, ""
  if math.random() < 0.5 then
    for n, _ in pairs(rewards) do
      table.insert(names, n)
    end
    name = room:tableRandomPick(names)
    card = room:printCard(name, rewards[name][1], rewards[name][2])
  else
    for _, c in ipairs(Fk.cards) do
      if (c.package.name == "standard" or c.package.name == "maneuvering") and
        c.type == Card.TypeTrick then
        table.insertIfNeed(names, c.name)
      end
    end
    table.removeOne(names, "lighting")
    table.insertTable(names, { "jink", "peach", "thunder__slash", "fire__slash", "ice__slash" })
    name = room:tableRandomPick(names)
    card = room:printCard(room:tableRandomPick(names), math.random(1, 4), math.random(1, 13))
    room:setCardMark(card, MarkEnum.DestructIntoDiscard, 1)
    if table.contains({"peach", "analeptic"}, name) then
      room:setCardMark(card, "@@mojin_recover", 1)
    else
      room:setCardMark(card, "@@mojin_disresponsive", 1)
    end
  end
  room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, mojin.name, nil, false, player)
end

mojin:addEffect(fk.GameStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(mojin.name)
  end,
  on_use = function(self, event, target, player, data)
    mojin_choice(player)
  end,
})

mojin:addEffect(fk.TurnStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(mojin.name) then
      local card = table.find(player.room:prepareDeriveCards({{ "luoyang_shovel", Card.Spade, 13 }}, mojin.name), function (id)
        return player.room:getCardArea(id) == Card.Void
      end)
      return card and player:canMoveCardIntoEquip(card, true)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = table.find(room:prepareDeriveCards({{ "luoyang_shovel", Card.Spade, 13 }}, mojin.name), function (id)
      return room:getCardArea(id) == Card.Void
    end)
    if card then
      room:setCardMark(Fk:getCardById(card), MarkEnum.DestructOutMyEquip, 1)
      room:moveCardIntoEquip(player, card, mojin.name, true, player)
    end
  end,
})

mojin:addEffect(fk.CardUseFinished, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:getMark("@mojin") ~= 0 then
      local choice = player:getMark("@mojin")
      if choice == "mojin_choice1" then
        return data.card.type ~= Card.TypeBasic
      elseif choice == "mojin_choice3" then
        return data.card.type == Card.TypeEquip
      elseif choice == "mojin_choice4" then
        return data.card.type == Card.TypeBasic
      elseif choice == "mojin_choice5" then
        return data.card.type == Card.TypeTrick
      elseif choice == "mojin_choice10" then
        return data.card.trueName == "slash" and (data.extra_data or {}).drankBuff
      elseif choice == "mojin_choice11" then
        return true
      elseif choice == "mojin_choice14" then
        return data.card.sub_type == Card.SubtypeDelayedTrick
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = player:getMark("@mojin")
    if choice == "mojin_choice1" then
      room:addPlayerMark(player, "mojin_choice1_count", 1)
      if player:getMark("mojin_choice1_count") > 2 then
        room:setPlayerMark(player, "mojin_choice1_count", 0)
      else
        return
      end
    elseif choice == "mojin_choice3" then
      room:addPlayerMark(player, "mojin_choice3_count", 1)
      if player:getMark("mojin_choice3_count") > 1 then
        room:setPlayerMark(player, "mojin_choice3_count", 0)
      else
        return
      end
    elseif choice == "mojin_choice4" then
      room:addPlayerMark(player, "mojin_choice4_count", 1)
      if player:getMark("mojin_choice4_count") > 2 then
        room:setPlayerMark(player, "mojin_choice4_count", 0)
      else
        return
      end
    elseif choice == "mojin_choice5" then
      room:addPlayerMark(player, "mojin_choice5_count", 1)
      if player:getMark("mojin_choice5_count") > 1 then
        room:setPlayerMark(player, "mojin_choice5_count", 0)
      else
        return
      end
    elseif choice == "mojin_choice11" then
      if #data.tos == 0 then
        room:setPlayerMark(player, "mojin_choice11_count", 0)
        return
      elseif player:getMark("mojin_choice11_count") == 0 or
        not table.hasIntersection(data.tos, player:getMark("mojin_choice11_count")) then
        room:setPlayerMark(player, "mojin_choice11_count", data.tos)
        return
      end
      room:setPlayerMark(player, "mojin_choice11_count", 0)
    end

    mojin_reward(player)
    if player.dead then return end
    mojin_choice(player)
  end,
})

mojin:addEffect(fk.Damage, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:getMark("@mojin") ~= 0 then
      local choice = player:getMark("@mojin")
      if choice == "mojin_choice6" then
        return true
      elseif choice == "mojin_choice8" then
        return data.damageType ~= fk.NormalDamage
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = player:getMark("@mojin")
    if choice == "mojin_choice6" then
      room:addPlayerMark(player, "mojin_choice6_count", data.damage)
      if player:getMark("mojin_choice6_count") > 1 then
        room:setPlayerMark(player, "mojin_choice6_count", 0)
      else
        return
      end
    end

    mojin_reward(player)
    if player.dead then return end
    mojin_choice(player)
  end,
})

mojin:addEffect(fk.EnterDying, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return data.damage and data.damage.from == player and
      player:getMark("@mojin") == "mojin_choice7"
  end,
  on_use = function(self, event, target, player, data)
    mojin_reward(player)
    if player.dead then return end
    mojin_choice(player)
  end,
})

mojin:addEffect(fk.AfterCardsMove, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if player:getMark("@mojin") ~= 0 then
      local choice = player:getMark("@mojin")
      for _, move in ipairs(data) do
        if choice == "mojin_choice2" and move.from == player and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
        if choice == "mojin_choice15" and move.from and move.from ~= player and move.from:isKongcheng() then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
        if move.to == player then
          if choice == "mojin_choice9" and move.from and move.moveReason == fk.ReasonPrey then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                return true
              end
            end
          elseif choice == "mojin_choice12" and move.toArea == Card.PlayerHand then
            return true
          elseif choice == "mojin_choice13" and move.toArea == Card.PlayerEquip then
            return table.every(player.room.alive_players, function (p)
              return #p:getCardIds("e") <= #player:getCardIds("e")
            end)
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = player:getMark("@mojin")
    if choice == "mojin_choice2" then
      for _, move in ipairs(data) do
        if move.from == player and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              room:addPlayerMark(player, "mojin_choice2_count-turn", 1)
            end
          end
        end
      end
      if player:getMark("mojin_choice2_count-turn") > 1 then
        room:setPlayerMark(player, "mojin_choice2_count-turn", 0)
      else
        return
      end
    elseif choice == "mojin_choice12" then
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Card.PlayerHand then
          room:addPlayerMark(player, "mojin_choice12_count-turn", #move.moveInfo)
        end
      end
      if player:getMark("mojin_choice12_count-turn") > 3 then
        room:setPlayerMark(player, "mojin_choice12_count-turn", 0)
      else
        return
      end
    end

    mojin_reward(player)
    if player.dead then return end
    mojin_choice(player)
  end,
})

mojin:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and data.card:getMark("@@mojin_disresponsive") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.disresponsiveList = table.simpleClone(player.room.players)
  end,
})

mojin:addEffect(fk.PreHpRecover, {
  can_refresh = function (self, event, target, player, data)
    return target == player and data.card and data.card:getMark("@@mojin_recover") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data:changeRecover(1)
  end,
})

mojin:addLoseEffect(function (self, player, is_death)
  local room = player.room
  room:setPlayerMark(player, "@mojin", 0)
  room:setPlayerMark(player, "mojin_choice2_count-turn", 0)
  room:setPlayerMark(player, "mojin_choice12_count-turn", 0)
  for _, i in ipairs({1, 3, 4, 5, 11}) do
    room:setPlayerMark(player, "mojin_choice"..i.."_count", 0)
  end
end)

return mojin
