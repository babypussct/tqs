
local jiushi = fk.CreateSkill{
  name = "ol_heg__jiushi",
}

Fk:loadTranslationTable{
  ["ol_heg__jiushi"] = "酒诗",
  [":ol_heg__jiushi"] = "你明置一张武将牌后，若当前回合角色能使用【酒】，你可以令其视为使用之。"..
  "当你受到伤害后，若你的武将牌均明置，你可以重铸任意张♣牌并暗置此武将牌。",

  ["#ol_heg__jiushi-invoke"] = "酒诗：你可以令 %dest 视为使用【酒】",
  ["#ol_heg__jiushi-recast"] = "酒诗：你可以重铸任意张♣牌并暗置此武将牌",

  ["$ol_heg__jiushi1"] = "",
  ["$ol_heg__jiushi2"] = "",
}

local H = require "packages.hegemony.util"

jiushi:addEffect(fk.GeneralRevealed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiushi.name) and
      player.room:getCurrent() and player.room:getCurrent():canUse(Fk:cloneCard("analeptic"), { bypass_times = false })
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = jiushi.name,
      prompt = "#ol_heg__jiushi-invoke::"..room:getCurrent().id,
    }) then
      event:setCostData(self, { tos = { room:getCurrent() } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local current = room:getCurrent()  ---@cast current ServerPlayer 
    room:useVirtualCard("analeptic", {}, current, current, jiushi.name, false)
  end
})

jiushi:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(jiushi.name) and
      H.allGeneralsRevealed(player) and not player:isNude()
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 999,
      include_equip = true,
      skill_name = jiushi.name,
      pattern = ".|.|club",
      prompt = "#ol_heg__jiushi-recast",
      cancelable = true,
    })
    if #cards > 0 then
      event:setCostData(self, { cards = cards })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:recastCard(event:getCostData(self).cards, player, jiushi.name)
    if not player.dead then
      H.hideBySkillName(player, jiushi.name)
    end
  end,
})

return jiushi
