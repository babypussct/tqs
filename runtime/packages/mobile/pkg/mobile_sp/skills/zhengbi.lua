
local zhengbi = fk.CreateSkill {
  name = "mobile__zhengbi",
}

Fk:loadTranslationTable{
  ["mobile__zhengbi"] = "征辟",
  [":mobile__zhengbi"] = "准备阶段，你可以选择至多一名其他角色，其选择令你获得其区域内的一至三张牌，然后你交给其等量张牌。"..
  "每名角色限一次，若其选择三，你因〖征辟〗选择的角色数+1。",

  ["#mobile__zhengbi-choose"] = "征辟：选择至多%arg名角色，你获得其区域内一至三张牌",
  ["#mobile__zhengbi-choice"] = "征辟：令 %src 获得你区域内的一至三张牌",
  ["#mobile__zhengbi-give"] = "征辟：请交给 %dest %arg张牌",

  ["$mobile__zhengbi1"] = "共掌东曹，为君遴羽，为民择天！",
  ["$mobile__zhengbi2"] = "用人使天下自治，正身率一世之杰。",
  ["$mobile__zhengbi3"] = "清名颂于山野，天下莫不砥砺！",
  ["$mobile__zhengbi4"] = "正时风谓之清雅，秉中直四海归心！",
}

zhengbi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhengbi.name) and player.phase == Player.Start and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not p:isAllNude()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not p:isAllNude()
    end)
    local tos = room:askToChoosePlayers(player, {
      skill_name = zhengbi.name,
      min_num = 1,
      max_num = 1 + #player:getTableMark(zhengbi.name),
      targets = targets,
      prompt = "#mobile__zhengbi-choose:::"..1 + #player:getTableMark(zhengbi.name),
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(event:getCostData(self).tos) do
      if not p:isAllNude() then
        local n = room:askToNumber(p, {
          min = 1,
          max = math.min(#p:getCardIds("hej"), 3),
          skill_name = zhengbi.name,
          prompt = "#mobile__zhengbi-choice:"..player.id,
        })   ---@cast n integer
        local cards = room:askToChooseCards(player, {
          target = p,
          min = n,
          max = n,
          flag = "hej",
          skill_name = zhengbi.name,
        })
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, zhengbi.name, nil, false, player)

        if player:isAlive() and p:isAlive() and not player:isNude() then
          local toGive = room:askToCards(
            player,
            {
              min_num = n,
              max_num = n,
              include_equip = true,
              skill_name = zhengbi.name,
              prompt = "#mobile__zhengbi-give::" .. p.id .. ":" .. n,
              cancelable = false,
            }
          )

          room:obtainCard(p, toGive, false, fk.ReasonGive, player, zhengbi.name)
        end

        if n == 3 and player:hasSkill(zhengbi.name, true) then
          room:addTableMarkIfNeed(player, zhengbi.name, p)
        end
      end
    end
  end,
})

return zhengbi
