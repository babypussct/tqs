
local xiaoben = fk.CreateSkill {
  name = "xiaoben",
  tags = { Skill.Combo },
}

Fk:loadTranslationTable{
  ["xiaoben"] = "骁贲",
  [":xiaoben"] = "连招技（伤害牌+非基本牌）你可以移动一个“骑”并可以移除所有其他角色的“骑”，其他角色每失去一个“骑”便受到1点伤害。",

  ["@@xiaoben"] = "骁贲 +非基本牌",
  ["#xiaoben-invoke"] = "骁贲：是否移动一个“骑”，然后可以移除“骑”造成伤害",
  ["#xiaoben-damage"] = "骁贲：是否移除所有其他角色的“骑”并造成伤害？",

  ["$xiaoben1"] = "羌风卷朔雪，铁骑到处，春风不须度！",
  ["$xiaoben2"] = "天下惊蛟已起，我当伏波山河！",
}

xiaoben:addAuxActiveSkill("#xiaoben_active", {
  card_num = 0,
  target_num = 2,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      return to_select:getMark("@heqim") > 0
    else
      return #selected == 1
    end
  end,
})

xiaoben:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return
      data.from == player and
      data.card.type ~= Card.TypeBasic and
      player:hasSkill(xiaoben.name) and
      (data.extra_data or {}).combo_skill and
      data.extra_data.combo_skill[xiaoben.name] and
      #player.room.alive_players > 1 and
      not table.every(
        player.room.alive_players,
        function(p)
          return p:getMark("@heqim") == 0
        end
      )
  end,
  on_cost = function(self, event, target, player, data)
    local success, dat = player.room:askToUseActiveSkill(player, {
      skill_name = "#xiaoben_active",
      prompt = "#xiaoben-invoke",
      cancelable = true,
    })
    if success and dat then
      event:setCostData(self, { tos = dat.targets })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = xiaoben.name
    local room = player.room
    room:setPlayerMark(player, "@@xiaoben", 0)
    local tos = event:getCostData(self).tos or {}
    room:removePlayerMark(tos[1], "@heqim", 1)
    room:addPlayerMark(tos[2], "@heqim", 1)
    tos = table.filter(room:getAlivePlayers(), function(p)
      return p ~= player and p:getMark("@heqim") > 0
    end)
    if #tos > 0 and room:askToSkillInvoke(player, {
      skill_name = skillName,
      prompt = "#xiaoben-damage",
    }) then
      for _, p in ipairs(tos) do
        if p:isAlive() then
          local x = p:getMark("@heqim")
          if x > 0 then
            room:setPlayerMark(p, "@heqim", 0)
            room:damage{
              from = player,
              to = p,
              damage = x,
              skillName = xiaoben.name,
            }
          end
        end
      end
    end
  end,
})

xiaoben:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(xiaoben.name, true)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if player:getMark("@@xiaoben") > 0 and data.card.type ~= Card.TypeBasic then
      data.extra_data = data.extra_data or {}
      data.extra_data.combo_skill = data.extra_data.combo_skill or {}
      data.extra_data.combo_skill[xiaoben.name] = true
    end
    if data.card.is_damage_card then
      room:setPlayerMark(player, "@@xiaoben", 1)
    else
      room:setPlayerMark(player, "@@xiaoben", 0)
    end
  end,
})

xiaoben:addLoseEffect(function (self, player)
  player.room:setPlayerMark(player, "@@xiaoben", 0)
end)

return xiaoben
