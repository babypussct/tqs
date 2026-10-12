local junmou = fk.CreateSkill {
  name = "junmou",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable{
  ["junmou"] = "隽谋",
  [":junmou"] = "转换技，游戏开始时可自选阴阳状态。以你为目标的牌结算结束后，你可以选择一张手牌，<br>" ..
  "阳：此牌视为无次数和距离限制的火【杀】并摸一张牌，你可以额外摸一张牌令此技能本阶段失效；<br>" ..
  "阴：此颜色的牌不计入手牌上限并横置一名角色，你可以额外横置一名角色令此技能本阶段失效。",

  ["#junmou-invoke_yang"] = "隽谋：选择一张手牌，视为无次数和距离限制的火【杀】并摸一张牌",
  ["#junmou_yang-extra"] = "隽谋：你可以多摸一张牌，此技能本阶段失效",
  ["#junmou-invoke_yin"] = "隽谋：选择一张手牌，此颜色手牌不计入手牌上限并横置一名角色",
  ["#junmou-choose"] = "隽谋：你可横置至多两名角色，若本次横置两名角色，则此技能本阶段失效",
  ["@@junmou_exlude-inhand"] = "不计入上限",

  ["$junmou1"] = "燎原之势已成，七十万枯骨作柴薪！",
  ["$junmou2"] = "夷陵宴始，邀玄德公献头！",
}

local U = require "packages.utility.utility"

junmou:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return table.contains(data.tos or {}, player) and player:hasSkill(junmou.name) and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local switchStatus = player:getSwitchSkillState(junmou.name)
    local room = player.room
    local ids = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      skill_name = junmou.name,
      prompt = switchStatus == fk.SwitchYang and "#junmou-invoke_yang" or "#junmou-invoke_yin",
    })

    if #ids == 0 then
      return false
    end

    local costData = { switchStatus = switchStatus, cardId = ids[1] }
    if
      switchStatus == fk.SwitchYang and
      room:askToSkillInvoke(
        player,
        {
          skill_name = junmou.name,
          prompt = "#junmou_yang-extra",
        }
      )
    then
      costData.extraDraw = true
    end

    event:setCostData(self, costData)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local costData = event:getCostData(self)
    U.SetSwitchSkillState(player, junmou.name, player:getSwitchSkillState(junmou.name))
    local switchStatus = costData.switchStatus
    local id = costData.cardId

    if not player:isAlive() or player:isKongcheng() then
      return false
    end

    if switchStatus == fk.SwitchYang then
      room:setCardMark(Fk:getCardById(id), "junmou_slash-inhand", 1)
      local drawNum = 1
      if costData.extraDraw then
        drawNum = 2
        room:invalidateSkill(player, junmou.name, "-phase")
      end
      player:drawCards(drawNum, junmou.name)
    else
      for _, c in ipairs(player:getCardIds("h")) do
        if Fk:getCardById(c):compareColorWith(Fk:getCardById(id)) then
          room:setCardMark(Fk:getCardById(c), "@@junmou_exlude-inhand", 1)
        end
      end
      local targets = table.filter(room.alive_players, function(p)
        return not p.chained
      end)
      if #targets == 0 then return end
      local tos = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 2,
        targets = targets,
        skill_name = junmou.name,
        prompt = "#junmou-choose",
      })
      if #tos == 0 then
        return false
      end

      if #tos > 1 then
        room:invalidateSkill(player, junmou.name, "-phase")
      end

      room:sortByAction(tos)
      for _, p in ipairs(tos) do
        p:setChainState(true)
      end
    end
  end,
})

junmou:addEffect("filter", {
  mute = true,
  card_filter = function(self, card, player, isJudgeEvent)
    return card:getMark("junmou_slash-inhand") ~= 0 and table.contains(player:getCardIds("h"), card.id)
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard("fire__slash", card.suit, card.number)
  end,
})

junmou:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and card:getMark("junmou_slash-inhand") ~= 0
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and card:getMark("junmou_slash-inhand") ~= 0
  end,
})

junmou:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return data.card:getMark("junmou_slash-inhand") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

junmou:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return card:getMark("@@junmou_exlude-inhand") > 0
  end,
})

junmou:addEffect(fk.GameStart, {
  mute = true,
  is_delay_effect = true,
  priority = 1.5,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(junmou.name, true)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = { "tymou_switch:::junmou:yang", "tymou_switch:::junmou:yin" },
      skill_name = junmou.name,
      prompt = "#tymou_switch-choice:::junmou",
    })
    choice = choice:endsWith("yang") and fk.SwitchYang or fk.SwitchYin
    U.SetSwitchSkillState(player, junmou.name, choice)
  end,
})

return junmou
