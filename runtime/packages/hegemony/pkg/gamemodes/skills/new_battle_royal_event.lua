local battleRoyalVs = fk.CreateSkill{
  name = "#new_battle_royal_event&",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["#new_battle_royal_event&"] = "鏖战",
  [":#new_battle_royal_new_event&"] = "",

  ["@[:]new_battle_royal_event"] = "本轮事件：",
  ["new_battle_royal_event-log"] = "本轮事件为：%arg：%arg2",

  ["@[:]battle_royal_used_event"] = "历史事件",

  ["battle_royal_bujinzetui"] = "不进则退",
  [":battle_royal_bujinzetui"] = "本轮内：每名角色的回合结束时，若其本回合未造成过伤害，其失去1点体力。",

  ["battle_royal_fuli"] = "赋礼",
  [":battle_royal_fuli"] = "本轮内：任意角色的摸牌阶段开始前，其可以跳过此阶段，改为获得弃牌堆中至多两张<a href=':rare_treasure'>奇珍牌</a>。",
  ["#battle_royal_fuli"] = "赋礼：你可以跳过此阶段，改为获得弃牌堆中至多两张奇珍牌",

  ["battle_royal_luoshi"] = "落石",
  [":battle_royal_luoshi"] = "翻开此牌时，所有确定势力的角色依次变更副将。",

  ["battle_royal_shengzheweiwang"] = "胜者为王",
  [":battle_royal_shengzheweiwang"] = "本轮内：有角色死亡时，杀死其的角色本局游戏摸牌阶段多摸三张牌。",
  ["@battle_royal_shengzheweiwang"] = "胜者为王",

  ["battle_royal_huoqi"] = "祸起",
  [":battle_royal_huoqi"] = "本轮内：所有角色受到的伤害+1。",

  ["battle_royal_jili"] = "激励",
  [":battle_royal_jili"] = "本轮内：【杀】无次数距离限制。",
}

local H = require "packages.hegemony.util"

local all_events = {
  "battle_royal_bujinzetui",
  "battle_royal_fuli",
  "battle_royal_luoshi",
  "battle_royal_shengzheweiwang",
  "battle_royal_huoqi",
  "battle_royal_jili",
}

---获取当前事件
---@param room Room|AbstractRoom
local function getCurrentEvent(room)
  local event = room:getBanner("@[:]new_battle_royal_event") or {}
  if event then
    return event
  end
end

---抽取并替换事件（无重复抽取直到抽完）
---@param room Room
local function changeEvent(room)
  local used = room:getBanner("@[:]battle_royal_used_event") or {}
  local events = table.simpleClone(all_events)
  table.removeTable(events, used)
  if #events == 0 then
    used = {}
    events = table.simpleClone(all_events)
    room:setBanner("new_battle_royal_event_used", used)
  end
  local event = room:tableRandomPick(events)
  table.insert(used, event)
  room:setBanner("new_battle_royal_event_used", used)
  room:setBanner("@[:]new_battle_royal_event", event)
  room:setBanner("@[:]battle_royal_used_event", used)
  room:sendLog{
    type = "new_battle_royal_event-log",
    arg = event,
    arg2 = ":" .. event,
    toast = true
  }
  ---落石
  if getCurrentEvent(room) == "battle_royal_luoshi" then
    for _, p in ipairs(room:getAlivePlayers(true)) do
      if not p.dead and p.kingdom ~= "unknown" then
        H.transformGeneral(room, p, false, false, 1)
      end
    end
  end
end


---每轮刷新
battleRoyalVs:addEffect(fk.RoundStart, {
  can_trigger = function (self, event, target, player, data)
    return player.seat == 1
  end,
  on_trigger = function (self, event, target, player, data)
    changeEvent(player.room)
  end,
})

---不进则退
battleRoyalVs:addEffect(fk.TurnEnd, {
  anim_type = "negative",
  can_trigger = function (self, event, target, player, data)
    return player == target and not player.dead and getCurrentEvent(player.room) == "battle_royal_bujinzetui" and
      #player.room.logic:getActualDamageEvents(1, function (e)
        return e.data.from == player
      end, Player.HistoryTurn) == 0
  end,
  on_use = function (self, event, target, player, data)
    player.room:loseHp(player, 1, battleRoyalVs.name)
  end,
})

---赋礼
battleRoyalVs:addEffect(fk.EventPhaseChanging, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return player == target and data.phase == Player.Draw and not player.dead and
      getCurrentEvent(player.room) == "battle_royal_fuli" and not data.skipped
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = battleRoyalVs.name,
      prompt = "#battle_royal_fuli"
    })
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    data.skipped = true
    local cards = table.filter(room.discard_pile, function (id)
      local card = Fk:getCardById(id)
      return card.type == Card.TypeEquip and card.package.name == "nine_variations"
    end)
    if #cards > 0 then
      cards = room:askToChooseCards(player, {
        min = 1,
        max = 2,
        target = player,
        flag = { card_data = {{ "equip", cards }} },
        skill_name = battleRoyalVs.name,
      })
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, battleRoyalVs.name, nil, false, player)
    end
  end,
})

---胜者为王
battleRoyalVs:addEffect(fk.Death, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return not player.dead and getCurrentEvent(player.room) == "battle_royal_shengzheweiwang" and data.killer == player
  end,
  on_use= function (self, event, target, player, data)
    player.room:addPlayerMark(player, "@battle_royal_shengzheweiwang")
  end,
})

battleRoyalVs:addEffect(fk.DrawNCards, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and target:getMark("@battle_royal_shengzheweiwang") > 0
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + 3 * target:getMark("@battle_royal_shengzheweiwang")
  end,
})

---祸起
battleRoyalVs:addEffect(fk.DamageInflicted, {
  anim_type = "negative",
  can_trigger = function (self, event, target, player, data)
    return player == target and not player.dead and getCurrentEvent(player.room) == "battle_royal_huoqi" and data.damage > 0
  end,
  on_use = function (self, event, target, player, data)
    data:changeDamage(1)
  end,
})

---激励
battleRoyalVs:addEffect("targetmod", {
  bypass_distances = function (self, player, skill, card, to)
    if card and card.trueName == "slash" and getCurrentEvent(Fk:currentRoom()) == "battle_royal_jili" then
      return true
    end
  end,
  bypass_times = function (self, player, skill, scope, card, to)
    if card and card.trueName == "slash" and getCurrentEvent(Fk:currentRoom()) == "battle_royal_jili" then
      return true
    end
  end,
})

return battleRoyalVs
