local osLinglu = fk.CreateSkill {
  name = "os__linglu"
}

Fk:loadTranslationTable{
  ["os__linglu"] = "令戮",
  [":os__linglu"] = "出牌阶段开始时，你可<a href='os__qiangling_href'>强令</a>一名其他角色在其下回合结束前造成2点伤害。成功：其摸两张牌；失败：其失去1点体力。",

  ["#os__linglu-ask"] = "令戮：你可强令一名其他角色在其下回合结束前造成2点伤害",
  ["os__linglu_twice"] = "令其〖令戮〗的失败结算进行两次",
  ["#os__linglu_twice-ask"] = "令戮：你可令 %src 〖令戮〗的失败结算进行两次",
  ["@os__linglu_twice"] = "令戮2",
  ["@os__linglu"] = "令戮",
}

osLinglu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(osLinglu.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local tos = room:askToChoosePlayers(
      player,
      {
        targets = room:getOtherPlayers(player, false),
        min_num = 1,
        max_num = 1,
        prompt = "#os__linglu-ask",
        skill_name = osLinglu.name,
      }
    )
    if #tos > 0 then
      event:setCostData(self, tos[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    ---@type string
    local skillName = osLinglu.name
    local room = player.room
    local to = event:getCostData(self)
    local mark_name = table.contains(player:getTableMark("_os__linglu_jianshuo"), to.id) and
    room:askToChoice(
      player,
      {
        choices = { "os__linglu_twice", "Cancel" },
        skill_name = skillName,
        prompt = "#os__linglu_twice-ask:" .. to.id,
      }
    ) ~= "Cancel" and
    "@os__linglu_twice" or
    "@os__linglu"

    local mark = to:getTableMark(mark_name)
    table.insert(mark, player.general)
    table.insert(mark, 0)
    room:setPlayerMark(to, mark_name, mark)
    mark_name = string.sub(mark_name, 2)
    room:addTableMark(to, mark_name, player.id)
  end
})

osLinglu:addEffect(fk.Damage, {
  can_refresh = function(self, event, target, player)
    return target == player and (player:getMark("@os__linglu") ~= 0 or player:getMark("@os__linglu_twice") ~= 0)
  end,
  on_refresh = function(self, event, target, player, data)
    local mark_names = { "@os__linglu", "@os__linglu_twice" }
    local room = player.room
    for _, mark_name in ipairs(mark_names) do
      local mark = player:getTableMark(mark_name)
      for i = 2, #mark, 2 do
        mark[i] = mark[i] + data.damage
      end
      room:setPlayerMark(player, mark_name, mark)
    end
  end
})

osLinglu:addEffect(fk.TurnEnd, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player)
    return target == player and (player:getMark("@os__linglu") ~= 0 or player:getMark("@os__linglu_twice") ~= 0)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    ---@type string
    local skillName = osLinglu.name
    local mark_names = { "@os__linglu", "@os__linglu_twice" }
    local room = player.room
    for _, mark_name in ipairs(mark_names) do
      if not player:isAlive() then
        break
      end

      local mark = player:getTableMark(mark_name)
      for i = 2, #mark, 2 do
        if not player:isAlive() then
          break
        end

        room:doIndicate(player:getMark(string.sub(mark_name, 2))[i/2], { player })
        if mark[i] < 2 then
          room:loseHp(player, 1, skillName)
          if mark_name == "@os__linglu_twice" then room:loseHp(player, 1, skillName) end
        else
          player:drawCards(2, skillName)
        end
      end
      room:setPlayerMark(player, mark_name, 0)
      room:setPlayerMark(player, string.sub(mark_name, 2), 0)
    end
  end
})

return osLinglu
