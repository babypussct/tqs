local osXingZhilue = fk.CreateSkill {
  name = "os_xing__zhilue"
}

Fk:loadTranslationTable{
  ["os_xing__zhilue"] = "知略",
  [":os_xing__zhilue"] = "准备阶段，你可选择一项：1.移动场上的一张牌，若此牌为：装备牌，你失去1点体力；" ..
  "延时锦囊牌，你此回合手牌上限-1；2.此回合你摸牌阶段额定摸牌数+1，使用的第一张【杀】不计入次数且无距离限制。",

  ["os_xing__zhilue_draw"] = "摸牌阶段摸牌数+1，使用第一张【杀】无距离次数限制",
  ["os_xing__zhilue_move"] = "移动场上一张牌，若为装备牌，你失去1点体力；延时锦囊牌，你此回合手牌上限-1",
  ["#os_xing__zhilue-movecard"] = "知略：移动场上一张牌，若为装备牌，你失去1点体力；延时锦囊牌，你此回合手牌上限-1",
  ["@@os_xing__zhilue-turn"] = "知略",

  ["$os_xing__zhilue1"] = "时以进而取之，无则磨锋以待。",
  ["$os_xing__zhilue2"] = "知敌之薄弱，略我之计谋。",
}

osXingZhilue:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(osXingZhilue.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player)
    local choices = { "os_xing__zhilue_draw", "Cancel" }
    local room = player.room
    if #room:canMoveCardInBoard() > 0 then
      table.insert(choices, 1, "os_xing__zhilue_move")
    end
    local choice = room:askToChoice(
      player,
      {
        choices = choices,
        skill_name = osXingZhilue.name,
      }
    )
    if choice ~= "Cancel" then
      event:setCostData(self, choice)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    ---@type string
    local skillName = osXingZhilue.name
    local room = player.room
    local choice = event:getCostData(self)
    if choice == "os_xing__zhilue_move" then
      local targets = room:askToChooseToMoveCardInBoard(
        player,
        {
          skill_name = skillName,
          cancelable = false,
        }
      )
      local card = room:askToMoveCardInBoard(
        player,
        {
          target_one = targets[1],
          target_two = targets[2],
          skill_name = skillName,
        }
      ).card
      if not player:isAlive() then
        return false
      end

      if card.type == Card.TypeEquip then
        room:loseHp(player, 1, skillName)
      elseif card.sub_type == Card.SubtypeDelayedTrick then
        room:addPlayerMark(player, MarkEnum.MinusMaxCardsInTurn, 1)
      end
    else
      room:addPlayerMark(player, "@@os_xing__zhilue-turn")
      room:setPlayerMark(player, "os_xing__zhilue_slash-turn", 1)
    end
  end,
})

osXingZhilue:addEffect(fk.DrawNCards, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player)
    return target == player and player:getMark("@@os_xing__zhilue-turn") ~= 0
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + player:getMark("@@os_xing__zhilue-turn")
  end,
})

osXingZhilue:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("os_xing__zhilue_slash-turn") > 0 and data.card.trueName == "slash"
  end,
  on_refresh = function (self, event, target, player, data)
    data.extraUse = true
    player.room:setPlayerMark(player, "os_xing__zhilue_slash-turn", 0)
  end,
})

osXingZhilue:addEffect("targetmod", {
  bypass_distances = function (self, player, skill, card, to)
    return player:getMark("os_xing__zhilue_slash-turn") > 0 and skill.trueName == "slash_skill"
  end,
})

return osXingZhilue
