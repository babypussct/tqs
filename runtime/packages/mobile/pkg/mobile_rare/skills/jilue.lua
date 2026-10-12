
local jilue = fk.CreateSkill {
  name = "mobile__jilue",
  related_skills = { "guicai", "jizhi", "fangzhu", "zhiheng", "wansha" },
}

Fk:loadTranslationTable{
  ["mobile__jilue"] = "极略",
  [":mobile__jilue"] = "当你获得此技能时，你获得〖鬼才〗，然后根据你的势力获得对应技能：<br>魏〖放逐〗；蜀〖集智〗；吴〖制衡〗；群〖完杀〗。<br>"..
  "出牌阶段开始时，你可以选择一项：1.移去X枚“忍”标记，选择并获得一项你未拥有的“极略”中的技能" ..
  "（X为你选择过此项的次数+1，且至少为2）；2.移去至多两枚“忍”标记，然后摸等量的牌。",

  ["mobile__jilue_skill"] = "移去%arg枚“忍”标记，获得一项极略技能",
  ["mobile__jilue_draw"] = "移去至多两枚“忍”标记，摸等量的牌",
  ["$mobile__jilue1"] = "三分一统，天下归一！",
  ["$mobile__jilue2"] = "大权独揽，朝野皆平！",

  ["$guicai_mobile__godsimayi"] = "天地造化，不过老夫一念之间！",
  ["$fangzhu_mobile__godsimayi"] = "此非老夫不仁，实乃汝咎由自取！",
  ["$jizhi_mobile__godsimayi"] = "一策一划，皆为成吾之远图！",
  ["$zhiheng_mobile__godsimayi"] = "轮回不止，因果不休！",
  ["$wansha_mobile__godsimayi"] = "连诛其族，翦其党羽，以夷后患！",
}

jilue:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jilue.name) and player.phase == Player.Play and
      player:getMark("@mobile__renjie_ren") > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local cost = math.max(player:getMark("mobile__jilue_option1") + 1, 2)
    local optionOne = "mobile__jilue_skill:::" .. cost
    local choices = { "mobile__jilue_draw", "Cancel" }

    local skills = table.filter(jilue.related_skills, function(s)
      return not player:hasSkill(s, true)
    end)
    if player:getMark("@mobile__renjie_ren") >= cost and #skills > 0
    then
      table.insert(choices, 1, optionOne)
    end

    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = jilue.name,
      all_choices = {
        optionOne,
        "mobile__jilue_draw",
        "Cancel",
      }})
    if choice == "Cancel" then
      return false
    elseif choice == "mobile__jilue_draw" then
      if player:getMark("@mobile__renjie_ren") > 1 then
        choice = room:askToChoice(player, {
          choices = { "1", "2" },
          skill_name = jilue.name
        })
      else
        choice = "1"
      end
      choice = "mobile__jilue_draw:"..choice
    else
      choice = room:askToChoice(player, {
        choices = skills,
        skill_name = jilue.name,
      })
      choice = "mobile__jilue_skill:" .. choice
    end
    event:setCostData(self, {choice = choice})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice:startsWith("mobile__jilue_skill") then
      room:removePlayerMark(player, "@mobile__renjie_ren", math.max(player:getMark("mobile__jilue_option1") + 1, 2))
      room:addPlayerMark(player, "mobile__jilue_option1")
      room:handleAddLoseSkills(player, choice:split(":")[2])
    else
      local cost = tonumber(choice:split(":")[2]) ---@type integer
      room:removePlayerMark(player, "@mobile__renjie_ren", cost)
      player:drawCards(cost, jilue.name)
    end
  end,
})
jilue:addEffect(fk.EventAcquireSkill, {
  can_trigger = function (self, event, target, player, data)
    return target == player and data.skill.name == jilue.name
  end,
  on_trigger = function (self, event, target, player, data)
    local toAcquire = "guicai"
    local kingdom = player.kingdom
    if kingdom == "wei" then
      toAcquire = toAcquire .. "|fangzhu"
    elseif kingdom == "shu" then
      toAcquire = toAcquire .. "|jizhi"
    elseif kingdom == "wu" then
      toAcquire = toAcquire .. "|zhiheng"
    elseif kingdom == "qun" then
      toAcquire = toAcquire .. "|wansha"
    end
    player.room:handleAddLoseSkills(player, toAcquire)
  end,
})

return jilue
