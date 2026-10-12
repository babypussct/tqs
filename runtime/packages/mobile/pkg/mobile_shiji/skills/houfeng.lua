local houfeng = fk.CreateSkill {
  name = "houfeng",
}

Fk:loadTranslationTable{
  ["houfeng"] = "厚俸",
  [":houfeng"] = "每轮限一次，你攻击范围内一名角色出牌阶段开始时，你可以令其“<a href='zhengsu_desc'>整肃</a>”；"..
  "你与其共同获得“<a href='zhengsu_desc'>整肃</a>”奖励。",

  ["#houfeng-invoke"] = "厚俸：你可令 %dest “整肃”，若成功则你与其获得整肃奖励",
  ["@houfeng-turn"] = "厚俸",
  ["#houfeng-choice"] = "厚俸：为 %dest 选择一项整肃条件",
  ["#houfeng-reward"] = "厚俸：整肃成功，你与 %src 共同执行整肃奖励",

  ["$houfeng1"] = "交汝统领，勿负我望！",
  ["$houfeng2"] = "有功自当行赏，来人呈上！",
  ["$houfeng3"] = "叉出去！罚其二十军杖！",
}

local U = require "packages.utility.utility"

houfeng:addEffect(fk.EventPhaseStart, {
  audio_index = 1,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(houfeng.name) and player:usedEffectTimes(houfeng.name, Player.HistoryRound) == 0 and
      target.phase == Player.Play and not target.dead and player:inMyAttackRange(target)
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = houfeng.name,
      prompt = "#houfeng-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    U.startZhengsu(player, target, houfeng.name, "#houfeng-choice::"..target.id)
    room:setPlayerMark(player, "@houfeng-turn", target.general)
  end,
})
houfeng:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  audio_index = 2,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Discard and not target.dead and not player.dead and
      U.checkZhengsu(player, target, houfeng.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"draw2"}
    if player:isWounded() or (target:isWounded() and not target.dead) then
      table.insert(choices, 1, "recover")
    end
    local reward = room:askToChoice(target, {
      choices = choices,
      skill_name = houfeng.name,
      prompt = "#houfeng-reward:"..player.id,
      all_choices = {"draw2", "recover"},
    })
    U.rewardZhengsu(player, target, reward, houfeng.name)
    if not player.dead then
      U.rewardZhengsu(player, player, reward, houfeng.name)
    end
  end,
})

return houfeng
