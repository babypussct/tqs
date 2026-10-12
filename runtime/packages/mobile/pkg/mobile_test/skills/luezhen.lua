local luezhen = fk.CreateSkill {
  name = "luezhen",
}

Fk:loadTranslationTable{
  ["luezhen"] = "掠阵",
  [":luezhen"] = "出牌阶段开始时，你可以令所有其他角色依次选择一项：1.展示X张手牌（X为其选择过此项的次数+1）；" ..
  "2.令你视为对其使用一张不计入次数且无距离次数限制的【杀】。",

  ["#luezhen-invoke"] = "掠阵：你可令所有其他角色依次选择展示手牌或视为你对其使用【杀】",
  ["#luezhen-display"] = "掠阵：请展示%arg张手牌，否则视为 %src 对你使用【杀】",

  ["$luezhen1"] = "哼，曹操万军，吾视之如草芥！",
  ["$luezhen2"] = "吾当亲率兵马，掠阵斩此逆贼。",
}

luezhen:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player.phase == Player.Play and
      player:hasSkill(luezhen.name) and
      table.find(player.room.alive_players, function(p) return p ~= player end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player.room:askToSkillInvoke(player, { skill_name =  luezhen.name, prompt = "#luezhen-invoke" }) then
      event:setCostData(self, { tos = room:getOtherPlayers(player) })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = luezhen.name
    local room = player.room

    table.forEach(room:getOtherPlayers(player), function(p)
      if p:isAlive() then
        local num = p:getMark("luezhen_1_chosen-noclear") + 1
        local ids = {}
        if not p:isKongcheng() then
          ids = room:askToCards(
            p,
            {
              min_num = num,
              max_num = num,
              skill_name = luezhen.name,
              prompt = "#luezhen-display:" .. player.id .. "::" .. num,
            }
          )

          if #ids == num then
            room:addPlayerMark(p, "luezhen_1_chosen-noclear")
            p:showCards(ids)
          end
        end

        if #ids ~= num then
          room:useVirtualCard("slash", nil, player, p, skillName, true)
        end
      end
    end)
  end,
})

return luezhen
