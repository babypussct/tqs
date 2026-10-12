
local miehai = fk.CreateSkill {
  name = "os__miehai",
}

Fk:loadTranslationTable{
  ["os__miehai"] = "灭害",
  [":os__miehai"] = "每回合限三次，你可以将两张牌当无距离和次数限制的刺【杀】使用。"..
  "因此失去过♠牌的角色回复1点体力，然后你可以令其中任意名角色各摸两张牌。",

  ["#os__miehai"] = "灭害：将两张牌当刺【杀】使用，结算期间失去过♠牌的角色回复1点体力，你选择其中任意名角色摸两张牌",
  ["#os__miehai-choose"] = "灭害：你可以令其中任意名角色各摸两张牌",

  ["$os__miehai1"] = "吾欲治天下之疾，当从权臣始！",
  ["$os__miehai2"] = "吾有一法，可绝丞相百般疾痛。",
}

miehai:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#os__miehai",
  times = function (self, player)
    return 3 - player:usedSkillTimes(miehai.name)
  end,
  pattern = "stab__slash",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected < 2
  end,
  view_as = function(self, player, cards)
    if #cards ~= 2 then return end
    local c = Fk:cloneCard("stab__slash")
    c.skillName = miehai.name
    c:addSubcards(cards)
    return c
  end,
  before_use = function (self, player, use)
    use.extraUse = true
    local room = player.room
    local banner = room:getBanner(miehai.name) or {}
    local index = 1
    if #banner > 0 then
      index = banner[#banner][1][1] + 1
    end
    use.extra_data = use.extra_data or {}
    use.extra_data.miehai = index
    table.insert(banner, {{index}, {}})
    room:setBanner(miehai.name, banner)
  end,
  after_use = function (self, player, use)
    local room = player.room
    local banner = room:getBanner(miehai.name)
    local index = use.extra_data.miehai
    if banner == nil or index == nil then return end
    local tos
    for i = #banner, 1, -1 do
      if banner[i][1][1] == index then
        tos = banner[i][2]
        table.remove(banner, i)
      end
    end
    room:setBanner(miehai.name, #banner > 0 and banner or 0)
    if tos then
      tos = table.map(tos, Util.Id2PlayerMapper) ---@type ServerPlayer[]
      tos = table.filter(tos, function (t)
        return not t.dead
      end)
      if #tos > 0 then
        room:sortByAction(tos)
        for _, p in ipairs(tos) do
          if not p.dead and p:isWounded() then
            room:recover{
              who = p,
              num = 1,
              recoverBy = player,
              skillName = miehai.name,
            }
          end
        end
        tos = table.filter(tos, function (t)
          return not t.dead
        end)
        tos = room:askToChoosePlayers(player, {
          targets = tos,
          min_num = 1,
          max_num = #tos,
          skill_name = miehai.name,
          prompt = "#os__miehai-choose",
          cancelable = true,
        })
        if #tos > 0 then
          room:sortByAction(tos)
          for _, p in ipairs(tos) do
            if not p.dead then
              p:drawCards(2, miehai.name)
            end
          end
        end
      end
    end
  end,
  enabled_at_play = function (self, player)
    return player:usedSkillTimes(miehai.name) < 3
  end,
  enabled_at_response = function (self, player, response)
    return not response
  end,
})

miehai:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return player.room:getBanner(miehai.name)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local tos = {}
    for _, move in ipairs(data) do
      if move.from and move.to ~= move.from and (move.moveVisible == nil or move.moveVisible) and
        table.find(move.moveInfo, function (info)
          return Fk:getCardById(info.cardId).suit == Card.Spade and
            (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip)
        end) then
        table.insertIfNeed(tos, move.from)
      end
    end
    if #tos > 0 then
      local banner = room:getBanner(miehai.name)
      for _, info in ipairs(banner) do
        table.insertTableIfNeed(info[2], table.map(tos, Util.IdMapper))
      end
      room:setBanner(miehai.name, banner)
    end
  end,
})

miehai:addEffect("targetmod", {
  bypass_distances = function (self, player, skill, card, to)
    return card and table.contains(card.skillNames, miehai.name)
  end,
  bypass_times = function (self, player, skill, scope, card, to)
    return card and table.contains(card.skillNames, miehai.name)
  end,
})

return miehai
