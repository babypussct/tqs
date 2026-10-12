local osWuhun = fk.CreateSkill {
  name = "os__wuhun",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__wuhun"] = "武魂",
  [":os__wuhun"] = "锁定技，①当你受到1点伤害后，伤害来源获得1枚“梦魇”。②当你对有“梦魇”的角色造成伤害后，其获得1枚“梦魇”。" ..
  "③当你死亡时，你可判定：若结果不为【桃】或【桃园结义】，你选择至少一名有“梦魇”的角色，这些角色失去X点体力（X为其“梦魇”数）。",

  ["@os__nightmare"] = "梦魇",
  ["os__wuhun_judge"] = "判定，若结果不为【桃】或【桃园结义】，你选择至少一名有“梦魇”的角色失去X点体力（X为其“梦魇”数）",
  ["#os__wuhun-targets"] = "武魂：选择至少一名有“梦魇”的角色，各失去X点体力（X为其“梦魇”数）",

  ["$os__wuhun1"] = "追你到天涯海角！",
  ["$os__wuhun2"] = "我看你怎么跑！",
}

osWuhun:addEffect(fk.Damaged, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(osWuhun.name) and data.from and data.from:isAlive()
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(data.from, "@os__nightmare", data.damage)
  end,
})

osWuhun:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(osWuhun.name) and
      data.to and
      data.to:getMark("@os__nightmare") > 0 and
      data.to:isAlive()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(data.to, "@os__nightmare")
  end,
})

osWuhun:addEffect(fk.Death, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(osWuhun.name, false, true) then
      return table.find(player.room:getOtherPlayers(player, false), function(p)
        return p:getMark("@os__nightmare") > 0
      end)
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osWuhun.name
    local room = player.room
    if
      room:askToChoice(
        player,
        {
          choices = { "os__wuhun_judge", "Cancel" },
          skill_name = skillName,
        }
      ) == "os__wuhun_judge"
    then
      local judge = {
        who = player,
        reason = skillName,
        pattern = "peach,god_salvation|.",
      }
      room:judge(judge)
      if judge.card.name == "peach" or judge.card.name == "god_salvation" then
        return false
      end

      local availableTargets = table.filter(player.room:getOtherPlayers(player, false), function(p)
        return p:getMark("@os__nightmare") > 0
      end)
      if #availableTargets == 0 then
        return false
      end

      local targets = room:askToChoosePlayers(
        player,
        {
          targets = availableTargets,
          min_num = 1,
          max_num = #availableTargets,
          prompt = "#os__wuhun-targets",
          skill_name = skillName,
          cancelable = false,
        }
      )
      if #targets > 0 then
        room:sortByAction(targets)
        for _, p in ipairs(targets) do
          room:loseHp(p, p:getMark("@os__nightmare"), skillName)
        end
      end
    end
  end,
})

return osWuhun
