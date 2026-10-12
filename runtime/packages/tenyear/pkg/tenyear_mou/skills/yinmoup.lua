local yinmoup = fk.CreateSkill {
  name = "yinmoup",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable{
  ["yinmoup"] = "寅谋",
  [":yinmoup"] = "转换技，游戏开始时可自选阴阳状态。每个回合结束时，若本回合有角色失去手牌数不小于当前手牌数，"..
  "你可以观看牌堆顶三张牌并交给其中一名角色一张牌，此牌离开其手牌区后，阳：摸当前体力值张牌（至多摸五张）；阴：弃置当前体力值张手牌。",

  ["#yinmoup_yang-invoke"] = "寅谋：观看牌堆顶三张牌并交给其中一名角色一张，其失去后此牌后摸牌",
  ["#yinmoup_yin-invoke"] = "寅谋：观看牌堆顶三张牌并交给其中一名角色一张，其失去后此牌后弃牌",
  ["#yinmoup-give"] = "寅谋：交给其中一名角色一张牌",
  ["@yinmoup-inhand"] = "寅谋",

  ["$yinmoup1"] = "曹脏孙乱、碌碌嚣尘，君岂可坐观天下丧于匹夫之手！",
  ["$yinmoup2"] = "吾君起于微末，知仁晓忍，舍公其谁当配天下！",
}

local U = require "packages.utility.utility"

yinmoup:addEffect(fk.TurnEnd, {
  anim_type = "switch",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yinmoup.name) then
      local dat = {}
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.from and not move.from.dead then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand then
                dat[move.from] = (dat[move.from] or 0) + 1
              end
            end
          end
        end
      end, Player.HistoryTurn)
      local targets = {}
      for p, n in pairs(dat) do
        if n >= p:getHandcardNum() then
          table.insert(targets, p)
        end
      end
      if #targets > 0 then
        event:setCostData(self, { extra_data = targets })
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = yinmoup.name,
      prompt = "#yinmoup_"..player:getSwitchSkillState(yinmoup.name, false, true).."-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getCostData(self).extra_data
    local cards = room:getNCards(3)
    U.SetSwitchSkillState(player, yinmoup.name, player:getSwitchSkillState(yinmoup.name, false))
    local to, card = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      min_num = 1,
      max_num = 1,
      targets = targets,
      pattern = tostring(Exppattern{ id = cards }),
      skill_name = yinmoup.name,
      prompt = "#yinmoup-give",
      cancelable = false,
      expand_pile = cards,
    })
    room:moveCardTo(card, Card.PlayerHand, to[1], fk.ReasonGive, yinmoup.name, nil, false, player,
      { "@yinmoup-inhand", Fk:translate(player:getSwitchSkillState(yinmoup.name, true, true)) })
  end,
})

yinmoup:addEffect(fk.AfterCardsMove, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if not player.dead then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.beforeCard:getMark("@yinmoup-inhand") ~= 0 and info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if info.beforeCard:getMark("@yinmoup-inhand") == Fk:translate("yang") then
            if player.hp > 0 then
              player:drawCards(math.min(player.hp, 5), yinmoup.name)
              if player.dead then return end
            end
          elseif info.beforeCard:getMark("@yinmoup-inhand") == Fk:translate("yin") then
            if player.hp > 0 and not player:isKongcheng() then
              player.room:askToDiscard(player, {
                min_num = player.hp,
                max_num = player.hp,
                include_equip = false,
                skill_name = yinmoup.name,
                cancelable = false,
              })
              if player.dead then return end
            end
          end
        end
      end
    end
  end,
})

yinmoup:addEffect(fk.GameStart, {
  mute = true,
  is_delay_effect = true,
  priority = 1.5,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yinmoup.name, true)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = { "tymou_switch:::yinmoup:yang", "tymou_switch:::yinmoup:yin" },
      skill_name = yinmoup.name,
      prompt = "#tymou_switch-choice:::yinmoup",
    })
    choice = choice:endsWith("yang") and fk.SwitchYang or fk.SwitchYin
    U.SetSwitchSkillState(player, yinmoup.name, choice)
  end,
})

return yinmoup
