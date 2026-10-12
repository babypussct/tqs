local huaiyi = fk.CreateSkill {
  name = "ld__huaiyi",
}

Fk:loadTranslationTable {
  ["ld__huaiyi"] = "怀异",
  [":ld__huaiyi"] = "出牌阶段限一次，你可展示所有手牌，若其中包含两种颜色，则你弃置其中一种颜色的牌，然后获得至多X名角色的各一张牌" ..
      "（X为你以此法弃置的手牌数）。你将以此法获得的装备牌置于武将牌上，称为“异”。",

  ["#ld__huaiyi-active"] = "发动 怀异，展示所有手牌，然后选择一种颜色弃置",
  ["#ld__huaiyi-choose"] = "怀异：你可以获得至多%arg名角色各一张牌",
  ["ld__gongsunyuan_infidelity"] = "异",

  ["$ld__huaiyi1"] = "曹魏可王，吾亦可王！",
  ["$ld__huaiyi2"] = "这天下，本就是我囊中之物。",
}

huaiyi:addEffect("active", {
  prompt = "#ld__huaiyi-active",
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(huaiyi.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local cards = player.player_cards[Player.Hand]
    player:showCards(cards)
    local colors = {}
    for _, id in ipairs(cards) do
      table.insertIfNeed(colors, Fk:getCardById(id):getColorString())
    end
    if #colors < 2 then return end
    local color = room:askToChoice(player, { choices = colors, skill_name = huaiyi.name })
    local throw = {}
    for _, id in ipairs(cards) do
      if Fk:getCardById(id):getColorString() == color then
        table.insert(throw, id)
      end
    end
    room:throwCard(throw, huaiyi.name, player, player)
    local targets = room:askToChoosePlayers(player, {
      targets = table.filter(room:getOtherPlayers(player, false), function(p) return not p:isNude() end),
      min_num = 1,
      max_num = #throw,
      prompt = "#ld__huaiyi-choose:::" .. tostring(#throw),
      skill_name = huaiyi.name,
      cancelable = true,
    })
    if #targets > 0 then
      room:sortByAction(targets)
      for _, pid in ipairs(targets) do
        if player.dead then break end
        local target = pid
        if target.dead or target:isNude() then
        else
          local id = room:askToChooseCard(player, {
            target = target,
            flag = "he",
            skill_name = huaiyi.name,
          })
          if Fk:getCardById(id).type == Card.TypeEquip then
            player:addToPile("ld__gongsunyuan_infidelity", id, true, huaiyi.name)
          else
            room:obtainCard(player, id, false, fk.ReasonPrey)
          end
        end
      end
    end
  end,
})

return huaiyi
