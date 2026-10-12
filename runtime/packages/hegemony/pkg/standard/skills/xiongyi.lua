
local xiongyi = fk.CreateSkill{
  name = "xiongyi",
  tags = {Skill.Limited},
}
local H = require "packages.hegemony.util"
xiongyi:addEffect("active", {
  anim_type = "drawcard",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(xiongyi.name, Player.HistoryGame) == 0
  end,
  -- max_game_use_time = 1,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local targets = table.filter(room:getAlivePlayers(), function(p) return H.compareKingdomWith(p, player) end)
    for _, p in ipairs(targets) do
      if not p.dead then
        p:drawCards(3, xiongyi.name)
      end
    end
    if player.dead or player.kingdom == "unknown" then return false end
    local kingdomMapper = H.getKingdomPlayersNum(room)
    local num = kingdomMapper[H.getKingdom(player)]
    for _, n in pairs(kingdomMapper) do
      if n < num then return false end
    end
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = xiongyi.name
      })
    end
  end,
})

xiongyi:addTest(function (room, me)
  FkTest.setNextReplies(me, {
    json.encode {
      card = { skill = xiongyi.name, subcards = {} },
    },
    "",
  })
  FkTest.runInRoom(function()
    room:handleAddLoseSkills(me, xiongyi.name)
    GameEvent.Turn:create(TurnData:new(me, "game_rule", { Player.Play })):exec()
  end)
  lu.assertEquals(me:getHandcardNum(), 3)
  local nextSame = table.find(room.alive_players, function(p) return p ~= me and H.compareKingdomWith(p, me) end)
  if nextSame then lu.assertEquals(nextSame:getHandcardNum(), 3) end
  lu.assertEvalToFalse(Fk.skills[xiongyi.name]:canUse(me))
end)

Fk:loadTranslationTable{
  ["xiongyi"] = "雄异",
  [":xiongyi"] = "限定技，出牌阶段，你可令与你势力相同的所有角色各摸三张牌，然后若你的势力角色数为全场最少，你回复1点体力。",

  ["$xiongyi1"] = "弟兄们，我们的机会来啦！",
  ["$xiongyi2"] = "此时不战，更待何时！",
}

return xiongyi
