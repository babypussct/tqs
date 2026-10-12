local neiji = fk.CreateSkill {
  name = "heg__neiji",
}

Fk:loadTranslationTable {
  ["heg__neiji"] = "内忌",
  [":heg__neiji"] = "出牌阶段开始时，你可以选择一名其他势力角色，与其同时展示两张手牌，若如此做，你与其依次弃置以此法展示的【杀】，" ..
      "若以此法弃置【杀】的数量：大于1，你与其各摸三张牌；为1，以此法未弃置【杀】的角色视为对以此法弃置【杀】的角色使用一张【决斗】。",

  ["#heg__neiji-choose"] = "内忌：选择一名其他角色，你与其同时展示两张手牌",
  ["#heg__neiji_showcards"] = "内忌：展示两张手牌",
}

local H = require "packages.hegemony.util"

neiji:addEffect(fk.EventPhaseStart, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    local targets = table.filter(player.room:getOtherPlayers(player, true),
    function(p) return #p:getCardIds("h") > 1 and (not H.compareKingdomWith(p, player) or p.kingdom == "unknown")
    end)
    return target == player and player:hasSkill(neiji.name) and player.phase == Player.Play and
    #player:getCardIds("h") > 1 and #targets > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, true), function(p)
      return #p:getCardIds("h") > 1 and
      (not H.compareKingdomWith(p, player) or p.kingdom == "unknown")
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      skill_name = neiji.name,
      prompt = "#heg__neiji-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local targets = { player, to } ---@type ServerPlayer[]
    local result = room:askToJointCards(player, {
      players = targets,
      min_num = 2,
      max_num = 2,
      include_equip = false,
      skill_name = neiji.name,
      cancelable = false,
      prompt = "#heg__neiji_showcards",
    })
    local slash_player = {}
    local slash_to = {}
    for _, p in ipairs(targets) do
      p:showCards(result[p])
      for _, c in ipairs(result[p]) do
        local card = Fk:getCardById(c)
        if card.trueName == "slash" then
          table.insert(p == player and slash_player or slash_to, c)
          room:throwCard(c, neiji.name, p, p)
        end
      end
    end
    if player.dead or to.dead then return end
    room:delay(300)
    local num = #slash_player + #slash_to
    if num > 1 then
      player:drawCards(3, neiji.name)
      to:drawCards(3, neiji.name)
    end
    if num == 1 then
      if #slash_player > 0 and #slash_to == 0 and to:canUseTo(Fk:cloneCard("duel"), player) then
        room:useVirtualCard("duel", nil, to, player, neiji.name, true)
      elseif #slash_to > 0 and #slash_player == 0 and player:canUseTo(Fk:cloneCard("duel"), to) then
        room:useVirtualCard("duel", nil, player, to, neiji.name, true)
      end
    end
  end,
})

return neiji
