local chongsi = fk.CreateSkill {
  name = "chongsi",
}

Fk:loadTranslationTable{
  ["chongsi"] = "冲司",
  [":chongsi"] = "出牌阶段，若你于此阶段内未选择过最后一项，你可以选择一名其他角色并选择一项，然后其也选择一项：1.使用一张【杀】；" ..
  "2.弃置两张手牌；3.对自己或装备【六龙骖驾】的角色造成1点伤害。",

  ["#chongsi-active"] = "冲司：你可选择一名其他角色，然后与其依次选择选项",
  ["#chongsi-slash"] = "冲司：你可以使用一张【杀】，否则在剩余两项里选择一项",
  ["chongsi_discard"] = "弃置两张牌",
  ["chongsi_damage"] = "对自己或装备六龙骖驾的角色造成1点伤害",
  ["#chongsi-choose"] = "冲司：对自己或装备六龙骖驾的角色造成1点伤害",

  ["$chongsi1"] = "仆夫早严驾，吾行将远游。",
  ["$chongsi2"] = "远游欲何之，吴国为我仇。",
}

chongsi:addEffect("active", {
  prompt = "#chongsi-active",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("chongsi_nullified-phase") == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = chongsi.name
    table.forEach({ effect.from, effect.tos[1] }, function(p)
      if p:isAlive() then
        local use = room:askToUseCard(
          p,
          {
            pattern = "slash",
            skill_name = skillName,
            prompt = "#chongsi-slash",
            extra_data = {
              bypass_times = false,
            }
          }
        )

        if use then
          room:useCard(use)
        else
          local choices = { "chongsi_damage" }
          local canDiscardNum = 0
          for _, id in ipairs(p:getCardIds("h")) do
            if not p:prohibitDiscard(id) then
              canDiscardNum = canDiscardNum + 1
            end

            if canDiscardNum > 1 then
              table.insert(choices, 1, "chongsi_discard")
              break
            end
          end

          local choice = room:askToChoice(
            p,
            {
              choices = choices,
              skill_name = skillName,
              all_choices = { "chongsi_discard", "chongsi_damage" }
            }
          )

          if choice == "chongsi_discard" then
            room:askToDiscard(
              p,
              {
                min_num = 2,
                max_num = 2,
                skill_name = skillName,
                cancelable = false,
              }
            )
          else
            if p == effect.from then
              room:setPlayerMark(p, "chongsi_nullified-phase", 1)
            end

            local targets = table.filter(room.alive_players, function(player)
              return
                player == p or
                table.find(player:getCardIds("e"), function(id)
                  return Fk:getCardById(id).name == "m_liuyi__liulongcanjia"
                end) ~= nil
            end)

            if #targets == 0 then
              return
            end

            local tos = room:askToChoosePlayers(
              p,
              {
                min_num = 1,
                max_num = 1,
                targets = targets,
                skill_name = skillName,
                prompt = "#chongsi-choose",
                cancelable = false,
              }
            )

            room:damage{
              from = p,
              to = tos[1],
              damage = 1,
              skillName = skillName,
            }
          end
        end
      end
    end)
  end,
})

return chongsi
