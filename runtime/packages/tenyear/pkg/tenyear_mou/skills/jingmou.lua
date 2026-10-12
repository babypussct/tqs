local jingmou = fk.CreateSkill {
  name = "jingmou",
  tags = { Skill.Switch },
  related_skills = { "dingnan" },
}

Fk:loadTranslationTable{
  ["jingmou"] = "靖谋",
  [":jingmou"] = "转换技，游戏开始时你可自选阴阳状态。任意角色出牌阶段开始时，若你没有记录的花色或牌类别，" ..
  "你可以弃置任意张牌并秘密记录其中至多三种包含的花色或牌类别。"..
  "当一名角色使用与记录的花色或类别相同的牌时，移除该记录，<br>" ..
  "阳：你可以令此牌无效并弃置牌堆顶的一张牌，若与使用的牌花色相同，你对其造成1点火焰伤害；<br>"..
  "阴：此牌结算结束后，你将之交给一名角色。<br>" ..
  "若你移除过所有花色和类别，你获得技能〖定南〗。",

  ["@[jingmou]"] = "靖谋",
  ["#jingmou-discard"] = "靖谋：弃置任意张牌，记录其中包含的花色与类别各一种",
  ["#jingmou-suit"] = "靖谋：请选择要记录的花色",
  ["#jingmou-type"] = "靖谋：请选择要记录的类别",
  ["#jingmou-negate"] = "靖谋：是否令此%arg无效，并可能对 %dest 造成1点火焰伤害？",
  ["#jingmou-choose"] = "靖谋：将%arg交给一名角色",

  ["#JingMouRemoved"] = "已移除过的花色和类别",
  ["#JingMouSuits"] = "当前记录的花色",
  ["#JingMouTypes"] = "当前记录的类别",
  ["#JingMouNone"] = "无",

  ["$jingmou1"] = "不服王化者，当死此谷中！",
  ["$jingmou2"] = "盘蛇一炬，万骨成焦，顺天者昌，逆天者亡。",
}

local U = require "packages.utility.utility"

jingmou:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if not (target.phase == Player.Play and player:hasSkill(jingmou.name)) then
      return false
    end

    local record = player:getMark("@[jingmou]")
    record = type(record) == "table" and record or {}
    return #(record.suits or {}) == 0 and #(record.types or {}) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local ids = player.room:askToDiscard(player, {
      min_num = 1,
      max_num = #player:getCardIds("he"),
      skill_name = jingmou.name,
      include_equip = true,
      prompt = "#jingmou-discard",
      skip = true,
    })

    if #ids > 0 then
      event:setCostData(self, { cards = ids, no_switch = true })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = jingmou.name
    local room = player.room

    ---@type integer[]
    local cards = event:getCostData(self).cards

    local props = {}
    table.forEach(cards, function(id)
      local card = Fk:getCardById(id)
      table.insertIfNeed(props, card:getTypeString())
      if card.suit ~= Card.NoSuit then
        table.insertIfNeed(props, card:getSuitString())
      end
    end)

    room:throwCard(cards, skillName, player, player)
    if not player:isAlive() then
      return false
    end

    local record = player:getMark("@[jingmou]")
    record = type(record) == "table" and record or {}

    props = room:askToChoices(player, {
      choices = props,
      min_num = 1,
      max_num = 3,
      skill_name = skillName,
      prompt = "#jingmou-suit:::",
      cancelable = false,
      all_choices =
      {
        "basic", "trick", "equip",
        "spade", "heart", "club", "diamond"
      },
    })

    record.suits = record.suits or {}
    record.types = record.types or {}

    local types = { "basic", "trick", "equip" }

    for _, prop in ipairs(props) do
      if table.contains(types, prop) then
        table.insertIfNeed(record.types, prop)
      else
        table.insertIfNeed(record.suits, prop)
      end
    end

    room:setPlayerMark(player, "@[jingmou]", record)
  end,
})

