local zhaoran = fk.CreateSkill{
  name = "heg__zhaoran",
}

Fk:loadTranslationTable{
  ["heg__zhaoran"] = "昭然",
  [":heg__zhaoran"] = "出牌阶段开始前，你可以摸X张牌（X为4-场上势力数），然后未确定势力的角色可以明置一张武将牌，令你结束此回合。",

  ["#heg__zhaoran-ask"] = "昭然：是否明置一张武将牌，令 %src 结束此回合？",

  ["$heg__zhaoran1"] = "行昭然于世，赦众贼以威。",
  ["$heg__zhaoran2"] = "吾之心思，路人皆知。",
}

local H = require "packages.hegemony.util"

zhaoran:addEffect(fk.EventPhaseChanging, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(zhaoran.name) and
      data.phase == Player.Play and not data.skipped then
      local n = 0
      for _, _ in pairs(H.getKingdomPlayersNum(player.room)) do
        n = n + 1
      end
      return n < 4
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, _ in pairs(H.getKingdomPlayersNum(room)) do
      n = n + 1
    end
    if n > 3 then return end
    player:drawCards(4 - n, zhaoran.name)
    if player.dead then return end
    for _, p in ipairs(room:getAlivePlayers()) do
      if not p.dead and p.kingdom == "unknown" and
      H.askToRevealGenerals(p, {
        skill_name = zhaoran.name,
        prompt = "#heg__zhaoran-ask:"..player.id,
        revealAll = false,
      }) ~= "Cancel" then
        data.skipped = true
        room:endTurn()
        break
      end
    end
  end,
})

zhaoran:addTest(function(room, me)
  local comp2 = room.players[2]
end)

return zhaoran

