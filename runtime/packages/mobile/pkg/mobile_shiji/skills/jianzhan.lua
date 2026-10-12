local jianzhan = fk.CreateSkill {
  name = "jianzhan",
}

Fk:loadTranslationTable{
  ["jianzhan"] = "谏战",
  [":jianzhan"] = "出牌阶段限一次，你可以令一名其他角色选择一项：1.视为其对攻击范围内你选择的另一名手牌少于其的角色使用一张【杀】；2.你摸一张牌。",

  ["#jianzhan"] = "谏战：令一名角色选择：视为对你指定的另一名角色使用【杀】，或你摸一张牌",
  ["#jianzhan-choose"] = "谏战：选择 %dest 视为使用【杀】的目标",
  ["jianzhan_slash"] = "视为对%dest使用【杀】",
  ["jianzhan_draw"] = "%src摸一张牌",

  ["$jianzhan1"] = "若能迎天子以兴兵讨贼，大业可成。",
  ["$jianzhan2"] = "明公乃当世之雄，谁可匹敌？",
}

jianzhan:addEffect("active", {
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#jianzhan",
  can_use = function(self, player)
    return player:usedSkillTimes(jianzhan.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local targets = table.filter(room:getOtherPlayers(target, false), function(p)
      return target:inMyAttackRange(p) and target:getHandcardNum() > p:getHandcardNum() and
        target:canUseTo(Fk:cloneCard("slash"), p, {bypass_times = true})
    end)
    if #targets == 0 then
      player:drawCards(1, jianzhan.name)
    else
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = jianzhan.name,
        prompt = "#jianzhan-choose::"..target.id,
        cancelable = false,
        no_indicate = true,
      })[1]
      room:doIndicate(target, {to})
      local choice = room:askToChoice(target, {
        choices = {"jianzhan_slash::"..to.id, "jianzhan_draw:"..player.id},
        skill_name = jianzhan.name,
      })
      if choice:startsWith("jianzhan_draw") then
        player:drawCards(1, jianzhan.name)
      else
        room:useVirtualCard("slash", nil, target, to, jianzhan.name, true)
      end
    end
  end,
})

return jianzhan
