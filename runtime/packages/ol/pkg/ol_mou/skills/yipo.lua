local yipo = fk.CreateSkill{
  name = "yipo",
}

Fk:loadTranslationTable{
  ["yipo"] = "毅魄",
  [":yipo"] = "当你的体力值变化后，若当前体力值大于0且为本局游戏首次变化到，你可以选择一名角色并选择一项：1.其摸X张牌，然后弃置一张牌；"..
  "2.其摸一张牌，然后弃置X张牌。（X为你已损失体力值，至少为1）",

  ["#yipo1-invoke"] = "毅魄：你可以令一名角色摸一张牌然后弃一张牌",
  ["#yipo-invoke"] = "毅魄：你可以令一名角色：摸%arg张牌然后弃一张牌，或摸一张牌然后弃%arg张牌",
  ["#yipo-choice"] = "毅魄：选择令 %dest 执行的一项",
  ["#yipo-draw"] = "摸%arg张牌，弃一张牌",
  ["#yipo-discard"] = "摸一张牌，弃%arg张牌",

  ["$yipo1"] = "乱臣贼子，天地不容。",
  ["$yipo2"] = "年少束发从羽林，纵死不改报国志。",
  ["$yipo3"] = "身既死兮神以灵，魂魄毅兮为鬼雄！",
}

local yipoSpec = {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    if data.num == 0 or player ~= target or player.hp < 1 or not player:hasSkill(yipo.name) then return false end
    local mark = player:getTableMark(yipo.name)
    local eid = player.room.logic:getCurrentEvent().id
    if mark[tostring(player.hp)] then
      return mark[tostring(player.hp)] == eid
    else
      mark[tostring(player.hp)] = eid
      player.room:setPlayerMark(player, yipo.name, mark)
      return true
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local n = math.max(player:getLostHp(), 1)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = yipo.name,
      prompt = n == 1 and "#yipo1-invoke" or "#yipo-invoke:::"..n,
      cancelable = true,
    })
    if #to > 0 then
      room:addTableMarkIfNeed(player, yipo.name, player.hp)
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local n = math.max(player:getLostHp(), 1)
    local choices = {"#yipo-draw:::" .. n,  "#yipo-discard:::" .. n}
    local choice = (n == 1) and choices[1] or room:askToChoice(player, {
      choices = choices,
      skill_name = yipo.name,
      prompt = "#yipo-choice::"..to.id,
    })
    if choice:startsWith("#yipo-draw") then
      to:drawCards(n, yipo.name)
      if not to.dead then
        room:askToDiscard(to, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = yipo.name,
          cancelable = false,
        })
      end
    else
      to:drawCards(1, yipo.name)
      if not to.dead then
        room:askToDiscard(to, {
          min_num = n,
          max_num = n,
          include_equip = true,
          skill_name = yipo.name,
          cancelable = false,
        })
      end
    end
  end,
}

yipo:addEffect(fk.Damaged, yipoSpec)

yipo:addEffect(fk.HpLost, yipoSpec)

yipo:addEffect(fk.HpRecover, yipoSpec)

yipo:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, yipo.name, 0)
end)

return yipo
