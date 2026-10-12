local xiongzhi = fk.CreateSkill{
  name = "xiongzhi",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["xiongzhi"] = "雄志",
  [":xiongzhi"] = "限定技，出牌阶段，你可以观看牌堆顶的牌并使用之，重复至不能被使用（使用【杀】有次数限制）。",

  ["#xiongzhi"] = "雄志：你可以重复展示牌堆顶牌并使用之（有次数限制）",
  ["#xiongzhi-use"] = "雄志：你可以使用这张牌",

  ["$xiongzhi1"] = "烈士雄心，志存高远。",
  ["$xiongzhi2"] = "乱世之中，唯我司马。",
}

xiongzhi:addEffect("active", {
  anim_type = "offensive",
  prompt = "#xiongzhi",
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(xiongzhi.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    while not player.dead do
      local cards = room:getNCards(1)
      if not room:askToUseRealCard(player, {
        pattern = cards,
        skill_name = xiongzhi.name,
        prompt = "#xiongzhi-use",
        extra_data = {
          bypass_times = false,
          extraUse = false,
          expand_pile = cards,
        }
      }) then
        break
      end
    end
  end,
})

return xiongzhi
