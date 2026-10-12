
local zhiti = fk.CreateSkill{
  name = "ty__zhiti",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty__zhiti"] = "止啼",
  [":ty__zhiti"] = "锁定技，摸牌阶段，你多摸X张牌（X为场上所有被废除的装备栏数，至多为5）；"..
  "其他角色弃牌阶段结束时，若其有被废除的装备栏，你弃置其区域内等量张牌。",

  ["#ty__zhiti-discard"] = "止啼：弃置 %dest %arg张牌",

  ["$ty__zhiti1"] = "皆言江东多才俊，闻吾入吴亦夜啼！",
  ["$ty__zhiti2"] = "闻吾之名讳，江东小儿无不惧而止啼！",
}

zhiti:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(zhiti.name) and
      table.find(player.room.alive_players, function(p)
        return table.find(p.sealedSlots, function (slot)
          return slot ~= Player.JudgeSlot and slot ~= Player.HandSlot
        end) ~= nil
      end)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, p in ipairs(room.alive_players) do
      for _, slot in ipairs(p.sealedSlots) do
        if slot ~= Player.JudgeSlot and slot ~= Player.HandSlot then
          n = n + 1
        end
      end
    end
    data.n = data.n + math.min(n, 5)
  end,
})

zhiti:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target ~= player and player:hasSkill(zhiti.name) and target.phase == Player.Discard and
      not target:isAllNude() and
      table.find(target.sealedSlots, function (slot)
        return slot ~= Player.JudgeSlot and slot ~= Player.HandSlot
      end) ~= nil
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, { tos = { target } })
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, slot in ipairs(target.sealedSlots) do
      if slot ~= Player.JudgeSlot and slot ~= Player.HandSlot then
        n = n + 1
      end
    end
    local cards = room:askToChooseCards(player, {
      min = n,
      max = n,
      target = target,
      flag = "he",
      skill_name = zhiti.name,
      prompt = "#ty__zhiti-discard::"..target.id..":"..n,
    })
    room:throwCard(cards, zhiti.name, target, player)
  end,
})

return zhiti
