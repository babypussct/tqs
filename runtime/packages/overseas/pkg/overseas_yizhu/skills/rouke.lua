local rouke = fk.CreateSkill {
  name = "os__rouke",
}

Fk:loadTranslationTable{
  ["os__rouke"] = "柔克",
  [":os__rouke"] = "当你成为其他角色使用的伤害类牌的目标后，若其本回合已造成过伤害，你可以令此牌无效并与其各摸一张牌；"..
  "若其本轮因此技能摸牌数大于你的体力值，此技能与其非锁定技本轮失效。",

  ["#os__rouke-invoke"] = "柔克：是否令此%arg无效，与 %dest 各摸一张牌？",
  ["@@os__rouke-round"] = "非锁定技失效",

  ["$os__rouke1"] = "宽以待人，柔能克刚，则英雄莫敌。",
  ["$os__rouke2"] = "务崇宽惠，顺天命以行诛。",
}

rouke:addEffect(fk.TargetConfirmed, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(rouke.name) and
      data.card.is_damage_card and data.from ~= player and
      #player.room.logic:getActualDamageEvents(1, function (e)
        return e.data.from == data.from
      end, Player.HistoryTurn) > 0
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = rouke.name,
      prompt = "#os__rouke-invoke::"..data.from.id..":"..data.card:toLogString(),
    }) then
      event:setCostData(self, { tos = {data.from} })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.use.nullifiedTargets = table.simpleClone(room.players)
    player:drawCards(1, rouke.name)
    if not data.from.dead then
      room:addPlayerMark(data.from, "os__rouke_count-round", 1)
      local yes = data.from:getMark("os__rouke_count-round") > player.hp
      data.from:drawCards(1, rouke.name)
      if yes then
        if not player.dead then
          room:invalidateSkill(player, rouke.name, "-round")
        end
        if not data.from.dead then
          room:addPlayerMark(data.from, MarkEnum.UncompulsoryInvalidity.."-round", 1)
          room:setPlayerMark(data.from, "@@os__rouke-round", 1)
        end
      end
    end
  end,
})

return rouke
