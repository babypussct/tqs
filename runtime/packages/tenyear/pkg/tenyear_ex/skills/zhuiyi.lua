local zhuiyi = fk.CreateSkill {
  name = "ty_ex__zhuiyi",
}

Fk:loadTranslationTable{
  ["ty_ex__zhuiyi"] = "追忆",
  [":ty_ex__zhuiyi"] = "当你死亡时，可以令一名其他角色（杀死你的角色除外）摸X张牌（X为存活角色数）并回复1点体力。",

  ["#ty_ex__zhuiyi-choose"] = "追忆：你可以令一名角色摸%arg张牌并回复1点体力",

  ["$ty_ex__zhuiyi1"] = "别后庭中树，相思几度攀。",
  ["$ty_ex__zhuiyi2"] = "空馀宫阙恨，因此寄相思。",
}

zhuiyi:addEffect(fk.Death, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhuiyi.name, false, true) and
      table.find(player.room.alive_players, function (p)
        return p ~= data.killer
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.simpleClone(room.alive_players)
    table.removeOne(targets, data.killer)
    local to = room:askToChoosePlayers(player, {
      skill_name = zhuiyi.name,
      min_num = 1,
      max_num = 1,
      targets = targets,
      prompt = "#ty_ex__zhuiyi-choose:::"..#room.alive_players,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    to:drawCards(#room.alive_players, zhuiyi.name)
    if to:isWounded() and not to.dead then
      room:recover{
        who = to,
        num = 1,
        recoverBy = player,
        skillName = zhuiyi.name,
      }
    end
  end,
})

zhuiyi:addAI(Fk.Ltk.AI.newChoosePlayersStrategy{
  choose_players = function(self, ai)
    return ai:askToChoosePlayers({
      targets = ai:getEnabledTargets(),
      min_num = 0,
      max_num = 1,
      skill_name = self.skill_name,
      benefit_func = function (logic, p)
        logic:drawCards(p, #ai.room.alive_players)
        logic:recover{
          who = p,
          num = 1,
          recoverBy = ai.player,
          skillName = self.skill_name,
        }
      end,
    })
  end,
})

return zhuiyi
