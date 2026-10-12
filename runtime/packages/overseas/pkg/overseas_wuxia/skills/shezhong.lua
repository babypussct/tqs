local osShezhong = fk.CreateSkill {
  name = "os__shezhong",
}

Fk:loadTranslationTable{
  ["os__shezhong"] = "慑众",
  [":os__shezhong"] = "结束阶段，你可以依次选择执行以下效果：1.若你本回合对其他角色造成过伤害，" ..
  "你可以令至多X名其他角色下个摸牌阶段的额定摸牌数-1（X为你本回合造成的伤害值）；2.若你本回合受到过伤害，" ..
  "你可以将手牌摸至与其中一名伤害来源的体力值相同（最多摸至5张）。",

  ["#os__shezhong1-target"] = "慑众：你可令至多 %arg 名其他角色下个摸牌阶段的摸牌数-1",
  ["@os__shezhong"] = "慑众",
  ["#os__shezhong2-target"] = "慑众：你可将手牌摸至与其中一名伤害来源的体力值相同（最多摸至5张）",

  ["$os__shezhong1"] = "此乃吾之私怨，与汝等何干？！",
  ["$os__shezhong2"] = "拦吾去路者，下场有如此贼！",
}

osShezhong:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(osShezhong.name) or player.phase ~= Player.Finish then return false end

    return #player.room.logic:getActualDamageEvents(
      1,
      function(e)
        local damage = e.data
        return (damage.from == player and damage.to and damage.to ~= player) or damage.to == player
      end,
      Player.HistoryTurn
    ) > 0
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osShezhong.name
    local room = player.room

    local damagedOthers = false
    local damagePoint = 0
    local sourceList = {}
    room.logic:getActualDamageEvents(
      1,
      function(e)
        local damage = e.data
        if damagedOthers or (damage.from == player and damage.to and damage.to ~= player) then
          damagedOthers = true
        end

        if damage.from == player then
          damagePoint = damagePoint + damage.damage
        end

        if damage.from and damage.to == player then
          table.insertIfNeed(sourceList, damage.from)
        end

        return false
      end,
      Player.HistoryTurn
    )
    if damagedOthers and damagePoint > 0 then
      local victims = room:askToChoosePlayers(
        player,
        {
          targets = room:getOtherPlayers(player, false),
          min_num = 1,
          max_num = damagePoint,
          prompt = "#os__shezhong1-target:::" .. tostring(damagePoint),
          skill_name = skillName,
          cancelable = true
        }
      )
      if #victims > 0 then
        for _, p in ipairs(victims) do
          room:addPlayerMark(p, "@os__shezhong")
        end
      end
    end

    sourceList = table.filter(sourceList, function(p) return p:isAlive() and p.hp > player:getHandcardNum() end)
    if #sourceList > 0 then
      local tos = room:askToChoosePlayers(
        player,
        {
          targets = sourceList,
          min_num = 1,
          max_num = 1,
          prompt = "#os__shezhong2-target",
          skill_name = skillName,
          cancelable = true
        }
      )
      if #tos > 0 then
        local to = tos[1]
        local num = math.min(to.hp, 5) - player:getHandcardNum()
        if num > 0 then player:drawCards(num, skillName) end
      end
    end
  end,
})

osShezhong:addEffect(fk.DrawNCards, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@os__shezhong") > 0 and data.n > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.n = math.max(data.n - player:getMark("@os__shezhong"), 0)
    player.room:setPlayerMark(player, "@os__shezhong", 0)
  end,
})

return osShezhong
