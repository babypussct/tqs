
local fu = fk.CreateSkill {
  name = "mobile__natu_fu",
}

Fk:loadTranslationTable {
  ["mobile__natu_fu"] = "抚",
  [":mobile__natu_fu"] = "你使用锦囊牌后，可以发动此技能。若此牌：<br>"..
  "1.与你手牌中的“兴”牌名均不同，你令体力值唯一最小的角色回复1点体力；<br>"..
  "2.本局游戏仅你使用过此牌名的牌，你对一名角色造成1点火焰伤害。<br>"..
  "乘势：本次执行效果中的所有数字+1。",

  ["#mobile__natu_fu-recover"] = "你可发动抚，令 %dest 回复%arg点体力",
  ["#mobile__natu_fu-damage"] = "你可发动抚，对一名角色造成%arg点火焰伤害",
  ["#mobile__natu_fu-combo"] = "你可发动抚，令 %dest 回复%arg点体力，然后对一名角色造成%arg点火焰伤害",
  ["#mobile__natu_fu-choose"] = "抚：对一名角色造成%arg点火焰伤害",

  ["$mobile__natu_fu1"] = "天下百姓安乐，种花家才会太平。",
  ["$mobile__natu_fu2"] = "为了亲们的太平，我愿穷尽此生。",
}

fu:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(fu.name) and
      data.card.type == Card.TypeTrick then
      local yes1, yes2
      if not table.find(player:getCardIds("h"), function (id)
        local card = Fk:getCardById(id)
        return card:getMark("@@mobile__natu_xing-inhand") > 0 and card.trueName == data.card.trueName
      end) then
        yes1 = true
      end
      if #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        return e.data.from ~= player and e.data.card.trueName == data.card.trueName
      end, Player.HistoryGame) == 0 then
        yes2 = true
      end
      local extra_data = { choices = {} }
      if yes1 then
        local targets = table.filter(player.room.alive_players, function (p)
          return not table.find(player.room:getOtherPlayers(p, false), function (q)
            return q.hp <= p.hp
          end)
        end)
        if #targets == 1 and targets[1]:isWounded() then
          table.insert(extra_data.choices, "recover")
          extra_data.tos = targets
        end
      end
      if yes2 then
        table.insert(extra_data.choices, "damage")
      end
      if #extra_data.choices > 0 then
        extra_data.n = yes1 and yes2 and 2 or 1
        event:setCostData(self, extra_data)
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local extra_data = event:getCostData(self)
    local prompt
    if #extra_data.choices == 2 then
      prompt = "#mobile__natu_fu-combo::" .. extra_data.tos[1].id .. ":" .. extra_data.n
    elseif table.contains(extra_data.choices, "recover") then
      prompt = "#mobile__natu_fu-recover::" .. extra_data.tos[1].id .. ":" .. extra_data.n
    else
      prompt = "#mobile__natu_fu-damage:::" .. extra_data.n
    end

    if room:askToSkillInvoke(player, {
      skill_name = fu.name,
      prompt = prompt,
    }) then
      event:setCostData(self, extra_data)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local extra_data = event:getCostData(self)
    local to
    if table.contains(extra_data.choices, "recover") then
      to = event:getCostData(self).tos[1]
      room:recover{
        who = to,
        num = extra_data.n,
        recoverBy = player,
        skillName = fu.name,
      }
      if player.dead then return end
    end
    if table.contains(extra_data.choices, "damage") then
      to = room:askToChoosePlayers(player, {
        targets = room.alive_players,
        min_num = 1,
        max_num = 1,
        prompt = "#mobile__natu_fu-choose:::" .. extra_data.n,
        skill_name = fu.name,
        cancelable = false,
      })[1]
      room:damage{
        from = player,
        to = to,
        damage = extra_data.n,
        damageType = fk.FireDamage,
        skillName = fu.name,
      }
    end
  end,
})

return fu
