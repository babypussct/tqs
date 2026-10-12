local shelun = fk.CreateSkill {
  name = "m_js__shelun",
  dynamic_desc = function(self, player)
    if Fk:currentRoom():isGameMode("1v2_mode") then
      return "m_js__shelun_1v2"
    else
      return "m_js__shelun_role_mode"
    end
  end,
}

Fk:loadTranslationTable{
  ["m_js__shelun"] = "赦论",
  [":m_js__shelun"] = "出牌阶段限一次，若你有手牌，你可以选择至多两名（若为斗地主模式，则改为一名）你攻击范围内的其他角色，"..
  "然后你令除其外所有手牌数不大于你的角色议事，若结果为：红色，你弃置其各两张牌；黑色，你对其各造成1点伤害。",

  [":m_js__shelun_1v2"] = "出牌阶段限一次，若你有手牌，你可以选择一名你攻击范围内的其他角色，"..
  "然后你令除其外所有手牌数不大于你的角色议事，若结果为：红色，你弃置其各两张牌；黑色，你对其各造成1点伤害。",
  [":m_js__shelun_role_mode"] = "出牌阶段限一次，若你有手牌，你可以选择至多两名你攻击范围内的其他角色，"..
  "然后你令除其外所有手牌数不大于你的角色议事，若结果为：红色，你弃置其各两张牌；黑色，你对其各造成1点伤害。",

  ["#m_js__shelun"] = "赦论：指定%arg名角色，除其外所有手牌数不大于你的角色议事<br>红色：弃置目标两张牌；黑色，对目标造成1点伤害",
  ["#m_js__shelun-discard"] = "赦论：弃置 %dest 两张牌",

  ["$m_js__shelun1"] = "董贼既死，凉州旧部，当有处置！",
  ["$m_js__shelun2"] = "此事甚难定夺，还请诸公共议！",
  ["$m_js__shelun3"] = "此辈何罪？但为其主，不足杀之！	",
  ["$m_js__shelun4"] = "今不屠此逆军，何慰关东义士之心！",
}

local U = require "packages.utility.utility"

shelun:addEffect("active", {
  anim_type = "offensive",
  audio_index = {1, 2},
  prompt = function (self, player, selected_cards, selected_targets)
    return "#m_js__shelun:::"..(Fk:currentRoom():isGameMode("1v2_mode") and 1 or 2)
  end,
  card_num = 0,
  min_target_num = 1,
  max_target_num = 2,
  can_use = function(self, player)
    return player:usedSkillTimes(shelun.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return player:inMyAttackRange(to_select) and
      #selected < (Fk:currentRoom():isGameMode("1v2_mode") and 1 or 2)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local tos = effect.tos
    local targets = table.filter(room:getAlivePlayers(), function(p)
      return not table.contains(tos, p) and not p:isKongcheng() and p:getHandcardNum() <= player:getHandcardNum()
    end)
    room:delay(1500)
    room:doIndicate(player, targets)
    local discussion = U.Discussion(player, targets, shelun.name)
    room:sortByAction(tos)
    if discussion.color == "red" then
      player:broadcastSkillInvoke(shelun.name, 3)
      for _, p in ipairs(tos) do
        if not p.dead and not p:isNude() and not player.dead then
          local cards = room:askToChooseCards(player, {
            target = p,
            min = 2,
            max = 2,
            flag = "he",
            skill_name = shelun.name,
            prompt = "#m_js__shelun-discard::"..p.id,
          })
          room:throwCard(cards, shelun.name, p, player)
        end
      end
    elseif discussion.color == "black" then
      player:broadcastSkillInvoke(shelun.name, 4)
      for _, p in ipairs(tos) do
        if not p.dead then
          room:damage{
            from = player,
            to = p,
            damage = 1,
            skillName = shelun.name,
          }
        end
      end
    end
  end,
})

return shelun
