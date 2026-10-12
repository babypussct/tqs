local osJiexun = fk.CreateSkill {
  name = "os__jiexun"
}

Fk:loadTranslationTable{
  ["os__jiexun"] = "诫训",
  [":os__jiexun"] = "1级：结束阶段，你可选择一名其他角色并选择一种花色，令其摸场上此花色牌数张牌，" ..
  "然后其弃置X张牌（X为此技能发动过的次数）。若其以此法弃置了所有牌，你选择一项：1. 摸X张牌，然后重置X为0；" ..
  "2. 升级〖复难〗和〖诫训〗。<br/>2级：结束阶段，你可选择一种花色，令一名其他角色摸场上此花色牌数张牌，然后其弃置X张牌（X为此技能升级前的X）。",

  ["#os__jiexun-target"] = "诫训：选择一种花色，令一名角色摸场上此花色数张牌",
  ["@os__jiexun_update"] = "诫训2级",
  ["@os__jiexun"] = "诫训",
  ["#os__jiexun-suit"] = "诫训：选择一种花色，令 %src 摸场上此花色牌数张牌，然后其弃置%arg张牌",
  ["os__jiexun_draw"] = "摸%arg张牌，重置〖诫训〗次数",
  ["os__jiexun_update"] = "升级〖复难〗和〖诫训〗",
  ["@@os__funan_update"] = "复难2级",

  ["$os__jiexun1"] = "帝王应以社稷为重，以大观为主。",
  ["$os__jiexun2"] = "吾冒昧进谏，只求陛下思虑。",
}

osJiexun:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(osJiexun.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    ---@type string
    local skillName = osJiexun.name
    local room = player.room
    local tos = room:askToChoosePlayers(
      player,
      {
        targets = room:getOtherPlayers(player, false),
        min_num = 1,
        max_num = 1,
        prompt = "#os__jiexun-target",
        skill_name = skillName,
      }
    )
    if #tos > 0 then
      local card_suits = { "log_spade", "log_club", "log_heart", "log_diamond" }
      local num = player:getMark("@os__jiexun_update") == 0 and
        player:getMark("@os__jiexun") or
        player:getMark("@os__jiexun_update")
      local choice = room:askToChoice(
        player,
        {
          choices = card_suits,
          skill_name = skillName,
          prompt = "#os__jiexun-suit:" .. tos[1].id .. "::" .. tostring(num),
        }
      )
      event:setCostData(self, { tos[1], table.indexOf(card_suits, choice) })
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osJiexun.name
    local room = player.room
    local to = event:getCostData(self)[1]
    local suit = event:getCostData(self)[2]
    local num = 0
    for _, p in ipairs(player.room.alive_players) do
      num = num + #table.filter(p:getCardIds("ej"), function(id)
        return Fk:getCardById(id).suit == suit
      end)
    end
    if num > 0 then
      room:drawCards(to, num, skillName)
    end
    num = player:getMark("@os__jiexun_update") == 0 and player:getMark("@os__jiexun") or player:getMark("@os__jiexun_update")
    if num > 0 then
      room:askToDiscard(
        to,
        {
          min_num = num,
          max_num = num,
          include_equip = true,
          skill_name = skillName,
          cancelable = false,
        }
      )
    end
    if player:getMark("@os__jiexun_update") == 0 then
      room:addPlayerMark(player, "@os__jiexun")
      if num > 0 and to:isNude() then
        local choice = room:askToChoice(
          player,
          {
            choices = { "os__jiexun_draw:::" .. num, "os__jiexun_update" },
            skill_name = skillName,
          }
        )
        if choice == "os__jiexun_update" then
          room:setPlayerMark(player, "@@os__funan_update", 1)
          room:setPlayerMark(player, "@os__jiexun_update", num)
          room:setPlayerMark(player, "@os__jiexun", 0)
        else
          player:drawCards(num, skillName)
          room:setPlayerMark(player, "@os__jiexun", 0)
        end
      end
    end
  end,
})

return osJiexun
