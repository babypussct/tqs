local cuoruiw = fk.CreateSkill {
  name = "v22__cuoruiw",
}

Fk:loadTranslationTable{
  ["v22__cuoruiw"] = "挫锐",
  [":v22__cuoruiw"] = "出牌阶段开始时，你可以弃置一名友方角色区域内的一张牌。若如此做，你选择一项："..
  "1.弃置敌方角色装备区里至多两张与此牌颜色相同的牌；2.展示敌方角色共计至多两张手牌，然后获得其中与此牌颜色相同的牌。",

  ["#v22__cuoruiw-choose"] = "挫锐：你可以弃置友方角色区域里的一张牌",
  ["v22__cuoruiw_equip"] = "弃置敌方至多两张颜色相同的装备",
  ["v22__cuoruiw_hand"] = "展示敌方至多两张手牌并获得其中相同颜色牌",
  ["#v22__cuoruiw-discard"] = "挫锐：弃置敌方至多两张%arg装备",
  ["#v22__cuoruiw-show"] = "挫锐：展示敌方共计至多两张手牌，获得其中的%arg牌",

  ["$v22__cuoruiw1"] = "减辎疾行，挫敌军锐气。",
  ["$v22__cuoruiw2"] = "外物当舍，摄敌为重。",
}

cuoruiw:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(cuoruiw.name) and player.phase == Player.Play and
      table.find(player:getFriends(), function(p)
        return not p:isAllNude()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(player:getFriends(), function(p)
      return not p:isAllNude()
    end)
    if not table.find(player:getCardIds("hej"), function (id)
      return not player:prohibitDiscard(id)
    end) then
      table.removeOne(targets, player)
    end
    if #targets > 0 then
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#v22__cuoruiw-choose",
        skill_name = cuoruiw.name,
        cancelable = true,
      })
      if #to > 0 then
        event:setCostData(self, {tos = to})
        return true
      end
    else
      room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = cuoruiw.name,
        pattern = "false",
        prompt = "#v22__cuoruiw-choose",
        cancelable = true,
      })
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local id1
    if to == player then
      local ids = table.filter(player:getCardIds("hej"), function (id)
        return not player:prohibitDiscard(id)
      end)
      id1 = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = cuoruiw.name,
        pattern = tostring(Exppattern{ id = ids }),
        cancelable = false,
        expand_pile = player:getCardIds("j"),
      })[1]
    else
      id1 = room:askToChooseCard(player, {
        target = to,
        flag = "hej",
        skill_name = cuoruiw.name,
      })
    end
    local color = Fk:getCardById(id1).color
    room:throwCard(id1, cuoruiw.name, to, player)
    if player.dead then return end

    local choices = {}
    for _, p in ipairs(player:getEnemies()) do
      if not p:isKongcheng() then
        table.insertIfNeed(choices, "v22__cuoruiw_hand")
      end
      if table.find(p:getCardIds("e"), function(id)
        return Fk:getCardById(id).color == color
      end) then
        table.insertIfNeed(choices, "v22__cuoruiw_equip")
      end
    end
    if #choices == 0 then return end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = cuoruiw.name,
    })
    local total = 2
    if choice == "v22__cuoruiw_equip" then
      while total > 0 and not player.dead do
        local targets = table.filter(player:getEnemies(), function(p)
          return table.find(p:getCardIds("e"), function(id)
            return Fk:getCardById(id).color == color
          end) ~= nil
        end)
        if #targets == 0 then return end
        to = room:askToChoosePlayers(player, {
          targets = targets,
          min_num = 1,
          max_num = total,
          prompt = "#v22__cuoruiw-discard:::"..color,
          skill_name = cuoruiw.name,
          cancelable = true,
        })
        if #to == 0 then return end
        to = to[1]
        local cards = table.filter(to:getCardIds("e"), function(id)
          return Fk:getCardById(id).color == color
        end)
        cards = room:askToChooseCards(player, {
          target = to,
          min = 1,
          max = 2,
          flag = { card_data = { { to.general, cards }  } },
          skill_name = cuoruiw.name,
        })
        total = total - #cards
        room:throwCard(cards, cuoruiw.name, to, player)
      end
    else
      while total > 0 and not player.dead do
        local targets = table.filter(player:getEnemies(), function(p)
          return not p:isKongcheng()
        end)
        if #targets == 0 then return end
        to = room:askToChoosePlayers(player, {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = "#v22__cuoruiw-show:::"..color,
          skill_name = cuoruiw.name,
          cancelable = true,
        })
        if #to == 0 then return end
        to = to[1]
        local cards = room:askToChooseCards(player, {
          target = to,
          min = 1,
          max = total,
          flag = "h",
          skill_name = cuoruiw.name,
        })
        total = total - #cards
        to:showCards(cards)
        room:delay(1000)
        cards = table.filter(cards, function (id)
          return Fk:getCardById(id).color == color and table.contains(to:getCardIds("h"), id)
        end)
        if #cards > 0 and not player.dead then
          room:obtainCard(player, cards, false, fk.ReasonPrey, player, cuoruiw.name)
        end
      end
    end
  end,
})

return cuoruiw
