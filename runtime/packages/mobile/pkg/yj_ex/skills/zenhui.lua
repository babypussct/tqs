local zenhui = fk.CreateSkill{
  name = "m_ex__zenhui",
}

Fk:loadTranslationTable{
  ["m_ex__zenhui"] = "谮毁",
  [":m_ex__zenhui"] = "出牌阶段限一次，当你使用【杀】或黑色普通锦囊牌指定一名角色为唯一目标时，"..
  "你可以选择另一名能成为此牌合法目标的角色，并选择：1.获得该角色的一张牌，然后其代替你成为此牌的使用者；2.令其也成为此牌的目标。",

  ["#m_ex__zenhui-choose"] = "谮毁：选择一名能成为%arg的目标的角色",
  ["@m_ex__zenhui-choice"] = "谮毁：选择一项令%dest执行",
  ["m_ex__zenhui_becomeuser"] = "获得其一张牌并令其成为使用者",
  ["m_ex__zenhui_becometarget"] = "令其也成为此牌的目标",

  ["$m_ex__zenhui1"] = "本公主说你忤逆，岂能有假？",
  ["$m_ex__zenhui2"] = "不用挣扎了，你们谁都逃不了！",
}

zenhui:addEffect(fk.TargetSpecifying, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return data.from == player and player:hasSkill(zenhui.name) and player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 and
      (data.card.trueName == "slash" or (data.card.color == Card.Black and data.card:isCommonTrick())) and data.firstTarget and
      #data.use.tos == 1 and #data:getExtraTargets({bypass_times = true}) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      targets = data:getExtraTargets({bypass_times = true}),
      min_num = 1,
      max_num = 1,
      prompt = "#m_ex__zenhui-choose:::"..data.card:toLogString(),
      skill_name = zenhui.name,
      cancelable = true,
      no_indicate = true
    })
    if #tos > 0 then
      local to = tos[1]
      local choices = {"m_ex__zenhui_becometarget::" .. to.id, "Cancel"}
      if not to:isNude() then
        table.insert(choices, "m_ex__zenhui_becomeuser::" .. to.id)
      end
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = zenhui.name,
        prompt = "@m_ex__zenhui-choice::" .. to.id,
        all_choices = {"m_ex__zenhui_becomeuser::" .. to.id, "m_ex__zenhui_becometarget::" .. to.id, "Cancel"}
      })
      if choice == "Cancel" then return false end
      event:setCostData(self, {tos = tos, choice = choice:split(":")[1]})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choice = event:getCostData(self).choice
    if choice:startsWith("m_ex__zenhui_becomeuser") then
      room:notifySkillInvoked(player, zenhui.name, "control", {to.id})
      player:broadcastSkillInvoke(zenhui.name, 1)
      local card = room:askToChooseCard(player, {
        target = to,
        flag = "he",
        skill_name = zenhui.name
      })
      room:obtainCard(player, card, false, fk.ReasonPrey, player, zenhui.name)
      data.from = to
      target = to
    else
      room:notifySkillInvoked(player, zenhui.name, "offensive", {to.id})
      player:broadcastSkillInvoke(zenhui.name, 2)
      data:addTarget(to)
    end
  end,
})

return zenhui
