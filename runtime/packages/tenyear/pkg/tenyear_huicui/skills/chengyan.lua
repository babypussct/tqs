local chengyan = fk.CreateSkill {
  name = "chengyan",
}

Fk:loadTranslationTable{
  ["chengyan"] = "乘烟",
  [":chengyan"] = "你使用【杀】或普通锦囊牌指定其他角色为目标后，可以摸一张牌并展示。<br>"..
    "若展示牌为【杀】或普通锦囊牌，将使用牌的效果改为展示牌的效果；否则摸一张牌并标记为“笛”。",

  ["#chengyan-invoke"] = "乘烟：是否摸一张牌？若是【杀】或普通锦囊牌，则将此%arg改为摸到牌的效果",
  ["#chengyan-choose"] = "乘烟：选择对 %dest 使用【%arg】的副目标",

  ["$chengyan1"] = "素女乘烟去，白玉凤凰声。",
  ["$chengyan2"] = "香魄成飞仙，凤箫月中闻。",
}

chengyan:addEffect(fk.TargetSpecified, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chengyan.name) and data.firstTarget and
      not table.contains(data.card.skillNames, chengyan.name) and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      table.find(data.use.tos, function(p)
        return p ~= player
      end)
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = chengyan.name,
      prompt = "#chengyan-invoke:::"..data.card:toLogString(),
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:drawCards(1, chengyan.name)
    if #cards == 0 or player.dead or not table.contains(player:getCardIds("h"), cards[1]) then return end
    room:showCards(cards, player)
    if player.dead then return end
    local card = Fk:getCardById(cards[1])
    if card.trueName == "slash" or card:isCommonTrick() then
      --实测无视禁止使用
      if not (card.is_passive) then
        card = Fk:cloneCard(card.name, data.card.suit, 0)
        card.color = data.card.color
        card.skillName = chengyan.name
        local new_tos = table.filter(data.use.tos, function (p)
          return not player:isProhibited(p, card) and
            card.skill:modTargetFilter(player, p, {}, card, { bypass_distances = true, bypass_times = true })
        end)
        --FIXME:实测是当前时机结算后终止使用流程（进入使用事件结束时）
        data.use.tos = {}
        if #new_tos > 0 then
          room:sortByAction(new_tos)
          local n = card.skill:getMinTargetNum(player)
          if n > 1 then
            local tos = {}
            for _, p in ipairs(new_tos) do
              local sub_tos = table.filter(room.alive_players, function (q)
                return card.skill:targetFilter(player, q, {p}, {}, card)
              end)
              if #sub_tos > 0 then
                local sub_to = room:askToChoosePlayers(player, {
                  min_num = n - 1,
                  max_num = n - 1,
                  targets = sub_tos,
                  skill_name = chengyan.name,
                  prompt = "#chengyan-choose::"..p.id..":"..card.name,
                  cancelable = false,
                })
                table.insert(tos, p)
                table.insertTable(tos, sub_to)
              end
            end
            new_tos = tos
          end
          if #new_tos > 0 then
            room:useCard{
              from = player,
              tos = new_tos,
              card = card,
              extraUse = true,
            }
          end
        end
      end
    elseif not player.dead then
      player:drawCards(1, chengyan.name, nil, player:hasSkill("xidi", true) and "@@xidi-inhand" or nil)
    end
  end,
})

return chengyan
