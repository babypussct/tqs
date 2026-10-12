local osXianfeng = fk.CreateSkill {
  name = "os__xianfeng"
}

Fk:loadTranslationTable{
  ["os__xianfeng"] = "先锋",
  [":os__xianfeng"] = "当你于出牌阶段使用伤害牌对其他角色造成伤害后，你可令其选择一项：1. 其摸一张牌，直到你的下回合开始，" ..
  "你至其他角色距离-1；2. 你摸一张牌，直到你的下回合开始，其至你距离-1。",

  ["#os__xianfeng"] = "你想对 %dest 发动技能“先锋”吗？",
  ["os__xianfeng_self"] = "你摸一张牌，直到其下回合开始，其至你距离-1",
  ["os__xianfeng_yg"] = "其摸一张牌，直到其下回合开始，你至其距离-1",
  ["#os__xianfeng-ask"] = "先锋：对 %src 选择一项",
  ["@os__xianfeng"] = "先锋",
  ["@os__xianfeng_others"] = "先锋",

  ["$os__xianfeng1"] = "吾领万余白马，可堪此战先锋！",
  ["$os__xianfeng2"] = "白马先发，敌不攻而散！",
}

osXianfeng:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(osXianfeng.name) and
      player.phase == Player.Play and
      data.to ~= player and
      data.card and
      data.card.is_damage_card and player:isAlive() and
      data.to:isAlive()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(
      player,
      {
        skill_name = osXianfeng.name,
        prompt = "#os__xianfeng::" .. data.to.id,
      }
    )
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osXianfeng.name
    local room = player.room
    local to = data.to
    local choice = room:askToChoice(
      to,
      {
        choices = { "os__xianfeng_self", "os__xianfeng_yg" },
        skill_name = skillName,
        prompt = "#os__xianfeng-ask:" .. player.id,
      }
    )
    if choice == "os__xianfeng_self" then
      to:drawCards(1, skillName)
      room:addPlayerMark(player, "@os__xianfeng")
    else
      player:drawCards(1, skillName)
      room:addTableMark(player, "_os__xianfeng_others", to.id)
      local record = type(to:getMark("@os__xianfeng_others")) == "table" and to:getMark("@os__xianfeng_others") or { player.general, 0 }
      record[2] = record[2] - 1
      room:setPlayerMark(to, "@os__xianfeng_others", record)
    end
  end,
})

osXianfeng:addEffect("distance", {
  correct_func = function(self, from, to)
    if from:getMark("@os__xianfeng") > 0 then
      return -from:getMark("@os__xianfeng")
    end

    if to:getMark("_os__xianfeng_others") ~= 0 then
      return -#table.filter(to:getMark("_os__xianfeng_others"), function(pid) return from.id == pid end)
    end
  end,
})

local osXianfengClearOnRefresh = function(self, event, target, player, data)
  local room = player.room
  room:setPlayerMark(player, "@os__xianfeng", 0)
  room:setPlayerMark(player, "_os__xianfeng_others", 0)
  for _, p in ipairs(room.alive_players) do
    room:setPlayerMark(p, "@os__xianfeng_others", 0)
  end
end

osXianfeng:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@os__xianfeng") ~= 0 or player:getMark("_os__xianfeng_others") ~= 0
  end,
  on_refresh = osXianfengClearOnRefresh,
})

osXianfeng:addEffect(fk.Death, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("_os__xianfeng_others") ~= 0
  end,
  on_refresh = osXianfengClearOnRefresh,
})

return osXianfeng
