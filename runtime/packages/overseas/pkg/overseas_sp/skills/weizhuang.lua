local os__weizhuang = fk.CreateSkill {
  name = "os__weizhuang",
  add_skills = { "os__caiqiu" },
}

---@type mobileUtil
local mobileUtil = require "packages.mobile.mobile_util"

Fk:loadTranslationTable{
  ["os__weizhuang"] = "褽装",
  [":os__weizhuang"] = "有<a href='#CardDisplayedDesc'>明置牌</a>的角色的结束阶段，你可以令以下一项数值-1，发动一次〖裁裘〗：" ..
  "1.摸牌阶段摸牌数；2.使用【杀】的次数上限；3.手牌上限；4.体力值。每局游戏限X次，每当有X张牌被明置后，你令以上一项数值+1（X为游戏人数+1）。",

  ["os__weizhuang_draw_diff"] = "摸牌阶段摸牌数-1",
  ["os__weizhuang_slash_diff"] = "使用【杀】的次数上限-1",
  ["os__weizhuang_hand_diff"] = "手牌上限-1",
  ["os__weizhuang_hp_diff"] = "失去1点体力",
  ["os__weizhuang_draw"] = "摸牌阶段摸牌数+1",
  ["os__weizhuang_slash"] = "使用【杀】的次数上限+1",
  ["os__weizhuang_hand"] = "手牌上限+1",
  ["os__weizhuang_hp"] = "回复1点体力",
  ["@os__weizhuang_status-noclear"] = "褽装",
  ["os__weizhuang_record-noclear"] = "褽装",

  ["$os__weizhuang1"] = "嘉宴在即，自要盛装以待。",
  ["$os__weizhuang2"] = "当择一华服，以尽显妾身之美。",
  ["$os__weizhuang3"] = "出门难得，唯以自妆为乐。",
  ["$os__weizhuang4"] = "衣饰岂可复着？当更新衣以庆。",
}

