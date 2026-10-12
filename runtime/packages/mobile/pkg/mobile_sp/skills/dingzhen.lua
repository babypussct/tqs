local dingzhen = fk.CreateSkill {
  name = "dingzhen",
}

Fk:loadTranslationTable{
  ["dingzhen"] = "定镇",
  [":dingzhen"] = "每轮开始时，你可以令与你距离X以内的至多X名其他角色依次选择一项（X为你当前体力值）：" ..
  "1.弃置一张【杀】；2.本轮其于回合内使用锦囊牌不能指定你为目标。",

  ["#dingzhen-choose"] = "定镇：你可以令至多%arg名角色选择一项",
  ["#dingzhen-discard"] = "定镇：弃一张【杀】，否则本轮回合内使用锦囊牌不能指定 %src 为目标",
  ["@@dingzhen-round"] = "定镇",

  ["$dingzhen1"] = "招抚流民，兴复县邑。",
  ["$dingzhen2"] = "容民畜众，群羌归土。",
}

dingzhen:addEffect(fk.RoundStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(dingzhen.name) and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return p:compareDistance(player, player.hp, "<=")
      end) and player.hp > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = player.hp
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return p:compareDistance(player, n, "<=")
    end)
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = n,
      prompt = "#dingzhen-choose:::" .. n,
      skill_name = dingzhen.name,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getCostData(self).tos or {}
    for _, p in ipairs(targets) do
      if not p.dead and
        #room:askToDiscard(p, {
          min_num = 1,
          max_num = 1,
          pattern = "slash",
          prompt = "#dingzhen-discard:" .. player.id,
          skill_name = dingzhen.name,
        }) == 0 and not player.dead then
        room:addTableMarkIfNeed(p, "@@dingzhen-round", player.id)
      end
    end
  end,
})

dingzhen:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return from and card and to and
      Fk:currentRoom():getCurrent() == from and card.type == Card.TypeTrick and
      table.contains(from:getTableMark("@@dingzhen-round"), to.id)
  end,
})

return dingzhen
