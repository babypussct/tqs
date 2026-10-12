local hegRule = fk.CreateSkill{
  name = "heg_rule",
}

local H = require "packages.hegemony.util"

hegRule:addEffect(fk.GameStart, {
  priority = 0,
  can_trigger = function(self, event, target, player, data)
    return player.seat == 1
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room

    for _, p in ipairs(room.players) do
      p:setMark("@seat", 0)
      p:doNotify("SetPlayerMark", { p.id, "@seat", 0})
    end

    local cards = table.filter(room.void, function (id)
      return Fk:getCardById(id).name == "nine_tripod_cauldrons"
    end)
    if #cards > 0 then
      room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonJustMove, hegRule.name, nil, true)
    end

    if room:getSettings("revealAllOnStart") then
      for _, p in ipairs(room.alive_players) do
        if p:isAlive() then
          p:revealGenerals()
        end
      end
    end
  end,
})

hegRule:addEffect(fk.BeforeTurnStart, {
  priority = 0,
  can_trigger = function(self, event, target, player, data)
    return target == player
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    -- 鏖战
    if #room.alive_players < (#room.players > 6 and 5 or 4) and not room:getTag("BattleRoyalMode") then
      local ret = true
      for _, v in pairs(H.getKingdomPlayersNum(room)) do
        if v and v > 1 then
          ret = false
          break
        end
      end
      if ret then
        H.enterBattleRoyalMode(room)
      end
    end
  end,
})
hegRule:addEffect(fk.AfterDrawPileShuffle, {
  priority = 0,
  can_trigger = function(self, event, target, player, data)
    return not player.room:getTag("BattleRoyalMode") and player.room:getSettings("enterBattleRoyalOnFirstShuffle")
  end,
  on_trigger = function(self, event, target, player, data)
    H.enterBattleRoyalMode(player.room)
  end,
})
hegRule:addEffect(fk.TurnStart, {
  priority = 100,
  can_trigger = function(self, event, target, player, data)
    return target == player
  end,
  on_trigger = function(self, event, target, player, data)
    H.askToRevealGenerals(player, {
      skill_name = hegRule.name,
      lord_convert = true,
    })
  end
})
hegRule:addEffect(fk.GameOverJudge, {
  priority = 0,
  can_trigger = function(self, event, target, player, data)
    return target == player
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    player:revealGeneral(false)
    player:revealGeneral(true)
    if player.kingdom == "wild" then
      H.wildChooseKingdom(player, player.general)
    end
    local winner = Fk.game_modes[room:getSettings('gameMode')]:getWinner(player)
    if winner ~= "" then
      for _, ps in ipairs(room.alive_players) do
        -- 先检测并询问主将是不是野人
        if ps.general == "anjiang" then
          -- 是野人则强制亮出来
          if ps:getMark("__heg_wild") == 1 then
            room:setPlayerMark(ps, "_wild_final_end", 1)
            ps:revealGeneral(false)
          end
        end
      end
      -- 强制亮完野人后检测场上有没有野人
      if table.find(room.alive_players, function(p) return p:getMark("__heg_wild") == 1 end) then
        --有野人则依次询问拉拢
        for _, p in ipairs(room.alive_players) do
          if p:getMark("__heg_wild") == 1 then
            H.wildChooseKingdom(p, p.general)
            H.AskForBuildCountry(p, p.general, false)
            room:setPlayerMark(p, "_wild_gained", 1)
          end
        end
      end
      -- 然后判断场上所有人势力是否相同
      local _kingdom2 = {}
      for _, p in ipairs(room.alive_players) do
        if not table.contains(_kingdom2, p.kingdom) and p.kingdom ~= "unknown" then
          table.insert(_kingdom2, p.kingdom)
        end
      end
      if #_kingdom2 == 1 then
        -- 若所有人势力相同则全部亮将
        for _, p in ipairs(room.players) do
          if p:isAlive() then
            if p.general == "anjiang" then p:revealGeneral(false) end
            if p.deputyGeneral == "anjiang" then p:revealGeneral(true) end
          end
          p.role = H.getKingdom(p)
          room:broadcastProperty(p, "role")
        end
        room:gameOver(winner)
        return true
      end
    end
  end
})
hegRule:addEffect(fk.GeneralRevealed, {
  priority = 0,
  can_trigger = function(self, event, target, player, data)
    return target == player
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    --本轮明置过武将牌
    room:setPlayerMark(player, "GeneralRevealed-round", 1)
    for _, general_name in pairs(data) do
      if room:getTag("TheFirstToShowRewarded") == player.id and player:getMark("_vanguard_gained") == 0 then
        room:setPlayerMark(player, "_vanguard_gained", 1)
        H.addHegMark(player, "vanguard")
      end
      if player:getMark("hasShownMainGeneral") == 1 and Fk.generals[general_name].kingdom == "wild" and player:getMark("_wild_gained") == 0 then
        room:setPlayerMark(player, "_wild_gained", 1)
        H.addHegMark(player, "wild")
      end
      if player.general == "anjiang" or player.deputyGeneral == "anjiang" then return false end
      if player:getMark("HalfMaxHpLeft") > 0 then
        room:setPlayerMark(player, "HalfMaxHpLeft", 0)
        H.addHegMark(player, "yinyangfish")
      end
      if player:getMark("CompanionEffect") > 0 then
        room:setPlayerMark(player, "CompanionEffect", 0)
        H.addHegMark(player, "companion")
      end
    end
  end
})
hegRule:addEffect(fk.EventPhaseStart, {
  priority = 0,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.phase == Player.Play
  end,
  on_trigger = function(self, event, target, player, data)
    player:addFakeSkill("alliance&")
  end
})
hegRule:addEffect(fk.EventPhaseEnd, {
  priority = 0,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.phase == Player.Play
  end,
  on_trigger = function(self, event, target, player, data)
    player:loseFakeSkill("alliance&")
  end
})

