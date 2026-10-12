local zhengjun = fk.CreateSkill {
  name = "zhengjun",
}

Fk:loadTranslationTable{
  ["zhengjun"] = "整军",
  [":zhengjun"] = "出牌阶段开始时，你可以进行“<a href='zhengsu_desc'>整肃</a>”，弃牌阶段结束后，若“<a href='zhengsu_desc'>整肃</a>”成功，"..
  "你获得“<a href='zhengsu_desc'>整肃</a>”奖励，然后你可以令一名其他角色也获得“<a href='zhengsu_desc'>整肃</a>”奖励。",

  ["#zhengjun-invoke"] = "整军：你可以进行“整肃”，若成功，则弃牌阶段结束后获得奖励，且可以令一名其他角色获得奖励",
  ["#zhengjun-choice"] = "整军：选择你本回合“整肃”的条件",
  ["#zhengjun-reward"] = "整军：“整肃”成功，选择一项整肃奖励",
  ["#zhengjun-choose"] = "整军：你可以令一名其他角色也获得整肃奖励",
  ["#zhengjun-support"] = "整军：选择 %dest 获得的整肃奖励",

  ["$zhengjun1"] = "众将平日随心，战则务尽死力！",
  ["$zhengjun2"] = "汝等不怀余力，皆有平贼之功！",
  ["$zhengjun3"] = "仁恕之道，终非治军良策！",
}

local U = require "packages.utility.utility"

zhengjun:addEffect(fk.EventPhaseStart, {
  audio_index = 1,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhengjun.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = zhengjun.name,
      prompt = "#zhengjun-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    U.startZhengsu(player, player, zhengjun.name, "#zhengjun-choice")
  end,
})
zhengjun:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  audio_index = 2,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Discard and not player.dead and
      U.checkZhengsu(player, target, zhengjun.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"draw2"}
    if player:isWounded() then
      table.insert(choices, 1, "recover")
    end
    local reward = room:askToChoice(player, {
      choices = choices,
      skill_name = zhengjun.name,
      prompt = "#zhengjun-reward",
      all_choices = {"draw2", "recover"},
    })
    U.rewardZhengsu(player, player, reward, zhengjun.name)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = zhengjun.name,
      prompt = "#zhengjun-choose",
      cancelable = true,
    })
    if #to > 0 then
      to = to[1]
      choices = {"draw2"}
      if to:isWounded() then
        table.insert(choices, 1, "recover")
      end
      reward = room:askToChoice(player, {
        choices = choices,
        skill_name = zhengjun.name,
        prompt = "#zhengjun-support::"..to.id,
        all_choices = {"draw2", "recover"},
      })
      U.rewardZhengsu(player, to, reward, zhengjun.name)
    end
  end,
})

return zhengjun
