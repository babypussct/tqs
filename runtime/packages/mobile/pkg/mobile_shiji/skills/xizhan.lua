local xizhan = fk.CreateSkill {
  name = "xizhan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xizhan"] = "嬉战",
  [":xizhan"] = "锁定技，其他角色回合开始时，你选择一项：<br>1.弃置一张牌并令你本回合〖芳踪〗失效，根据弃置牌的花色执行效果：<br>"..
  "♠，其视为使用【酒】；<br><font color='red'>♥</font>，你视为使用【无中生有】；<br>"..
  "♣，你视为对其使用【铁索连环】；<br><font color='red'>♦</font>，你视为对其使用火【杀】。<br>2.失去1点体力。",

  ["#xizhan-invoke"] = "嬉战：%dest 的回合，弃置一张牌并根据花色执行对应效果，或点“取消”失去1点体力",

  ["$xizhan1"] = "战场纵非玩乐之所，尔等又能奈我何？",
  ["$xizhan2"] = "本姑娘只是戏耍一番，尔等怎下如此重手！",
  ["$xizhan3"] = "哎呀~母亲放心，鬘儿不会捣乱的。",
  ["$xizhan4"] = "嘻嘻，这样才好玩嘛。",
  ["$xizhan5"] = "哼！让你瞧瞧本姑娘的厉害！",
}

xizhan:addEffect(fk.TurnStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(xizhan.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:isNude() then
      room:notifySkillInvoked(player, xizhan.name, "negative")
      player:broadcastSkillInvoke(xizhan.name, 1)
      room:loseHp(player, 1, xizhan.name)
      return
    end
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = xizhan.name,
      cancelable = true,
      prompt = "#xizhan-invoke::"..target.id,
      skip = true,
    })
    if #card > 0 then
      room:invalidateSkill(player, "fangzong", "-turn", xizhan.name)
      local suits = {"spade", "heart", "club", "diamond", "nosuit"}
      local anim_types = {"support", "drawcard", "control", "offensive", "negative"}
      local index = table.indexOf(suits, Fk:getCardById(card[1]):getSuitString())
      room:notifySkillInvoked(player, xizhan.name, anim_types[index])
      if index < 5 then
        player:broadcastSkillInvoke(xizhan.name, index + 1)
      end
      room:throwCard(card, xizhan.name, player, player)
      if player.dead then return end
      if index == 1 then
        room:useVirtualCard("analeptic", nil, target, target, xizhan.name, false)
      elseif index == 2 then
        room:useVirtualCard("ex_nihilo", nil, player, player, xizhan.name, false)
      elseif index == 3 then
        room:useVirtualCard("iron_chain", nil, player, target, xizhan.name, false)
      elseif index == 4 then
        room:useVirtualCard("fire__slash", nil, player, target, xizhan.name, false)
      end
    else
      room:notifySkillInvoked(player, xizhan.name, "negative")
      player:broadcastSkillInvoke(xizhan.name, 1)
      room:loseHp(player, 1, xizhan.name)
    end
  end,
})

return xizhan
