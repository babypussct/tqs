
local ranlv = fk.CreateSkill {
  name = "ranlv",
  dynamic_desc = function (self, player)
    if #player:getTableMark(self.name) == 3 then
      return "dummyskill"
    else
      local choices = {}
      for i = 1, 3, 1 do
        if not table.contains(player:getTableMark(self.name), "ranlv"..i) then
          table.insert(choices, Fk:translate("ranlv"..i))
        else
          table.insert(choices, "<font color=\'gray\'>"..Fk:translate("ranlv"..i).."</font>")
        end
      end
      return "ranlv_inner:"..table.concat(choices, "；")
    end
  end,
}

Fk:loadTranslationTable{
  ["ranlv"] = "燃缕",
  [":ranlv"] = "有角色受到非属性伤害后，你可以选择一项执行并移除："..
  "1.横置或重置至多四名角色；2.摸三张牌；3.弃置一名角色两张牌。",

  [":ranlv_inner"] = "有角色受到非属性伤害后，你可以选择一项执行并移除：{1}。",

  ["#ranlv-invoke"] = "燃缕：你可以选择一项执行并移除",
  ["ranlv1"] = "横置或重置至多四名角色",
  ["ranlv2"] = "摸三张牌",
  ["ranlv3"] = "弃置一名角色两张牌",
  ["#ranlv1-choose"] = "燃缕：横置或重置至多四名角色",
  ["#ranlv2-choice"] = "燃缕：失去至多3点体力，摸等量张牌",
  ["#ranlv3-choose"] = "燃缕：弃置一名角色两张牌",

  ["$ranlv1"] = "",
  ["$ranlv2"] = "",
}

ranlv:addEffect(fk.Damaged, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(ranlv.name) and
      --data.card and data.card.color ~= Card.Black and
      data.damageType == fk.NormalDamage and
      #player:getTableMark(ranlv.name) < 3
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local all_choices = { "ranlv1", "ranlv2", "ranlv3" }
    local choices = table.filter(all_choices, function (choice)
      return not table.contains(player:getTableMark(ranlv.name), choice)
    end)
    if table.every(room.alive_players, function (p)
        return p:isNude()
      end) then
      table.removeOne(choices, "ranlv3")
    end
    if #choices == 0 then return end
    local choice = room:askToChoice(player, {
      skill_name = ranlv.name,
      prompt = "#ranlv-invoke",
      choices = choices,
      all_choices = all_choices,
      cancelable = true,
    })
    if choice ~= "Cancel" then
      if choice == "ranlv1" then
        local tos = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 4,
          targets = room.alive_players,
          skill_name = ranlv.name,
          prompt = "#ranlv1-choose",
          cancelable = true,
        })
        if #tos > 0 then
          room:sortByAction(tos)
          event:setCostData(self, { tos = tos, choice = choice })
          return true
        end
      elseif choice == "ranlv2" then
        --[[
        local n = room:askToNumber(player, {
          skill_name = ranlv.name,
          prompt = "#ranlv2-choice",
          min = 1,
          max = math.min(3, player.hp),
          cancelable = true,
        })
        if n then
          event:setCostData(self, { num = n, choice = choice })
          return true
        end]]--
        event:setCostData(self, { choice = choice })
        return true
      elseif choice == "ranlv3" then
        local targets = table.filter(room:getOtherPlayers(player, false), function (p)
          return not p:isNude()
        end)
        if table.find(player:getCardIds("he"), function (id)
          return not player:prohibitDiscard(id)
        end) then
          table.insert(targets, player)
        end
        if #targets == 0 then
          room:askToCards(player, {
            min_num = 1,
            max_num = 1,
            include_equip = false,
            skill_name = ranlv.name,
            pattern = "false",
            prompt = "#ranlv3-choose",
            cancelable = true,
          })
        else
          local to = room:askToChoosePlayers(player, {
            min_num = 1,
            max_num = 1,
            targets = targets,
            skill_name = ranlv.name,
            prompt = "#ranlv3-choose",
            cancelable = true,
          })
          if #to > 0 then
            event:setCostData(self, { tos = to, choice = choice })
            return true
          end
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    room:addTableMark(player, ranlv.name, choice)
    if choice == "ranlv1" then
      local tos = event:getCostData(self).tos or {}
      for _, p in ipairs(tos) do
        if not p.dead then
          p:setChainState(not p.chained)
        end
      end
    elseif choice == "ranlv2" then
      --local n = event:getCostData(self).num
      --room:loseHp(player, n, ranlv.name, player)
      --if not player.dead then
        player:drawCards(3, ranlv.name)
      --end
    elseif choice == "ranlv3" then
      local to = event:getCostData(self).tos[1]
      local cards = {}
      if to == player then
        cards = room:askToDiscard(player, {
          min_num = 1,
          max_num = 2,
          include_equip = true,
          skill_name = ranlv.name,
          cancelable = false,
          skip = true,
        })
      else
        cards = room:askToChooseCards(player, {
          min = 1,
          max = 2,
          target = to,
          flag = "he",
          skill_name = ranlv.name,
        })
      end
      room:throwCard(cards, ranlv.name, to, player)
      --[[
      if not to.dead then
        room:recover{
          who = to,
          num = #cards,
          recoverBy = player,
          skillName = ranlv.name,
        }
      end]]--
    end
  end,
})

ranlv:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, ranlv.name, 0)
end)

return ranlv
