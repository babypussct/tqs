local zhengu = fk.CreateSkill {
  name = "zhengu",
}

Fk:loadTranslationTable{
  ["zhengu"] = "镇骨",
  [":zhengu"] = "结束阶段，你可以选择一名其他角色，本回合结束时和其下个回合结束时，其将手牌摸或弃至与你手牌数量相同（至多摸至五张）。",

  ["#zhengu-choose"] = "镇骨：选择一名其他角色，本回合结束时和其下个回合结束时其将手牌调整与你相同",
  ["@@zhengu"] = "镇骨",

  ["$zhengu1"] = "镇守城池，必以骨相拼！",
  ["$zhengu2"] = "孔明计虽百算，却难敌吾镇骨千具！",
}

zhengu:addLoseEffect(function (self, player, is_death)
  if is_death then
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      room:removeTableMark(p, "@@zhengu", player.id)
    end
  end
end)
zhengu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhengu.name) and player.phase == Player.Finish and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = zhengu.name,
      prompt = "#zhengu-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:addTableMarkIfNeed(to, "@@zhengu", player.id)
    local x, y, z = player:getHandcardNum(), to:getHandcardNum(), 0
    if x > y then
      z = math.min(5, x) - y
      if z > 0 then
        room:drawCards(to, z, zhengu.name)
      end
    elseif x < y then
      z = y - x
      room:askToDiscard(to, {
        min_num = z,
        max_num = z,
        include_equip = false,
        skill_name = zhengu.name,
        cancelable = false,
      })
    end
  end,
})
zhengu:addEffect(fk.TurnEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target.dead or player.dead then return end
    if table.contains(target:getTableMark("@@zhengu"), player.id) then
      local x, y = player:getHandcardNum(), target:getHandcardNum()
      return x < y or (x > y and y < 5)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player, { target })
    local x, y, z = player:getHandcardNum(), target:getHandcardNum(), 0
    if x > y then
      z = math.min(5, x) - y
      if z > 0 then
        room:drawCards(target, z, zhengu.name)
      end
    elseif x < y then
      z = y - x
      room:askToDiscard(target, {
        min_num = z,
        max_num = z,
        include_equip = false,
        skill_name = zhengu.name,
        cancelable = false,
      })
    end
  end,
})
zhengu:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@zhengu") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@zhengu", 0)
  end,
})

zhengu:addAI(Fk.Ltk.AI.newChoosePlayersStrategy{
  choose_players = function(self, ai)
    return ai:askToChoosePlayers({
      targets = ai:getEnabledTargets(),
      min_num = 0,
      max_num = 1,
      skill_name = self.skill_name,
      benefit_func = function (logic, p)
        local x, y, z = ai.player:getHandcardNum(), p:getHandcardNum(), 0
        if x > y then
          z = math.min(5, x) - y
          if z > 0 then
            logic:drawCards(p, z, zhengu.name)
          end
        elseif x < y then
          z = y - x
          logic:throwCard(table.random(p:getCardIds("h"), z), self.skill_name, p, p)
        end

        --延时效果
        if ai.player:getHandcardNum() ~= p:getMaxCards() then
          x, y, z = ai.player:getHandcardNum(), p:getMaxCards(), 0
          if x > y then
            z = math.min(5, x) - y
            if z > 0 then
              logic:drawCards(p, z, zhengu.name)
            end
          elseif x < y then
            z = y - x
            logic:throwCard(table.random(p:getCardIds("h"), z), self.skill_name, p, p)
          end
        end
      end,
    })
  end,
})

return zhengu
