local juelie = fk.CreateSkill {
  name = "ol__juelie",
}

Fk:loadTranslationTable{
  ["ol__juelie"] = "绝烈",
  [":ol__juelie"] = "当你使用【杀】指定目标后，你可以弃置至多X张牌（X为你的体力值），令目标角色弃置共计等量的牌" ..
  "（每名目标角色依次弃置任意张牌（可不弃），最后一名目标角色须弃置剩余牌数）。"..
  "然后若你的手牌数或体力值最小，此【杀】伤害+1；若你因此【杀】杀死一名角色，你将手牌摸至体力上限（至多为5）。",

  ["#ol__juelie-discard"] = "绝烈：你可以弃置至多%arg张牌，令目标弃置等量的牌",

  ["$ol__juelie1"] = "此战，当立千秋之功烈，绝万世之祸危！",
  ["$ol__juelie2"] = "坚固以躯命，与贼争生死！",
}

juelie:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(juelie.name) and data.firstTarget and
      data.card.trueName == "slash" and not player:isNude() and player.hp > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToDiscard(player, {
      min_num = 1,
      max_num = player.hp,
      include_equip = true,
      skill_name = juelie.name,
      cancelable = true,
      prompt = "#ol__juelie-discard:::" .. player.hp,
      skip = true,
    })
    if #cards > 0 then
      event:setCostData(self, {tos = {data.to}, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.extra_data = data.extra_data or {}
    data.extra_data.ol__juelie = player
    local cards = event:getCostData(self).cards ---@type integer[]
    room:throwCard(cards, juelie.name, player, player)
    local n = #cards
    local targets = data.use.tos
    local num = #targets
    for i, p in ipairs(targets) do
      local last = i == num
      if not (p.dead or p:isNude()) then
        local discard = room:askToDiscard(p, {
          min_num = last and n or 1,
          max_num = n,
          include_equip = true,
          skill_name = juelie.name,
          cancelable = not last,
        })
        n = n - #discard
        if n <= 0 then
          break
        end
      end
    end
    if (table.every(room.alive_players, function(p)
        return p:getHandcardNum() >= player:getHandcardNum()
      end) or
      table.every(room.alive_players, function(p)
        return p.hp >= player.hp
      end)) then
      data.use.additionalDamage = (data.use.additionalDamage or 0) + 1
    end
  end,
})

juelie:addEffect(fk.Death, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if data.damage and data.damage.from and data.damage.from == player and not player.dead and
      data.damage.card and player:getHandcardNum() < math.min(5, player.maxHp) then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if use_event then
        local use = use_event.data
        return use.extra_data and use.extra_data.ol__juelie == player
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(math.min(5, player.maxHp) - player:getHandcardNum(), juelie.name)
  end,
})

return juelie
