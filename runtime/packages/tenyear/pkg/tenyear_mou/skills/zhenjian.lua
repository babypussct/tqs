local zhenjian = fk.CreateSkill{
  name = "zhenjian",
}

Fk:loadTranslationTable{
  ["zhenjian"] = "缜鉴",
  [":zhenjian"] = "每轮开始时，你可以选择一名其他角色并秘密选择一种普通锦囊牌名，本轮内其使用普通锦囊牌时，若与你选择的牌名："..
  "不同，你可以令此牌增加或减少一个目标（目标数至少为1）；相同，你摸一张牌，此技能本回合失效。",

  ["#zhenjian-invoke"] = "缜鉴：选择一名角色并秘密选择锦囊牌，本轮其使用锦囊时根据牌名是否相同执行效果",
  ["#zhenjian-choose"] = "缜鉴：你可以为%arg增加或减少一个目标",

  ["$zhenjian1"] = "我知季玉其人，必不为伤民之恶。",
  ["$zhenjian2"] = "自古有拒敌以安民，无动民以避敌。",
}

zhenjian:addAuxActiveSkill("zhenjian_active", {
  interaction = function(self, player)
    return UI.ComboBox { choices = Fk:getAllCardNames("t") }
  end,
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
})

zhenjian:addEffect(fk.RoundStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhenjian.name) and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "zhenjian_active",
      prompt = "#zhenjian-invoke",
    })
    if success and dat then
      event:setCostData(self, { tos = dat.targets, choice = dat.interaction })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choice = event:getCostData(self).choice
    room:setPlayerMark(player, "zhenjian-round", { to, choice })
  end,
})

zhenjian:addEffect(fk.AfterCardTargetDeclared, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if
      player:getMark("zhenjian-round") ~= 0 and
      data.card:isCommonTrick() and
      target == player:getMark("zhenjian-round")[1] and
      player:hasSkill(zhenjian.name)
    then
      if data.card.trueName ~= player:getMark("zhenjian-round")[2] then
        return #data:getExtraTargets({ bypass_distances = true }) > 0 or #data.tos > 1
      else
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(zhenjian.name)
    if data.card.trueName ~= player:getMark("zhenjian-round")[2] then
      local targets = data:getExtraTargets({ bypass_distances = true })
      if #data.tos > 1 then
        table.insertTableIfNeed(targets, data.tos)
      end
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#zhenjian-choose:::" .. data.card:toLogString(),
        skill_name = zhenjian.name,
        cancelable = true,
        no_indicate = false,
        target_tip_name = "addandcanceltarget_tip",
        extra_data = table.map(data.tos, Util.IdMapper),
      })
      if #to > 0 then
        room:notifySkillInvoked(player, zhenjian.name, "control")
        to = to[1]
        if table.contains(data.tos, to) then
          data:removeTarget(to)
        else
          data:addTarget(to)
          room:sendLog{
            type = "#AddTargetsBySkill",
            from = player.id,
            to = { to.id },
            arg = zhenjian.name,
            arg2 = data.card:toLogString(),
          }
        end
      end
    else
      room:notifySkillInvoked(player, zhenjian.name, "drawcard")
      room:invalidateSkill(player, zhenjian.name, "-turn")
      player:drawCards(1, zhenjian.name)
    end
  end,
})

return zhenjian