--- 设置仅自己可见势力（非野心家势力）
---@param room Room
---@param player ServerPlayer
local setPrivateRole = function (room, player, role)
  room:setPlayerProperty(player, "role_shown", true)
  room:setPlayerProperty(player, "role", "hidden") -- 2行合在一起不显示身份
  player.role = role
  room:notifyProperty(player, player, "role")
end

hegRule:addEffect(fk.GeneralShown, {
  priority = 0,
  can_trigger = function(self, event, target, player, data)
    return target == player
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    if not room:getTag("TheFirstToShowRewarded") then
      room:setTag("TheFirstToShowRewarded", player.id)
    end
    local general_name = data["m"] or data["d"]  ---@cast general_name string
    -- 君主拉回野人
    if general_name and Fk.generals[general_name].trueName:startsWith("lord") then
      local kingdom = player:getMark("__heg_kingdom")
      for _, p in ipairs(room.players) do
        if p:getMark("__heg_kingdom") == kingdom and p.kingdom == "wild" and p:getMark("__heg_wild") == 0 then
          room:setPlayerProperty(p, "kingdom", kingdom)
          room:setPlayerProperty(p, "role_shown", false)
          setPrivateRole(room, p, kingdom)
        end
      end
    end
    if player.kingdom == "wild" and not player.dead and player:getMark("_wild_gained") == 0 then
      H.wildChooseKingdom(player, general_name)
      -- 野人亮出来的时候询问拉拢
      local choices = {"Cancel"}
      if player:getMark("__heg_wild") == 1 and player:getMark("_wild_final_end") == 0 then
        table.insert(choices, "heg_build_country:::" .. player.role)
      end
      -- if room:askForChoice(player, choices, hegRule.name) ~= "Cancel" then
      --   H.AskForBuildCountry(player, general_name, true)
      --   room:setPlayerMark(player, "_wild_gained", 1)
      -- end
    elseif player:getMark("__heg_join_wild") == 0 and player:getMark("__heg_construct_wild") == 0 then
      if player:getMark("__heg_wild") == 1 then
        if player.general == "anjiang" then
          setPrivateRole(room, player, player:getMark("__heg_kingdom")) --主将野人暂时身份
        end
      else
        setPrivateRole(room, player, player.kingdom)
      end
    end

    for _, v in pairs(H.getKingdomPlayersNum(room)) do
      if v == #room.alive_players then
        local winner = Fk.game_modes[room:getSettings('gameMode')]:getWinner(player)
        for _, p in ipairs(room.alive_players) do
          -- 先检测并询问主将是不是野人
          if p.general == "anjiang" then
            -- 是野人则强制亮出来
            if p:getMark("__heg_wild") == 1 then
              room:setPlayerMark(p, "_wild_final_end", 1)
              p:revealGeneral(false)
            end
          end
        end
        -- 强制亮完野人后检测场上有没有野人
        if table.find(room.alive_players, function(p) return p:getMark("__heg_wild") == 1 end) then
          --有野人则依次询问拉拢
          for _, p in ipairs(room.alive_players) do
            if p:getMark("__heg_wild") == 1 then
              H.wildChooseKingdom(p, p.general)
              H.AskForBuildCountry(p, p.general, false)
              room:setPlayerMark(p, "_wild_gained", 1)
            end
          end
        end
        -- 然后判断场上所有人势力是否相同
        if table.every(room.alive_players, function(p) return H.compareKingdomWith(p, player) end) then
          -- 若所有人势力相同则全部亮将
          for _, p in ipairs(room.players) do
            if p:isAlive() then
              if p.general == "anjiang" then p:revealGeneral(false) end
              if p.deputyGeneral == "anjiang" then p:revealGeneral(true) end
            end
            p.role = H.getKingdom(p)
            room:broadcastProperty(p, "role")
          end
          room:gameOver(winner)
          return true
        end
      else
        break
      end
    end
    if player:getMark("hasShownMainGeneral") == 0 and data["m"] then -- 首次亮主将
      room:setPlayerMark(player, "hasShownMainGeneral", 1)
    end
  end
})