os__weizhuang:addEffect(fk.EventPhaseStart, {
  audio_index = { 1, 2 },
  can_trigger = function(self, event, target, player, data)
    return
      target.phase == Player.Finish and
      player:hasSkill(os__weizhuang.name) and
      mobileUtil.hasCardsDisplayed(player.room, target)
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {
      "os__weizhuang_draw_diff",
      "os__weizhuang_slash_diff",
      "os__weizhuang_hand_diff",
      "os__weizhuang_hp_diff",
      "Cancel"
    }
    local os__weizhuangMark = player:getMark("@os__weizhuang_status-noclear")
    os__weizhuangMark = os__weizhuangMark == 0 and { 0, 0, 0 } or os__weizhuangMark
    if 2 + os__weizhuangMark[1] < 1 then
      table.removeOne(choices, "os__weizhuang_draw_diff")
    end
    local slash = Fk:cloneCard("slash")
    if slash.skill:getMaxUseTime(player, Player.HistoryPhase, slash) < 1 then
      table.removeOne(choices, "os__weizhuang_slash_diff")
    end
    if player:getMaxCards() < 1 then
      table.removeOne(choices, "os__weizhuang_hand_diff")
    end

    local choice = player.room:askToChoice(
      player,
      {
        choices = choices,
        skill_name = os__weizhuang.name,
      }
    )

    if choice ~= "Cancel" then
      event:setCostData(self, { choice = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local os__weizhuangMark = player:getMark("@os__weizhuang_status-noclear")
    os__weizhuangMark = os__weizhuangMark == 0 and { 0, 0, 0 } or os__weizhuangMark
    local choice = event:getCostData(self).choice

    if choice == "os__weizhuang_draw_diff" then
      os__weizhuangMark[1] = os__weizhuangMark[1] - 1
    elseif choice == "os__weizhuang_slash_diff" then
      os__weizhuangMark[2] = os__weizhuangMark[2] - 1
    elseif choice == "os__weizhuang_hand_diff" then
      os__weizhuangMark[3] = os__weizhuangMark[3] - 1
    else
      room:loseHp(player, 1, os__weizhuang.name)
    end

    if player:isAlive() then
      room:setPlayerMark(player, "@os__weizhuang_status-noclear", os__weizhuangMark)

      if not room:hasSkill("os__caiqiu") then
        room:addSkill("os__caiqiu")
      end
      Fk.skills["os__caiqiu"]:trigger(event, player, player)
    end
  end,
})

local os__weizhuangBuffOnUse = function(self, event, target, player, data)
  local room = player.room
  local choices = { "os__weizhuang_draw", "os__weizhuang_slash", "os__weizhuang_hand", "os__weizhuang_hp" }
  local os__weizhuangMark = player:getMark("@os__weizhuang_status-noclear")
  os__weizhuangMark = os__weizhuangMark == 0 and { 0, 0, 0 } or os__weizhuangMark

  for _ = 1, player:getMark("os__weizhuang_record-noclear") // (#room.players + 1) do
    local choice = room:askToChoice(
    player,
      {
        choices = choices,
        skill_name = os__weizhuang.name,
      }
    )

    if choice == "os__weizhuang_draw" then
      os__weizhuangMark[1] = os__weizhuangMark[1] + 1
    elseif choice == "os__weizhuang_slash" then
      os__weizhuangMark[2] = os__weizhuangMark[2] + 1
    elseif choice == "os__weizhuang_hand" then
      os__weizhuangMark[3] = os__weizhuangMark[3] + 1
    elseif player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = os__weizhuang.name,
      }
    end

    if player:isAlive() then
      room:removePlayerMark(player, "os__weizhuang_record-noclear", #room.players + 1)
      room:setPlayerMark(player, "@os__weizhuang_status-noclear", os__weizhuangMark)
    end
  end
end

os__weizhuang:addEffect(mobileUtil.CardDisplayed, {
  audio_index = { 3, 4 },
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(os__weizhuang.name) and
      player:getMark("os__weizhuang_record-noclear") >= #player.room.players + 1 and
      player:usedEffectTimes(self.name, Player.HistoryGame) +
        player:usedEffectTimes("#os__weizhuang_3_trig", Player.HistoryGame) <
        #player.room.players + 1
  end,
  on_cost = Util.TrueFunc,
  on_use = os__weizhuangBuffOnUse,

  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(os__weizhuang.name)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "os__weizhuang_record-noclear", #data.cards)
  end,
})

os__weizhuang:addEffect(fk.AfterCardsMove, {
  audio_index = { 3, 4 },
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(os__weizhuang.name) and
      player:getMark("os__weizhuang_record-noclear") >= #player.room.players + 1 and
      player:usedEffectTimes(self.name, Player.HistoryGame) +
        player:usedEffectTimes("#os__weizhuang_2_trig", Player.HistoryGame) <
        #player.room.players + 1
  end,
  on_cost = Util.TrueFunc,
  on_use = os__weizhuangBuffOnUse,

  can_refresh = function(self, event, target, player, data)
    return
      player:hasSkill(os__weizhuang.name) and
      table.find(data, function(move)
        if table.contains({ Card.PlayerEquip, Card.PlayerJudge }, move.toArea) then
          return table.find(move.moveInfo, function(info)
            return (info.extra_data or {}).hiddenBeforeMove
          end) ~= nil
        end
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    local toDisplay = 0
    local room = player.room
    table.forEach(data, function(move)
      if table.contains({ Card.PlayerEquip, Card.PlayerJudge }, move.toArea) then
        table.forEach(move.moveInfo, function(info)
          if (info.extra_data or {}).hiddenBeforeMove then
            toDisplay = toDisplay + 1
          end
        end)
      end
    end)

    if toDisplay > 0 then
      room:addPlayerMark(player, "os__weizhuang_record-noclear", toDisplay)
    end
  end,
})

os__weizhuang:addEffect(fk.BeforeCardsMove, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return
      player == player.room.players[1] and
      table.find(data, function(move)
        if table.contains({ Card.PlayerEquip, Card.PlayerJudge, Card.Processing }, move.toArea) then
          return table.find(move.moveInfo, function(info)
            return
              (
                info.fromArea == Card.Processing and
                Fk:getCardById(info.cardId):getMark("mobile_processing_invisible-inarea") ~= 0
              ) or
              (
                info.fromArea == Card.PlayerHand and not mobileUtil.cardIsVisible(player.room, info.cardId)
              )
          end) ~= nil
        end
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    table.forEach(data, function(move)
      if table.contains({ Card.PlayerEquip, Card.PlayerJudge, Card.Processing }, move.toArea) then
        table.forEach(move.moveInfo, function(info)
          if
            info.fromArea == Card.Processing and
            Fk:getCardById(info.cardId):getMark("mobile_processing_invisible-inarea") ~= 0
          then
            info.extra_data = info.extra_data or {}
            info.extra_data.hiddenBeforeMove = true
          elseif info.fromArea == Card.PlayerHand and not mobileUtil.cardIsVisible(player.room, info.cardId) then
            if move.toArea == Card.Processing then
              player.room:setCardMark(Fk:getCardById(info.cardId), "mobile_processing_invisible-inarea", { Card.Processing })
            else
              info.extra_data = info.extra_data or {}
              info.extra_data.hiddenBeforeMove = true
            end
          end
        end)
      end
    end)
  end,
})

os__weizhuang:addEffect(fk.DrawNCards, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getTableMark("@os__weizhuang_status-noclear")[1]
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + player:getTableMark("@os__weizhuang_status-noclear")[1]
  end,
})

os__weizhuang:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope, card, to)
    local os__weizhuangMark = player:getTableMark("@os__weizhuang_status-noclear")
    if
      card and
      card.trueName == "slash" and
      os__weizhuangMark[2] and
      scope == Player.HistoryPhase then
      return os__weizhuangMark[2]
    end
  end,
})

os__weizhuang:addEffect("maxcards", {
  correct_func = function(self, player)
    local os__weizhuangMark = player:getTableMark("@os__weizhuang_status-noclear")
    if os__weizhuangMark[3] then
      return os__weizhuangMark[3]
    end
  end,
})

os__weizhuang:addLoseEffect(function(self, player, isDeath)
  if not isDeath then
    player.room:setPlayerMark(player, "os__weizhuang_record-noclear", 0)
  end
end)

return os__weizhuang
