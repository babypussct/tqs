
local hongyuan = fk.CreateSkill({
  name = "os_mou__hongyuan",
  tags = { Skill.Charge },
})

Fk:loadTranslationTable{
  ["os_mou__hongyuan"] = "弘援",
  [":os_mou__hongyuan"] = "蓄力技（1/3），当你一次获得大于等于两张牌时，你可以消耗1点蓄力点令至多两名角色各摸一张牌。"..
  "当一名其他角色一次失去大于等于两张牌时，你可以消耗1点蓄力点令其摸两张牌。",

  ["#os_mou__hongyuan-choose"] = "弘援：你可以消耗1点蓄力点，令至多两名角色各摸一张牌",
  ["#os_mou__hongyuan-invoke"] = "弘援：你可以消耗1点蓄力点，令 %src 摸两张牌",

  ["$os_mou__hongyuan1"] = "",
  ["$os_mou__hongyuan2"] = "",
}

local U = require "packages.utility.utility"

hongyuan:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(hongyuan.name) or player:getMark("skill_charge") == 0 then return false end
    local tos = {}
    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Player.Hand then
        if #move.moveInfo > 1 then
          table.insert(tos, player)
        end
      end
      if move.from and move.from ~= player and move.from:isAlive() then
        if #table.filter(move.moveInfo, function (info)
          return info.fromArea == Player.Hand or info.fromArea == Player.Equip
        end) > 1 then
          table.insert(tos, move.from)
        end
      end
    end
    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local tos = table.simpleClone(event:getCostData(self).tos or {})
    player.room:sortByAction(tos)
    for _, p in ipairs(tos) do
      if not player:hasSkill(hongyuan.name) or player:getMark("skill_charge") == 0 then break end
      if p:isAlive() then
        self:doCost(event, p, player, data)
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if target == player then
      local tos = room:askToChoosePlayers(player, {
        targets = room.alive_players,
        min_num = 1,
        max_num = 2,
        prompt = "#os_mou__hongyuan-choose",
        skill_name = hongyuan.name
      })
      if #tos > 0 then
        room:sortByAction(tos)
        event:setCostData(self, { tos = tos })
        return true
      end
    elseif room:askToSkillInvoke(player, {
      skill_name = hongyuan.name,
      prompt = "#os_mou__hongyuan-invoke:" .. target.id,
    }) then
      event:setCostData(self, { tos = { target } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    U.skillCharged(player, -1)
    if target == player then
      for _, p in ipairs(event:getCostData(self).tos) do
        if not p.dead then
          p:drawCards(1, hongyuan.name)
        end
      end
    else
      target:drawCards(2, hongyuan.name)
    end
  end,
})

hongyuan:addAcquireEffect(function (self, player)
  U.skillCharged(player, 1, 3)
end)

hongyuan:addLoseEffect(function (self, player)
  U.skillCharged(player, -1, -3)
end)

return hongyuan
