local xingxue = fk.CreateSkill{
  name = "m_ex__xingxue",
  dynamic_desc = function(self, player)
    return player:hasSkill("m_ex__yanzhu", true) and "m_ex__xingxue_normal" or "m_ex__xingxue_upgrade"
  end,
}

Fk:loadTranslationTable{
  ["m_ex__xingxue"] = "兴学",
  [":m_ex__xingxue"] = "结束阶段，你可以选择至多X名角色（X为你的体力值），这些角色各摸一张牌并将一张牌置于牌堆顶，"..
    "若你没有〖宴诛〗，则可以改为将一张牌交给另一名此技能的目标且X改为你的体力上限。",

  [":m_ex__xingxue_normal"] = "结束阶段，你可以选择至多X名角色（X为你的体力值），这些角色各摸一张牌并将一张牌置于牌堆顶。",
  [":m_ex__xingxue_upgrade"] = "结束阶段，你可以选择至多X名角色（X为你的体力上限）这些角色各摸一张牌并选择："..
    "1.将一张牌置于牌堆顶；2.将一张牌交给另一名此技能的目标。",

  ["#m_ex__xingxue-choose"] = "兴学：你可以令至多%arg名角色依次摸一张牌并将一张牌置于牌堆顶",
  ["m_ex__xingxue_puttodrawpile"] = "将一张牌置于牌堆顶",
  ["m_ex__xingxue_give"] = "将一张牌交给一名兴学的目标",
  ["#m_ex__xingxue-puttodrawpile"] = "兴学：选择一张牌置于牌堆顶",
  ["#m_ex__xingxue-give"] = "兴学：选择1张牌交给1名此次兴学的目标，或不选目标则置于牌堆顶",

  ["$m_ex__xingxue1"] = "古者建国，教学为先，为时养器！",
  ["$m_ex__xingxue2"] = "偃武修文，以崇大化！",
}

xingxue:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xingxue.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local x = player:hasSkill("m_ex__yanzhu", true) and player.hp or player.maxHp
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = x,
      targets = room.alive_players,
      skill_name = xingxue.name,
      prompt = "#m_ex__xingxue-choose:::" .. x,
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local xingxue_upgrade = (not player:hasSkill("m_ex__yanzhu", true, true))
    local tos = event:getCostData(self).tos
    for _, to in ipairs(tos) do
      if not to.dead then
        room:drawCards(to, 1, xingxue.name)
        if not (to.dead or to:isNude()) then
          local selected, cards = room:askToChooseCardsAndPlayers(to, {
            targets = table.filter(tos, function (p)
              return p ~= to
            end),
            min_card_num = 1,
            max_card_num = 1,
            min_num = 0,
            max_num = xingxue_upgrade and 1 or 0,
            pattern = ".",
            prompt = xingxue_upgrade and "#m_ex__xingxue-give" or "#m_ex__xingxue-puttodrawpile",
            skill_name = xingxue.name,
            cancelable = false,
            no_indicate = true
          })
          if #selected == 0 then
            room:moveCardTo(cards, Card.DrawPile, nil, fk.ReasonPut, xingxue.name, nil, false, to)
          else
            room:obtainCard(selected[1], cards, false, fk.ReasonGive, to, xingxue.name)
          end
        end
      end
    end
  end,
})

return xingxue
