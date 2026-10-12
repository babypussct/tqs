local zhengdi = fk.CreateSkill{
  name = "os__zhengdi",
}

Fk:loadTranslationTable{
  ["os__zhengdi"] = "争嫡", -- 原文適，与今规范不符
  [":os__zhengdi"] = "①游戏开始时，你令两名其他角色获得〖隽嗣〗。②有〖隽嗣〗的角色死亡后或首轮开始时，若你有〖隽嗣〗，你可以令一名"..
    "角色因〖隽嗣〗摸牌数+1或-1，或弃牌数+1或-1。",

  ["#os__zhengdi-add"] = "争嫡：选择两名其他角色获得〖隽嗣〗",
  ["#os__zhengdi-alter"] = "争嫡：可以令一名角色因〖隽嗣〗摸牌数或弃牌数+1或-1",
  ["os__zhengdi_draw_plus"] = "%dest因〖隽嗣〗摸牌数+1",
  ["os__zhengdi_draw_minus"] = "%dest因〖隽嗣〗摸牌数-1",
  ["os__zhengdi_discard_plus"] = "%dest因〖隽嗣〗弃牌数+1",
  ["os__zhengdi_discard_minus"] = "%dest因〖隽嗣〗弃牌数-1",

  ["$os__zhengdi1"] = "身陷王侯之门，自然有此一遭。",
  ["$os__zhengdi2"] = "世子之位，非我莫属！",
  ["$os__zhengdi3"] = "哈哈哈哈，一步之遥，可成吾业！",
}

zhengdi:addEffect(fk.GameStart, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p) return not p:hasSkill("os__junsi", true) end)
    if #targets > 2 then
      targets = room:askToChoosePlayers(player, {
        skill_name = self.name,
        prompt = "#os__zhengdi-add",
        targets = targets,
        min_num = 2,
        max_num = 2,
        cancelable = false,
      })
    end
    room:sortByAction(targets)
    event:setCostData(self, {tos = targets})
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name, "special")
    player:broadcastSkillInvoke(zhengdi.name, 1)
    local targets = event:getCostData(self).tos
    for _, p in ipairs(targets) do
      room:handleAddLoseSkills(p, "os__junsi")
    end
  end
})

-- 标记上直接显示牌数，因此对初始0的处理要用string存储标记。初始0->1
local processMark = function (value)
  if value == 0 then return 1 end
  return tonumber(value)
end

local zhengd_spec = {
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p) return p:hasSkill("os__junsi", true) end)
    if #targets > 0 then
      targets = room:askToChoosePlayers(player, {
        skill_name = self.name,
        prompt = "#os__zhengdi-alter",
        targets = targets,
        min_num = 1,
        max_num = 1,
        cancelable = true,
      })
      if #targets > 0 then
        event:setCostData(self, {tos = targets})
        return true
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local to = event:getCostData(self).tos[1]
    local room = player.room
    room:notifySkillInvoked(player, self.name, "special")
    player:broadcastSkillInvoke(zhengdi.name, table.every(Fk:currentRoom().alive_players, function(p) return
      p == player or not p:hasSkill(self.name, true)
    end) and 3 or 2)
    local choices = {"os__zhengdi_draw_plus::" .. to.id, "os__zhengdi_draw_minus::" .. to.id,
        "os__zhengdi_discard_plus::" .. to.id, "os__zhengdi_discard_minus::" .. to.id}
    local all_choices = table.simpleClone(choices)
    local markName = ""
    for i = 0, 1, 1 do
      markName = "@os__junsi" .. i -- 0 draw; 1 discard
      if processMark(to:getMark(markName)) == 0 then -- 已经0了不能减
        table.remove(choices, i == 0 and 2 or nil)
      end
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = self.name,
      all_choices = all_choices,
    })
    local index = table.indexOf(all_choices, choice)
    markName = "@os__junsi" .. index // 3
    local record = processMark(to:getMark(markName)) + 2 * (index % 2) - 1
    room:setPlayerMark(to, markName, tostring(record))
  end
}
zhengdi:addEffect(fk.RoundStart, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(self.name) and player.room:getBanner("RoundCount") == 1 and player:hasSkill("os__junsi", true)
  end,
  on_cost = zhengd_spec.on_cost,
  on_use = zhengd_spec.on_use,
})
zhengdi:addEffect(fk.Deathed, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return target:hasSkill("os__junsi", true, true) and player:hasSkill(self.name)
  end,
  on_cost = zhengd_spec.on_cost,
  on_use = zhengd_spec.on_use,
})

return zhengdi
