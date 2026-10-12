local buyi = fk.CreateSkill{
  name = "ld__buyi",
}
local H = require "packages.hegemony.util"
buyi:addEffect(fk.AfterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(buyi.name) and player:usedSkillTimes(buyi.name, Player.HistoryTurn) == 0 and target and not target.dead and
    H.compareKingdomWith(target, player) and data.damage and data.damage.from and not data.damage.from.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = buyi.name,
      prompt = "#ld__buyi-ask:" .. target.id .. ":" .. data.damage.from.id,
    }) then
      event:setCostData(self, {tos = {data.damage.from}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:doIndicate(player.id, {data.damage.from.id})
    if not H.askToCommand(player, { tos = { data.damage.from }, skill_name = buyi.name }) then
      player.room:recover({
        who = target,
        num = 1,
        recoverBy = player,
        skillName = buyi.name,
      })
    end
  end,
})

Fk:loadTranslationTable{
  ['ld__buyi'] = '补益',
  [':ld__buyi'] = '每回合限一次，当与你势力相同的角色的濒死结算后，若其存活，你可对伤害来源发起“军令”。若来源不执行，则你令该角色回复1点体力。',

  ["#ld__buyi-ask"] = "补益：你可对 %dest 发起军令。若来源不执行，则 %src 回复1点体力",

  ["$ld__buyi1"] = "有我在，定保贤婿无余！",
  ["$ld__buyi2"] = "东吴，岂容汝等儿戏！",
}

return buyi
