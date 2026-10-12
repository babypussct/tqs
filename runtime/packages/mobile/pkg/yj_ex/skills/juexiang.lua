local juexiang = fk.CreateSkill{
  name = "mobile__juexiang",
  related_skills = { "mobile__canyun" },
}

Fk:loadTranslationTable{
  ["mobile__juexiang"] = "绝响",
  [":mobile__juexiang"] = "当你死亡时，杀死你的角色弃置装备区里的所有牌并失去1点体力，然后你可以令一名其他角色获得技能〖残韵〗，"..
  "该角色可以弃置场上一张♣牌，再获得技能〖绝响〗。",

  ["#mobile__juexiang-choose"] = "绝响：你可以令一名其他角色获得技能“残韵”",
  ["#mobile__juexiang-throw"] = "绝响：你可以弃置场上一张♣牌，再获得技能“绝响”",

  ["$mobile__juexiang1"] = "一曲广陵散，从此绝凡尘。",
  ["$mobile__juexiang2"] = "古之琴音，今绝响矣！",
}

juexiang:addEffect(fk.Death, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(juexiang.name, false, true) and
      ((data.killer and not data.killer.dead) or #player.room:getOtherPlayers(player, false) > 0)
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {data.killer}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.killer and not data.killer.dead then
      data.killer:throwAllCards("e", juexiang.name)
      if not data.killer.dead then
        room:loseHp(data.killer, 1, juexiang.name)
      end
    end
    if #room:getOtherPlayers(player, false) == 0 then return end
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = juexiang.name,
      prompt = "#mobile__juexiang-choose",
      cancelable = true,
    })
    if #to > 0 then
      to = to[1]
      room:handleAddLoseSkills(to, "mobile__canyun")
      local targets = table.filter(room.alive_players, function (p)
        return table.find(p:getCardIds("ej"), function(id)
          return Fk:getCardById(id).suit == Card.Club
        end) ~= nil
      end)
      if #targets == 0 then return end
      local tos = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = juexiang.name,
        prompt = "#mobile__juexiang-throw",
        cancelable = true,
      })
      if #tos > 0 then
        local to2 = tos[1]
        local card_data = {}
        local equip = table.filter(to2:getCardIds("e"), function(id)
          return Fk:getCardById(id).suit == Card.Club
        end)
        if #equip > 0 then
          table.insert(card_data, { "$Equip", equip })
        end
        local judge = table.filter(to2:getCardIds("j"), function(id)
          return Fk:getCardById(id).suit == Card.Club
        end)
        if #judge > 0 then
          table.insert(card_data, { "$Judge", judge })
        end
        local card = room:askToChooseCard(to, {
          target = to2,
          flag = { card_data = card_data },
          skill_name = juexiang.name,
        })
        room:throwCard(card, juexiang.name, to2, to)
        room:handleAddLoseSkills(to, "mobile__juexiang")
      end
    end
  end,
})

return juexiang
