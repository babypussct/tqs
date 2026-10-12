local weizhuang = fk.CreateSkill {
  name = "weizhuang",
  add_skills = { "caiqiu" },
}

---@type mobileUtil
local mobileUtil = require "packages.mobile.mobile_util"

Fk:loadTranslationTable{
  ["weizhuang"] = "褽装",
  [":weizhuang"] = "有<a href='#CardDisplayedDesc'>明置牌</a>的角色的结束阶段开始时，你可以令以下一项数值-1，发动一次“<a href=':caiqiu'>裁裘</a>”：" ..
  "1.摸牌阶段摸牌数；2.使用【杀】的次数上限；3.手牌上限；4.体力值。每局游戏限X次，每当有X张牌被明置后，你令以上一项数值+1（X为游戏人数+1）。",

  ["weizhuang_draw_diff"] = "摸牌阶段摸牌数-1",
  ["weizhuang_slash_diff"] = "使用【杀】的次数上限-1",
  ["weizhuang_hand_diff"] = "手牌上限-1",
  ["weizhuang_hp_diff"] = "失去1点体力",
  ["weizhuang_draw"] = "摸牌阶段摸牌数+1",
  ["weizhuang_slash"] = "使用【杀】的次数上限+1",
  ["weizhuang_hand"] = "手牌上限+1",
  ["weizhuang_hp"] = "回复1点体力",
  ["@weizhuang_status-noclear"] = "褽装",
  ["weizhuang_record-noclear"] = "褽装",

  ["$weizhuang1"] = "嘉宴在即，自要盛装以待。",
  ["$weizhuang2"] = "当择一华服，以尽显妾身之美。",
  ["$weizhuang3"] = "出门难得，唯以自妆为乐。",
  ["$weizhuang4"] = "衣饰岂可复着？当更新衣以庆。",
}

weizhuang:addEffect(fk.EventPhaseStart, {
  audio_index = { 1, 2 },
  can_trigger = function(self, event, target, player, data)
    return
      target.phase == Player.Finish and
      player:hasSkill(weizhuang.name) and
      mobileUtil.hasCardsDisplayed(player.room, target)
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {
      "weizhuang_draw_diff",
      "weizhuang_slash_diff",
      "weizhuang_hand_diff",
      "weizhuang_hp_diff",
      "Cancel"
    }
    local weizhuangMark = player:getMark("@weizhuang_status-noclear")
    weizhuangMark = weizhuangMark == 0 and { 0, 0, 0 } or weizhuangMark
    if 2 + weizhuangMark[1] < 1 then
      table.removeOne(choices, "weizhuang_draw_diff")
    end
    local slash = Fk:cloneCard("slash")
    if slash.skill:getMaxUseTime(player, Player.HistoryPhase, slash) < 1 then
      table.removeOne(choices, "weizhuang_slash_diff")
    end
    if player:getMaxCards() < 1 then
      table.removeOne(choices, "weizhuang_hand_diff")
    end

    local choice = player.room:askToChoice(
      player,
      {
        choices = choices,
        skill_name = weizhuang.name,
      }
    )

    if choice ~= "Cancel" then
      event:setCostData(self, { choice = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local weizhuangMark = player:getMark("@weizhuang_status-noclear")
    weizhuangMark = weizhuangMark == 0 and { 0, 0, 0 } or weizhuangMark
    local choice = event:getCostData(self).choice

    if choice == "weizhuang_draw_diff" then
      weizhuangMark[1] = weizhuangMark[1] - 1
    elseif choice == "weizhuang_slash_diff" then
      weizhuangMark[2] = weizhuangMark[2] - 1
    elseif choice == "weizhuang_hand_diff" then
      weizhuangMark[3] = weizhuangMark[3] - 1
    else
      room:loseHp(player, 1, weizhuang.name)
    end

    if player:isAlive() then
      room:setPlayerMark(player, "@weizhuang_status-noclear", weizhuangMark)

      if not room:hasSkill("caiqiu") then
        room:addSkill("caiqiu")
      end
      Fk.skills["caiqiu"]:trigger(event, player, player)
    end
  end,
})

local weizhuangBuffOnUse = function(self, event, target, player, data)
  local room = player.room
  local choices = { "weizhuang_draw", "weizhuang_slash", "weizhuang_hand", "weizhuang_hp" }
  local weizhuangMark = player:getMark("@weizhuang_status-noclear")
  weizhuangMark = weizhuangMark == 0 and { 0, 0, 0 } or weizhuangMark

  for _ = 1, player:getMark("weizhuang_record-noclear") // (#room.players + 1) do
    local choice = room:askToChoice(
    player,
      {
        choices = choices,
        skill_name = weizhuang.name,
      }
    )

    if choice == "weizhuang_draw" then
      weizhuangMark[1] = weizhuangMark[1] + 1
    elseif choice == "weizhuang_slash" then
      weizhuangMark[2] = weizhuangMark[2] + 1
    elseif choice == "weizhuang_hand" then
      weizhuangMark[3] = weizhuangMark[3] + 1
    elseif player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = weizhuang.name,
      }
    end

    if player:isAlive() then
      room:removePlayerMark(player, "weizhuang_record-noclear", #room.players + 1)
      room:setPlayerMark(player, "@weizhuang_status-noclear", weizhuangMark)
    end
  end
end

weizhuang:addEffect(mobileUtil.CardDisplayed, {
  audio_index = { 3, 4 },
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(weizhuang.name) and
      player:getMark("weizhuang_record-noclear") >= #player.room.players + 1 and
      player:usedEffectTimes(self.name, Player.HistoryGame) +
        player:usedEffectTimes("#weizhuang_3_trig", Player.HistoryGame) <
        #player.room.players + 1
  end,
  on_cost = Util.TrueFunc,
  on_use = weizhuangBuffOnUse,

  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(weizhuang.name)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "weizhuang_record-noclear", #data.cards)
  end,
})

weizhuang:addEffect(fk.AfterCardsMove, {
  audio_index = { 3, 4 },
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(weizhuang.name) and
      player:getMark("weizhuang_record-noclear") >= #player.room.players + 1 and
      player:usedEffectTimes(self.name, Player.HistoryGame) +
        player:usedEffectTimes("#weizhuang_2_trig", Player.HistoryGame) <
        #player.room.players + 1
  end,
  on_cost = Util.TrueFunc,
  on_use = weizhuangBuffOnUse,

  can_refresh = function(self, event, target, player, data)
    return
      player:hasSkill(weizhuang.name) and
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
      room:addPlayerMark(player, "weizhuang_record-noclear", toDisplay)
    end
  end,
})

weizhuang:addEffect(fk.BeforeCardsMove, {
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

weizhuang:addEffect(fk.DrawNCards, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getTableMark("@weizhuang_status-noclear")[1]
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + player:getTableMark("@weizhuang_status-noclear")[1]
  end,
})

weizhuang:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope, card, to)
    local weizhuangMark = player:getTableMark("@weizhuang_status-noclear")
    if
      card and
      card.trueName == "slash" and
      weizhuangMark[2] and
      scope == Player.HistoryPhase then
      return weizhuangMark[2]
    end
  end,
})

weizhuang:addEffect("maxcards", {
  correct_func = function(self, player)
    local weizhuangMark = player:getTableMark("@weizhuang_status-noclear")
    if weizhuangMark[3] then
      return weizhuangMark[3]
    end
  end,
})

weizhuang:addLoseEffect(function(self, player, isDeath)
  if not isDeath then
    player.room:setPlayerMark(player, "weizhuang_record-noclear", 0)
  end
end)

return weizhuang
