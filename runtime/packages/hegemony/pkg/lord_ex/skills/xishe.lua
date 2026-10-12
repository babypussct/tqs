local xishe = fk.CreateSkill {
  name = "ld__xishe",
}

Fk:loadTranslationTable {
  ["ld__xishe"] = "袭射",
  [":ld__xishe"] = "其他角色的准备阶段，你可以弃置一张装备区内的牌，视为对其使用一张【杀】（体力值小于你的角色不能响应），然后你可以重复此流程。"..
  "此回合结束时，若你以此法杀死了一名角色，你可以变更副将且变更后的副将处于暗置状态。",

  ["#ld__xishe"] = "袭射：你可以弃置一张装备区内的牌，视为对 %dest 使用一张【杀】",

  ["$ld__xishe1"] = "伏箭灭破虏，坚城拒讨逆。",
  ["$ld__xishe2"] = "什么江东猛虎？还不是我箭下之鬼！",
}

local H = require "packages.hegemony.util"

xishe:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xishe.name) and target.phase == Player.Start and target ~= player
        and table.find(player:getCardIds("e"), function(id) return not player:prohibitDiscard(Fk:getCardById(id)) end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    while true do
      local card = room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = xishe.name,
        pattern = ".|.|.|equip",
        prompt = "#ld__xishe::" .. target.id,
        cancelable = true,
      })
      if #card == 0 then break end
      local slash = Fk:cloneCard("slash")
      slash.skillName = xishe.name
      local use = { from = player, tos = { target }, card = slash, extraUse = true }
      use.extra_data = use.extra_data or {}
      use.extra_data.ld__xisheUser = player
      room:useCard(use)
      if #player:getCardIds("e") == 0 or player.dead or target.dead then
        break
      end
    end
  end,
})

xishe:addEffect(fk.Death, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.damage and data.damage.card and
    table.contains(data.damage.card.skillNames, xishe.name)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local use = room.logic:getMostRecentEvent(GameEvent.UseCard).data
    local user = (use.extra_data or {}).ld__xisheUser
    room:setPlayerMark(user, "ld__xishe_change-turn", 1)
  end,
})

xishe:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and (data.extra_data or {}).ld__xisheUser == player
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local targets = table.filter(data:getAllTargets(), function(p) return p.hp < player.hp end)
    data.use.disresponsiveList = data.use.disresponsiveList or {}
    table.insertTable(data.use.disresponsiveList, targets)
  end,
})

xishe:addEffect(fk.TurnEnd, {
  anim_type = "special",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("ld__xishe_change-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if room:askToChoice(player, {
      choices = { "transformDeputy", "Cancel" },
      skill_name = xishe.name
    }) ~= "Cancel" then
      H.transformGeneral(room, player, false, true)
    end
  end,
})

return xishe
