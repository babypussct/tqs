local fengji = fk.CreateSkill {
  name = "os__fengji"
}

Fk:loadTranslationTable {
  ["os__fengji"] = "蜂集",
  [":os__fengji"] = "出牌阶段开始时，若你没有“示”，你可以将一张基本牌或普通锦囊牌置于武将牌上，称为“示”，" ..
  "并<a href='os__shifa_href'>施法</a>X=1~3回合：从牌堆中获得X张与“示”同名的牌，然后将“示”置入弃牌堆。",

  ["os__revelation"] = "示",
  ["@os__fengji"] = "蜂集",
  ["#os__fengji-ask"] = "蜂集：将一张基本牌或普通锦囊牌牌置于武将牌上，称为“示”并施法",
  ["#os__fengji-conjure"] = "蜂集：施法，第X个回合结束前，从牌堆中获得X张与“示”同名的牌，然后将“示”置入弃牌堆",

  ["$os__fengji1"] = "蜂趋蚁附，皆为道来。",
  ["$os__fengji2"] = "蜂攒蚁集，皆为道往！",
}

-- 主技能
fengji:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(fengji.name) and player.phase == Player.Play and
      not player:isKongcheng() and
      #player:getPile("os__revelation") == 0 and player:getMark("@os__fengji") == 0
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local cards = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id).type == Card.TypeBasic or Fk:getCardById(id):isCommonTrick()
    end)
    cards = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = fengji.name,
      pattern = tostring(Exppattern{ id = cards }),
      prompt = "#os__fengji-ask",
    })
    if #cards > 0 then
      event:setCostData(self, { cards = cards })
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local cards = event:getCostData(self).cards or {}
    player:addToPile("os__revelation", cards, true, fengji.name, player)
    if player.dead then return end
    local num = room:askToChoice(player, {
      choices = { "1", "2", "3" },
      skill_name = fengji.name,
      prompt = "#os__fengji-conjure",
    })
    room:setPlayerMark(player, "@os__fengji", num .. "-" .. num)
  end,
})

fengji:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player)
    return player:getMark("@os__fengji") ~= 0 and string.sub(player:getMark("@os__fengji"), -1) == "0"
  end,
  on_use = function(self, event, target, player)
    ---@type string
    local skillName = fengji.name
    local room = player.room
    local nums = string.split(player:getMark("@os__fengji"), "-")
    local num = tonumber(nums[1])
    if #player:getPile("os__revelation") > 0 then
      room:notifySkillInvoked(player, "os__fengji")
      player:broadcastSkillInvoke("os__fengji")
      room:obtainCard(
        player,
        room:getCardsFromPileByRule(Fk:getCardById(player:getPile("os__revelation")[1]).trueName, num),
        false,
        fk.ReasonPrey,
        player,
        skillName
      )
      room:moveCardTo(
        Fk:getCardById(player:getPile("os__revelation")[1]),
        Card.DiscardPile,
        nil,
        fk.ReasonPutIntoDiscardPile,
        skillName,
        "os__revelation"
      )
    end
    room:setPlayerMark(player, "@os__fengji", 0)
  end,

  can_refresh = function(self, event, target, player)
    return player:getMark("@os__fengji") ~= 0
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    local nums = string.split(player:getMark("@os__fengji"), "-")
    local num = tonumber(nums[1])
    local num2 = (tonumber(nums[2]) or 1) - 1
    room:setPlayerMark(player, "@os__fengji", num .. "-" .. num2)
  end,
})

return fengji
