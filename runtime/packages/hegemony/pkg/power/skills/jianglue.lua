local jianglue = fk.CreateSkill{
  name = "jianglue",
  tags = {Skill.Limited},
}
local H = require "packages.hegemony.util"
jianglue:addEffect("active", {
  anim_type = "support",
  can_use = function(self, player)
    return player:usedSkillTimes(jianglue.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local command = H.askToStartCommand(player, {skill_name = jianglue.name})
    local kingdom = H.getKingdom(player)
    for _, p in ipairs(room:getAlivePlayers()) do
      if p.kingdom == "unknown" and p:isAlive() then
        if H.getKingdomPlayersNum(room)[kingdom] >= #room.players // 2 and not table.find(room.alive_players, function(_p) return _p.general == "ld__lordliubei" end) then break end
        local main, deputy = false, false
        if H.compareExpectedKingdomWith(p, player) then
          local general = Fk.generals[p:getMark("__heg_general")]
          main = general.kingdom == kingdom or general.subkingdom == kingdom
          general = Fk.generals[p:getMark("__heg_deputy")]
          deputy = general.kingdom == kingdom or general.subkingdom == kingdom
        end
        local flag = main and "m" or ""
        if deputy then
          flag = flag.. "d"
        end
        H.askToRevealGenerals(p, {
          skill_name = jianglue.name,
          flag = flag,
        })
      end
    end
    local targets = table.filter(room.alive_players, function(p) return H.compareKingdomWith(p, player) and p ~= player end)
    local tos = {} ---@type ServerPlayer[]
    if #targets > 0 then
      local dat = {
        from = player,
        tos = targets,
        command = command,
        skillName = jianglue.name,
        no_indicate = true,
      }
      H.Command(dat)
      table.insertTable(tos, dat.succeed_list)
    end
    table.insert(tos, 1, player)
    local num = 0
    for _, p in ipairs(tos) do
      if p:isAlive() then
        room:changeMaxHp(p, 1)
        if p:isAlive() and p:isWounded() then
          if room:recover({
            who = p,
            num = 1,
            recoverBy = player,
            skillName = jianglue.name
          }) then
            num = num + 1
          end
        end
      end
    end
    if num > 0 then player:drawCards(num, jianglue.name) end
  end
})

Fk:loadTranslationTable{
  ["jianglue"] = "将略",
  [":jianglue"] = "限定技，出牌阶段，你可选择一个“军令”，然后发动势力召唤。你对所有与你势力相同的角色发起此“军令”。你和所有执行“军令”的角色各加1点体力上限，回复1点体力。然后你摸X张牌（X为以此法回复体力的角色数）。",

  ["$jianglue1"] = "奇谋为短，将略为要。",
  ["$jianglue2"] = "为将者，需有谋略。",
}

return jianglue
