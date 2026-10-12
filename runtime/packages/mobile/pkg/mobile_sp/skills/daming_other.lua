local damingOther = fk.CreateSkill {
  name = "daming_other&",
}

Fk:loadTranslationTable{
  ["daming_other&"] = "达命",
  [":daming_other&"] = "出牌阶段限一次，你可以交给彭羕一张牌，然后其选择另一名其他角色。若该角色有相同类型的牌，则该角色须交给你一张相同类型的牌且" ..
  "彭羕获得1点“达命”值，否则彭羕将获得的牌交还给你。",

  ["#daming-choose"] = "达命：选择一名其他角色，若其有%arg，则须交给%dest一张%arg且你获得1点“达命”值，否则你将%arg2交给%dest",
  ["#daming-give"] = "达命：你须交给%dest一张%arg",
  ["#daming_other"] = "达命：你可以交给有“达命”的角色一张牌，令其选择其他角色交给你同类型牌",

}

local changeDaming = function (player, n)
  local room = player.room
  local mark = type(player:getMark("@daming")) == "string" and 0 or player:getMark("@daming")
  mark = mark + n
  room:setPlayerMark(player, "@daming", mark == 0 and "0" or mark)
end

damingOther:addEffect("active", {
  prompt = "#daming_other",
  mute = true,
  can_use = function(self, player)
    if player:usedSkillTimes(damingOther.name, Player.HistoryPhase) < 1 and not player:isNude() then
      return table.find(Fk:currentRoom().alive_players, function(p) return p:hasSkill("daming") and p ~= player end)
    end
  end,
  card_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  target_num = 1,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select:hasSkill("daming") and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local damingName = "daming"
    local player = effect.from
    local py = effect.tos[1]
    room:notifySkillInvoked(py, damingName)
    py:broadcastSkillInvoke(damingName)
    local get = effect.cards[1]
    local cardType = Fk:getCardById(get):getTypeString()
    room:obtainCard(py, get, false, fk.ReasonGive, player, damingName)

    local targets = room:getOtherPlayers(py)
    table.removeOne(targets, player)
    if #targets > 0 then
      local tos = room:askToChoosePlayers(
        py,
        {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = "#daming-choose::" .. player.id .. ":" .. cardType .. ":" .. Fk:getCardById(get):toLogString(),
          skill_name = damingName,
          cancelable = false,
        }
      )
      local to = tos[1]
      if table.find(to:getCardIds("he"), function(id) return Fk:getCardById(id):getTypeString() == cardType end) then
        local give = room:askToCards(
          to,
          {
            min_num = 1,
            max_num = 1,
            skill_name = damingName,
            cancelable = false,
            pattern = ".|.|.|.|.|" .. cardType,
            include_equip = true,
            prompt = "#daming-give::" .. player.id .. ":" .. cardType,
          }
        )
        if #give > 0 and player:isAlive() then
          py:broadcastSkillInvoke(damingName)
          room:obtainCard(player, give[1], false, fk.ReasonGive, to, damingName)
          changeDaming(py, 1)
          return false
        end
      end
    end
    if table.contains(py:getCardIds("he"), get) and player:isAlive() then
      room:obtainCard(player, get, false, fk.ReasonGive, py, damingName)
    end
  end,
})

return damingOther
