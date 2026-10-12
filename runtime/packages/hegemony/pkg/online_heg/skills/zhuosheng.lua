local zhuosheng = fk.CreateSkill{
  name = "ol_heg__zhuosheng",
}

Fk:loadTranslationTable{
  ["ol_heg__zhuosheng"] = "擢升",
  [":ol_heg__zhuosheng"] = "当与你势力相同的角色受到伤害后，你可以令其摸一张牌，直到其下个结束阶段，其使用此牌根据类型执行效果：<br>"..
  "基本牌：无距离次数限制；<br>普通锦囊牌，可以令此牌目标+1或-1；<br>装备牌，其可以摸一张牌。",

  ["#ol_heg__zhuosheng-invoke"] = "擢升：你可以令 %dest 摸一张牌，其使用此牌获得增益",
  ["@@ol_heg__zhuosheng-inhand"] = "擢升",
  ["#ol_heg__zhuosheng-choose"] = "擢升：你可以为此%arg增加或减少一个目标",
  ["#ol_heg__zhuosheng-draw"] = "擢升：你可以摸一张牌",

  ["$ol_heg__zhuosheng1"] = "才经世务，干用之绩。",
  ["$ol_heg__zhuosheng2"] = "器量之远，当至公辅。",
}

local H = require "packages.hegemony.util"

zhuosheng:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhuosheng.name) and not target.dead and
      H.compareKingdomWith(target, player)
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = zhuosheng.name,
      prompt = "#ol_heg__zhuosheng-invoke::"..target.id,
    }) then
      event:setCostData(self, { tos = {target} })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    target:drawCards(1, zhuosheng.name, nil, "@@ol_heg__zhuosheng-inhand")
  end,
})

zhuosheng:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and
      (data.extra_data or {}).ol_heg__zhuosheng and data.card:isCommonTrick() and
      (#data.tos > 1 or #data:getExtraTargets() > 0)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = {}
    if #data.tos > 1 then
      table.insertTable(targets, data.tos)
    end
    table.insertTable(targets, data:getExtraTargets())
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ol_heg__zhuosheng-choose:::"..data.card:toLogString(),
      skill_name = zhuosheng.name,
      cancelable = true,
      extra_data = table.map(data.tos, Util.IdMapper),
      target_tip_name = "addandcanceltarget_tip",
    })
    if #tos > 0 then
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    if table.contains(data.tos, to) then
      data:removeTarget(to)
    else
      data:addTarget(to)
    end
  end,
})

zhuosheng:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and
      (data.extra_data or {}).ol_heg__zhuosheng and data.card.type == Card.TypeEquip
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = zhuosheng.name,
      prompt = "#ol_heg__zhuosheng-draw",
    })
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, zhuosheng.name)
  end,
})

zhuosheng:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card:getMark("@@ol_heg__zhuosheng-inhand") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.ol_heg__zhuosheng = true
    if data.card.type == Card.TypeBasic then
      data.extraUse = true
    end
  end,
})

zhuosheng:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and card.type == Card.TypeBasic and card:getMark("@@ol_heg__zhuosheng-inhand") > 0
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return card and card.type == Card.TypeBasic and card:getMark("@@ol_heg__zhuosheng-inhand") > 0
  end,
})

zhuosheng:addEffect(fk.EventPhaseStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player.phase == Player.Finish
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:clearHandMark(player, "@@ol_heg__zhuosheng-inhand")
  end,
})

return zhuosheng
