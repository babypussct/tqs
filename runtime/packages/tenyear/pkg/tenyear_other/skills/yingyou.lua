local yingyou = fk.CreateSkill {
  name = "ty__yingyou",
}

Fk:loadTranslationTable{
  ["ty__yingyou"] = "应有",
  [":ty__yingyou"] = "你的回合开始时，结束阶段开始时，或当你受到伤害后，你可以选择一项执行并摸一张牌：1.随机获得一个五虎将的技能；" ..
  "2.将<a href=':real__crossbow'>【真·诸葛连弩】</a>置入你的装备区；3.获得10吨馒头（当你使用手牌时，可消耗等同于此牌点数吨馒头令此牌额外结算一次）。",

  ["ty__yingyou_skill"] = "随机获得一个五虎将技能",
  ["ty__yingyou_ak"] = "将【真·诸葛连弩】置入你的装备区",
  ["ty__yingyou_mantou"] = "获得10吨馒头",
  ["@ty__yingyou_mantou"] = "馒头",

  ["#ty__yingyou-extra"] = "应有：你可以消耗%arg吨馒头，令%arg2额外结算一次",
}

local function GetWuhuSkills(player)
  local room = player.room
  local mappers = room:getBanner("huyi_wuhushangjiang")
  if mappers == nil then
    local skills = {}
    local generals = {}
    local SGmapper = {}
    for name, general in pairs(Fk.generals) do
      local wuhuNames = { "guanyu", "zhangfei", "zhaoyun", "machao", "huangzhong", "gundam" }
      if Fk:canUseGeneral(name) and table.find(wuhuNames, function(wuhu) return general.trueName:endsWith(wuhu) end) then
        table.insert(generals, general)
      end
    end
    if #generals == 0 then return {} end
    for _, general in ipairs(generals) do
      local list = general:getSkillNameList(true)
      for _, skill in ipairs(list) do
        table.insert(skills, skill)
        SGmapper[skill] = general.name
      end
    end
    mappers = { skills, SGmapper }
    room:setBanner("huyi_wuhushangjiang", mappers)
  end
  return table.filter(mappers[1], function(s) return not player:hasSkill(s, true) end)
end

local yingyouSpec = { ---@type TrigSkelSpec<fun(self: TriggerSkill, event: TurnEvent|DamageEvent, target: ServerPlayer, player: ServerPlayer, data: TurnData|DamageData):any>
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yingyou.name)
  end,
  on_cost = function(self, event, target, player, data)
    local choices = { "ty__yingyou_skill", "ty__yingyou_ak", "ty__yingyou_mantou", "Cancel" }
    local allChoices = table.simpleClone(choices)

    local realCrossbow = table.find(
      player.room:prepareDeriveCards({ { "real__crossbow", Card.Club, 1 } }, yingyou.name),
      function (id)
        return player.room:getCardArea(id) == Card.Void
      end
    )
    if not (realCrossbow and player:canMoveCardIntoEquip(realCrossbow)) then
      table.remove(choices, 2)
    end

    local choice = player.room:askToChoice(
      player,
      {
        choices = choices,
        skill_name = yingyou.name,
        all_choices = allChoices,
      }
    )

    if choice == "Cancel" then
      return false
    end

    event:setCostData(self, { choice = choice })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local choice = event:getCostData(self).choice
    ---@type string
    local skillName = yingyou.name
    local room = player.room

    if choice == "ty__yingyou_skill" then
      local skills = room:tableRandomPick(GetWuhuSkills(player), 1)
      if #skills == 0 then return end

      local skill = skills[1]
      room:addTableMark(player, skillName, skill)
      room:handleAddLoseSkills(player, skill)
    elseif choice == "ty__yingyou_ak" then
      local realCrossbow = table.find(
        player.room:prepareDeriveCards({ { "real__crossbow", Card.Club, 1 } }, skillName),
        function (id)
          return player.room:getCardArea(id) == Card.Void
        end
      )
      if realCrossbow then
        room:setCardMark(Fk:getCardById(realCrossbow), MarkEnum.DestructOutMyEquip, 1)
        room:moveCardIntoEquip(player, realCrossbow, skillName, true, player)
      end
    else
      room:addPlayerMark(player, "@ty__yingyou_mantou", 10)
    end

    if player:isAlive() then
      player:drawCards(1, skillName)
    end
  end,
}

yingyou:addEffect(fk.TurnStart, yingyouSpec)

yingyou:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yingyou.name) and player.phase == Player.Finish
  end,
  on_cost = yingyouSpec.on_cost,
  on_use = yingyouSpec.on_use,
})

yingyou:addEffect(fk.Damaged, yingyouSpec)

yingyou:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(yingyou.name) and
      data:isUsingHandcard(player) and
      data.card.number > 0 and
      player:getMark("@ty__yingyou_mantou") >= data.card.number
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(
      player,
      { skill_name = yingyou.name, prompt = "#ty__yingyou-extra:::" .. data.card.number .. ":" .. data.card:toLogString() }
    )
  end,
  on_use = function(self, event, target, player, data)
    player.room:removePlayerMark(player, "@ty__yingyou_mantou", data.card.number)
    -- TODO：额外结算暂时偷懒
    data.additionalEffect = (data.additionalEffect or 0) + 1
  end,
})

return yingyou
