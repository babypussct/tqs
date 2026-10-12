local gaoyuan = fk.CreateSkill {
  name = "gaoyuan",
}

Fk:loadTranslationTable{
  ["gaoyuan"] = "告援",
  [":gaoyuan"] = "当你成为一名角色使用【杀】的目标时，你可以弃置一张牌，将此【杀】转移给另一名有“诤荐”标记的其他角色。",

  ["#gaoyuan-choose"] = "告援：你可以弃置一张牌，将此【杀】转移给一名有“诤荐”标记的其他角色",
  ["#gaoyuan-invoke"] = "告援：你可以弃置一张牌，将此【杀】转移给%src",

  ["$gaoyuan1"] = "烦请告知兴霸，请他务必相助。",
  ["$gaoyuan2"] = "如今事急，唯有兴霸可救。",
}

gaoyuan:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    local room = player.room
    if target == player and player:hasSkill(gaoyuan.name) and data.card.trueName == "slash" and not data.cancelled then
      return table.find(room:getOtherPlayers(player, false), function (p)
        return p ~= data.from and not data.from:isProhibited(p, data.card) and
          not (type(p:getMark("@zhengjian")) == "number" and p:getMark("@zhengjian") == 0)
      end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    ---@type string
    local skillName = gaoyuan.name
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return p ~= data.from and not data.from:isProhibited(p, data.card) and
        not (type(p:getMark("@zhengjian")) == "number" and p:getMark("@zhengjian") == 0)
    end)
    if #targets == 0 then
      return false
    elseif #targets == 1 then
      local card = room:askToDiscard(
        player,
        {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = gaoyuan.name,
          prompt = "#gaoyuan-invoke:" .. targets[1].id,
          skip = true,
        }
      )
      if #card > 0 then
        event:setCostData(self, { targets[1], card[1] })
        return true
      end
    else
      local tos, cid = room:askToChooseCardsAndPlayers(
        player,
        {
          targets = targets,
          min_num = 1,
          max_num = 1,
          min_card_num = 1,
          max_card_num = 1,
          prompt = "#gaoyuan-choose",
          skill_name = skillName,
          no_indicate = true,
          will_throw = true,
        }
      )
      if #tos > 0 then
        event:setCostData(self, { tos[1], cid })
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self)[1]
    room:doIndicate(player.id, { to.id })
    room:throwCard(event:getCostData(self)[2], gaoyuan.name, player, player)
    if data:cancelCurrentTarget() then
      data:addTarget(to)
    end
  end,
})

return gaoyuan