jingmou:addEffect(fk.CardUsing, {
  anim_type = "switch",
  can_trigger = function(self, event, target, player, data)
    local record = player:getMark("@[jingmou]")
    if not (player:hasSkill(jingmou.name) and record ~= 0) then
      return false
    end

    record = type(record) == "table" and record or {}
    if
      table.contains(record.suits or {}, data.card:getSuitString()) or
      table.contains(record.types or {}, data.card:getTypeString())
    then
      if player:getSwitchSkillState(jingmou.name) == fk.SwitchYang then
        return true
      else
        local logic = player.room.logic
        local e = logic:getCurrentEvent()
        while e do
          if e.event == GameEvent.UseCard then
            if table.contains((e.data.extra_data or {}).jingmouYinOwner or {}, player) then
              return false
            end
          end
          e = e.parent
        end
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local switchState = player:getSwitchSkillState(jingmou.name)
    ---@type CostData
    local costData = { switchState = switchState }
    if switchState == fk.SwitchYin then
      costData.no_switch = true
      costData.mute = true
    end
    event:setCostData(self, costData)
    return true
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = jingmou.name
    local room = player.room
    local switchState = event:getCostData(self).switchState

    if switchState == fk.SwitchYang then
      U.SetSwitchSkillState(player, skillName, fk.SwitchYin)
    end

    local record = player:getMark("@[jingmou]")
    record = type(record) == "table" and record or {}
    local curSuit = data.card:getSuitString()
    if table.contains(record.suits or {}, curSuit) then
      table.removeOne(record.suits, curSuit)
      record.removed = record.removed or {}
      table.insertIfNeed(record.removed, curSuit)
    end

    local curType = data.card:getTypeString()
    if table.contains(record.types or {}, curType) then
      table.removeOne(record.types, curType)
      record.removed = record.removed or {}
      table.insertIfNeed(record.removed, curType)
    end

    room:setPlayerMark(player, "@[jingmou]", record)
    if #(record.removed or {}) > 6 then
      room:handleAddLoseSkills(player, "dingnan")
    end

    if switchState == fk.SwitchYang then
      if room:askToSkillInvoke(player, {
        skill_name = skillName,
        prompt = "#jingmou-negate::" .. data.from.id .. ":" .. data.card:toLogString(),
      }) then
        --data.toCard = nil
        --data:removeAllTargets()
        data:setNullified()
        local ids = room:getNCards(1)
        local suit = Fk:getCardById(ids[1]).suit
        room:moveCardTo(ids, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, skillName, nil, true, player)
        if suit == data.card.suit then
          room:damage{
            from = player,
            to = data.from,
            damage = 1,
            damageType = fk.FireDamage,
            skillName = skillName,
          }
        end
      end
    else
      data.extra_data = data.extra_data or {}
      data.extra_data.jingmouYinOwner = data.extra_data.jingmouYinOwner or {}
      table.insert(data.extra_data.jingmouYinOwner, player)
    end
  end,
})

jingmou:addEffect(fk.CardUseFinished, {
  anim_type = "switch",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jingmou.name) and
      player:getSwitchSkillState(jingmou.name) == fk.SwitchYin and
      table.contains((data.extra_data or {}).jingmouYinOwner or {}, player)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = jingmou.name
    U.SetSwitchSkillState(player, skillName, fk.SwitchYang)
    local room = player.room
    if room:getCardArea(data.card) ~= Card.Processing then return end
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = skillName,
      prompt = "#jingmou-choose:::" .. data.card:toLogString(),
      cancelable = false,
    })[1]
    room:obtainCard(to, data.card, true, fk.ReasonGive, player, skillName)
  end,
})

jingmou:addEffect(fk.GameStart, {
  mute = true,
  is_delay_effect = true,
  priority = 1.5,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jingmou.name, true)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = { "tymou_switch:::jingmou:yang", "tymou_switch:::jingmou:yin" },
      skill_name = jingmou.name,
      prompt = "#tymou_switch-choice:::jingmou",
    })
    choice = choice:endsWith("yang") and fk.SwitchYang or fk.SwitchYin
    U.SetSwitchSkillState(player, jingmou.name, choice)
  end,
})

Fk:addQmlMark{
  name = jingmou.name,
  how_to_show = function(name, value, player)
    return " "
  end,
  qml = function(name, value, player)
    if Self == player then
      return {
        url = "packages/tenyear/qml/JingMouBox.qml",
        prop = {
          name = name, value = value,
        },
      }
    end
  end,
}

return jingmou
