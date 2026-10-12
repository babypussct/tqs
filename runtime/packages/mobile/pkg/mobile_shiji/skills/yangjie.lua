local yangjie = fk.CreateSkill {
  name = "yangjie",
}

Fk:loadTranslationTable{
  ["yangjie"] = "佯解",
  [":yangjie"] = "出牌阶段限一次，你可以与一名角色拼点。若你没赢，你可以令另一名其他角色视为对与你拼点的角色使用一张无距离限制的火【杀】。",

  ["#yangjie"] = "佯解：你可以拼点，若没赢，你可以令另一名角色视为对拼点角色使用火【杀】",
  ["#yangjie-choose"] = "佯解：你可以选择一名角色，视为其对 %dest 使用火【杀】",

  ["$yangjie1"] = "全军彻围，待其出城迎敌，再攻敌自散矣！",
  ["$yangjie2"] = "佯解敌围，而后城外击之，此为易破之道！",
}

yangjie:addEffect("active", {
  anim_type = "offensive",
  prompt = "#yangjie",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(yangjie.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and player:canPindian(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local pindian = player:pindian({target}, yangjie.name)
    if pindian.results[target].winner ~= player and not player.dead and not target.dead then
      local slash = Fk:cloneCard("fire__slash")
      slash.skillName = yangjie.name
      local targets = table.filter(room.alive_players, function (p)
        return p ~= player and p ~= target and p:canUseTo(slash, target, {bypass_distances = true, bypass_times = true})
      end)
      if #targets == 0 then return end
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = yangjie.name,
        prompt = "#yangjie-choose::"..target.id,
        cancelable = true,
      })
      if #to > 0 then
        room:useVirtualCard("fire__slash", nil, to[1], target, yangjie.name, true)
      end
    end
  end,
})

return yangjie
