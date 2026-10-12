local yanji = fk.CreateSkill {
  name = "yanji",
}

Fk:loadTranslationTable{
  ["yanji"] = "严纪",
  [":yanji"] = "出牌阶段开始时，你可以进行“<a href='zhengsu_desc'>整肃</a>”。",

  ["#yanji-invoke"] = "严纪：你可以进行“整肃”，若成功，则弃牌阶段结束后获得奖励",
  ["#yanji-choice"] = "严纪：选择你本回合“整肃”的条件",
  ["#yanji-reward"] = "严纪：“整肃”成功，选择一项整肃奖励",

  ["$yanji1"] = "范既典主财计，必律己以率之！",
  ["$yanji2"] = "有财贵于善用，须置军资以崇国防！",
  ["$yanji3"] = "公帑私用？待吾查清定要严惩！",
}

local U = require "packages.utility.utility"

yanji:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yanji.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = yanji.name,
      prompt = "#yanji-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, yanji.name)
    player:broadcastSkillInvoke(yanji.name, math.random(2))
    U.startZhengsu(player, player, yanji.name, "#yanji-choice")
  end,
})
yanji:addEffect(fk.EventPhaseEnd, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Discard and not player.dead and
      U.checkZhengsu(player, target, yanji.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, yanji.name)
    player:broadcastSkillInvoke(yanji.name, math.random(2))
    local choices = {"draw2"}
    if player:isWounded() then
      table.insert(choices, 1, "recover")
    end
    local reward = room:askToChoice(player, {
      choices = choices,
      skill_name = yanji.name,
      prompt = "#yanji-reward",
      all_choices = {"draw2", "recover"},
    })
    U.rewardZhengsu(player, player, reward, yanji.name)
  end,
})

return yanji