--奇珍
hegRule:addEffect(fk.Damaged, {
  priority = 0,
  can_trigger = function(self, event, target, player, data)
    return target == player and
      data.card and data.card.trueName == "slash" and
      table.find(player:getCardIds("e"), function (id)
        local card = Fk:getCardById(id)
        return card.type == Card.TypeEquip and card.package.name == "nine_variations"
      end) and
    data.from and not data.from.dead
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getCardIds("e"), function (id)
      local card = Fk:getCardById(id)
      return card.type == Card.TypeEquip and card.package.name == "nine_variations"
    end)
    if #cards > 0 and
      room:askToSkillInvoke(data.from, {
        skill_name = "rare_treasure",
        prompt = "#rare_treasure-prey::"..player.id,
      }) then
      local id = room:askToChooseCard(data.from, {
        target = player,
        flag = { card_data = { { "equip", cards } } },
        skill_name = "rare_treasure",
      })
      room:moveCardTo(id, Card.PlayerHand, data.from, fk.ReasonPrey, "rare_treasure", nil, true, data.from)
    end
  end,
})

hegRule:addEffect(fk.AfterDrawPileShuffle, {
  priority = 0,
  can_trigger = function (self, event, target, player, data)
    return player.seat == 1
  end,
  on_trigger = function (self, event, target, player, data)
    local room = player.room
    local cards = table.filter(room.draw_pile, function (id)
      return Fk:getCardById(id).name == "nine_tripod_cauldrons"
    end)
    if #cards > 0 then
      room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonJustMove, hegRule.name, nil, true)
    end
  end,
})

return hegRule
