local osJianwei = fk.CreateSkill {
  name = "os__jianwei"
}

Fk:loadTranslationTable{
  ["os__jianwei"] = "剑威",
  [":os__jianwei"] = "若你装备区里有武器牌，你的【杀】无视防具，你拼点的点数+X（X为你的攻击范围），其他角色的准备阶段，" ..
  "其可与你拼点；你的准备阶段，你可与攻击范围内的一名角色拼点：若你赢，你获得其每个区域各一张牌；若你没赢，其获得你装备区里的武器牌。",

  ["#os__jianwei-target"] = "剑威：你可与一名攻击范围内的角色拼点：若你赢，你获得其每个区域各一张牌；若你没赢，其获得你装备区里的武器牌",
  ["#os__jianwei-ask"] = "剑威：你可与 %src 拼点：若其没赢，你获得其装备区里的武器牌；若其赢，其获得你每个区域各一张牌",

  ["$os__jianwei1"] = "小小匹夫，可否闻长坂剑神之名号？",
  ["$os__jianwei2"] = "此剑吹毛得过，削铁如泥。",
}

local U = require "packages.utility.utility"

-- 触发技效果
osJianwei:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      data.card.trueName == "slash" and
      player:hasSkill(osJianwei.name) and
      player:getEquipment(Card.SubtypeWeapon)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.to:addQinggangTag(data)
  end,
})

osJianwei:addEffect(fk.PindianCardsDisplayed, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return
      (data.from == player or table.contains(data.tos, player)) and
      player:hasSkill(osJianwei.name) and
      player:getEquipment(Card.SubtypeWeapon) and
      player:getAttackRange() > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:changePindianNumber(data, player, player:getAttackRange(), osJianwei.name)
  end,
})

-- 拼点技能效果
osJianwei:addEffect(fk.EventPhaseStart, {
  anim_type = "special",
  can_trigger = function(self, event, target, player)
    if
      not player:hasSkill(osJianwei.name) or
      target.phase ~= Player.Start or
      target:isKongcheng() or
      not player:getEquipment(Card.SubtypeWeapon)
    then
      return false
    end
    if target == player then
      return table.find(player.room.alive_players, function(p)
        return player:canPindian(p) and player:inMyAttackRange(p)
      end)
    else
      return target:canPindian(player)
    end
  end,
  on_cost = function(self, event, target, player)
    ---@type string
    local skillName = osJianwei.name
    local room = target.room
    if target == player then
      local availableTargets = table.filter(room.alive_players, function(p)
        return player:canPindian(p) and player:inMyAttackRange(p)
      end)
      if #availableTargets == 0 then
        return false
      end

      local targets = room:askToChoosePlayers(
        player,
        {
          min_num = 1,
          max_num = 1,
          targets = availableTargets,
          prompt = "#os__jianwei-target",
          skill_name = skillName,
        }
      )
      if #targets > 0 then
        event:setCostData(self, targets[1])
        return true
      end
    else
      return room:askToSkillInvoke(
        target,
        {
          skill_name = skillName,
          prompt = "#os__jianwei-ask:" .. player.id,
        }
      )
    end
  end,
  on_use = function(self, event, target, player)
     ---@type string
     local skillName = osJianwei.name
    local room = target.room
    local to, pd, pd_target
    if target == player then
      to = event:getCostData(self)
      pd_target = to
      pd = player:pindian({ pd_target }, skillName)
    else
      to = target
      pd_target = player
      pd = target:pindian({ pd_target }, skillName)
    end
    if pd.results[pd_target].winner == player then
      if not player:isAlive() or to:isAllNude() then return end
      local cards = U.askforCardsChosenFromAreas(player, to, "hej", skillName, nil, nil, false)
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, skillName, nil, false, player)
      end
    else
      if #player:getEquipments(Card.SubtypeWeapon) > 0 then
        room:obtainCard(to, player:getEquipments(Card.SubtypeWeapon), true, fk.ReasonPrey, to, skillName)
      end
    end
  end,
})

return osJianwei
