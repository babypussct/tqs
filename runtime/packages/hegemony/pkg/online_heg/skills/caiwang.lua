local caiwang = fk.CreateSkill{
  name = "ol_heg__caiwang",
}

Fk:loadTranslationTable{
  ["ol_heg__caiwang"] = "才望",
  [":ol_heg__caiwang"] = "当你使用/打出牌响应其他角色使用的牌后，或其他角色使用/打出牌响应你使用的牌后，若两张牌颜色相同，你可以弃置其一张牌。",

  ["#ol_heg__caiwang-discard"] = "才望：你可以弃置 %dest 一张牌",
  ["#ol_heg__caiwang-prey"] = "才望：你可以获得 %dest 一张牌",

  ["$ol_heg__caiwang1"] = "才气不俗，声望四海。",
  ["$ol_heg__caiwang2"] = "绥怀之称，监守邺城。",
}

local spec = {
  on_cost = function(self, event, target, player, data)
    local prompt = "#ol_heg__caiwang-discard"
    local to
    if data.responseToEvent.from == player then
      to = target
    elseif target == player then
      to = data.responseToEvent.from
    end
    if table.contains(player:getTableMark("naxiang"), to.id) then
      prompt = "#ol_heg__caiwang-prey"
    end
    if player.room:askToSkillInvoke(player, {
      skill_name = caiwang.name,
      prompt = prompt.."::"..to.id,
    }) then
      event:setCostData(self, {tos = {to}, choice = prompt})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local card = room:askToChooseCard(player, {
      target = to,
      flag = "he",
      skill_name = caiwang.name,
    })
    if event:getCostData(self).choice:startsWith("#ol_heg__caiwang-discard") then
      room:throwCard(card, caiwang.name, to, player)
    else
      room:obtainCard(player, card, false, fk.ReasonPrey, player, caiwang.name)
    end
  end,
}

caiwang:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(caiwang.name) and
      data.responseToEvent and
      data.responseToEvent.card and
      data.responseToEvent.card:compareColorWith(data.card)
    then
      local to
      if data.responseToEvent.from == player then
        to = target
      elseif target == player then
        to = data.responseToEvent.from
      end
      return to and to ~= player and not to:isNude()
    end
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

caiwang:addEffect(fk.CardRespondFinished, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(caiwang.name) and data.responseToEvent.card and data.responseToEvent.card:compareColorWith(data.card) then
      local to
      if data.responseToEvent.from == player then
        to = target
      elseif target == player then
        to = data.responseToEvent.from
      end
      return to and to ~= player and not to:isNude()
    end
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

return caiwang
