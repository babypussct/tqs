-- SPDX-License-Identifier: GPL-3.0-or-later
-- Server-only deterministic scenario director for TQS QA.

local config = ServerConfig and ServerConfig.tqsQa
if not config or config.enabled ~= true then
  return nil
end

local function fail(message)
  error("[tqs_qa] " .. message)
end

local function readJson(path)
  local file, err = io.open(path, "r")
  if not file then
    fail("cannot read " .. path .. ": " .. tostring(err))
  end
  local raw = file:read("*a")
  file:close()
  local ok, value = pcall(json.decode, raw)
  if not ok or type(value) ~= "table" then
    fail("invalid JSON: " .. path)
  end
  return value
end

local manifest = readJson("qa_packages/tqs_qa/package.manifest.json")
if manifest.schemaVersion ~= 1 or manifest.package ~= "tqs_qa" or
    manifest.status ~= "verified" or type(manifest.sourceRevision) ~= "string" or
    manifest.sourceRevision == "" or manifest.sourceRevision == "UNRELEASED" or
    type(manifest.catalogSha256) ~= "string" or manifest.catalogSha256 == "" or
    type(manifest.packageSha256) ~= "string" or manifest.packageSha256 == "" then
  fail("refusing to load an unverified package manifest")
end

local catalog = readJson("qa_packages/tqs_qa/catalog.json")
if catalog.schemaVersion ~= 1 or catalog.package ~= "tqs_qa" or
    type(catalog.scenarios) ~= "table" or #catalog.scenarios == 0 then
  fail("invalid scenario catalog")
end

local scenarioById = {}
local function validateDamageExchangeScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("damage-exchange scenarios must define exactly two players")
  end
  for _, role in ipairs({ "actor", "target" }) do
    local player = scenario.players[role]
    if type(player) ~= "table" or type(player.general) ~= "string" or
        type(player.deputy) ~= "string" or type(player.kingdom) ~= "string" then
      fail("damage-exchange scenario has an invalid " .. role .. " roster entry")
    end
  end
  if type(scenario.attackSteps) ~= "table" or #scenario.attackSteps ~= 4 then
    fail("damage-exchange scenario must define four Slash steps")
  end
  for index, step in ipairs(scenario.attackSteps) do
    if type(step.from) ~= "string" or type(step.to) ~= "string" or
        type(step.amount) ~= "number" or step.amount ~= (index == 1 and 0 or 1) or
        type(step.mandatorySkills) ~= "table" or type(step.optionalSkills) ~= "table" or
        type(step.expectedEffect) ~= "string" then
      fail("damage-exchange scenario has an invalid Slash step " .. tostring(index))
    end
    if step.from ~= (index <= 3 and "actor" or "target") or
      step.to ~= (index <= 3 and "target" or "actor") then
      fail("damage-exchange scenario has an invalid attack direction")
    end
    for _, skillName in ipairs(step.mandatorySkills) do
      if skillName == "hs__yiji" or skillName == "fankui" then
        fail("Yiji and Fankui must remain optional")
      end
    end
    for _, skillName in ipairs(step.expectedInvokedSkills or {}) do
      if not table.contains(step.optionalSkills, skillName) then
        fail("selected optional reaction is not declared optional")
      end
    end
  end
end

local function validateHiddenYijiScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-yiji scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local expectedMain = scenario.id == "hidden-yiji-deputy" and "hs__simayi" or "hs__guojia"
  local expectedDeputy = scenario.id == "hidden-yiji-deputy" and "hs__guojia" or "hs__simayi"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "wei" then
    fail("hidden-yiji actor must use the catalogued Quách Gia main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhaoyun" or
      target.deputy ~= "ld__fazheng" or target.kingdom ~= "shu" then
    fail("hidden-yiji target must be Triệu Vân + Pháp Chính in Shu")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-yiji must expose AskForSkillInvoke as its positive/skip proof")
  end
end

local function validateHiddenRehideYijiScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-rehide-yiji scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-rehide-yiji-deputy"
  local expectedMain = deputy and "hs__simayi" or "hs__guojia"
  local expectedDeputy = deputy and "hs__guojia" or "hs__simayi"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "wei" then
    fail("hidden-rehide-yiji actor must use the catalogued Quách Gia main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhaoyun" or
      target.deputy ~= "ld__fazheng" or target.kingdom ~= "shu" then
    fail("hidden-rehide-yiji target must be Triệu Vân + Pháp Chính in Shu")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-rehide-yiji must expose AskForSkillInvoke before the native damage interaction")
  end
  if #scenario.cards ~= 0 then
    fail("hidden-rehide-yiji must not reserve cards; native Di Kế owns the draw/move path")
  end
end

local function validateHiddenJianxiongScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-jianxiong scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-jianxiong-deputy"
  local expectedMain = deputy and "hs__simayi" or "hs__caocao"
  local expectedDeputy = deputy and "hs__caocao" or "hs__simayi"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "wei" then
    fail("hidden-jianxiong actor must use the catalogued Cao Cao main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhaoyun" or
      target.deputy ~= "ld__fazheng" or target.kingdom ~= "shu" then
    fail("hidden-jianxiong target must be Triệu Vân + Pháp Chính in Shu")
  end
  if scenario.expectedCommand ~= "AskForChoices" then
    fail("hidden-jianxiong must expose AskForChoices after the optional invoke")
  end
  if #scenario.cards ~= 1 or type(scenario.cards[1]) ~= "table" or
      scenario.cards[1].key ~= "jianxiong-card" or scenario.cards[1].owner ~= "target" or
      scenario.cards[1].area ~= "hand" or type(scenario.cards[1].match) ~= "table" or
      scenario.cards[1].match.trueName ~= "slash" then
    fail("hidden-jianxiong must reserve exactly one target Slash")
  end
end

local function validateHiddenFankuiScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-fankui scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-fankui-deputy"
  local expectedMain = deputy and "hs__guojia" or "hs__simayi"
  local expectedDeputy = deputy and "hs__simayi" or "hs__guojia"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "wei" then
    fail("hidden-fankui actor must use the catalogued Tư Mã Ý main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhaoyun" or
      target.deputy ~= "ld__fazheng" or target.kingdom ~= "shu" then
    fail("hidden-fankui target must be Triệu Vân + Pháp Chính in Shu")
  end
  if scenario.expectedCommand ~= "AskForCardChosen" then
    fail("hidden-fankui must expose AskForCardChosen after the Damaged trigger")
  end
  if #scenario.cards ~= 2 then
    fail("hidden-fankui must reserve one target Slash and one target Peach")
  end
  local damageCard, lootCard
  for _, card in ipairs(scenario.cards) do
    if card.key == "fankui-damage" and card.owner == "target" and card.area == "hand" and
        type(card.match) == "table" and card.match.trueName == "slash" then
      damageCard = card
    elseif card.key == "fankui-loot" and card.owner == "target" and card.area == "hand" and
        type(card.match) == "table" and card.match.trueName == "peach" then
      lootCard = card
    end
  end
  if not damageCard or not lootCard then
    fail("hidden-fankui must reserve a target Slash and a target Peach")
  end
end

local function validateHiddenKuangguScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-kuanggu scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-kuanggu-deputy"
  local expectedMain = deputy and "hs__huangzhong" or "hs__weiyan"
  local expectedDeputy = deputy and "hs__weiyan" or "hs__huangzhong"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "shu" then
    fail("hidden-kuanggu actor must use the catalogued Wei Yan main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhangliao" or
      target.deputy ~= "hs__xuchu" or target.kingdom ~= "wei" then
    fail("hidden-kuanggu target must be Zhang Liao + Xu Chu in Wei")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-kuanggu must expose AskForSkillInvoke as its prelight gate")
  end
  if #scenario.cards ~= 2 then
    fail("hidden-kuanggu must reserve one actor Slash and one target Peach")
  end
  local actorCard, targetCard
  for _, card in ipairs(scenario.cards) do
    if card.key == "kuanggu-card" and card.owner == "actor" and card.area == "hand" and
        type(card.match) == "table" and card.match.trueName == "slash" then
      actorCard = card
    elseif card.key == "kuanggu-target-card" and card.owner == "target" and card.area == "hand" and
        type(card.match) == "table" and card.match.trueName == "peach" then
      targetCard = card
    end
  end
  if not actorCard or not targetCard then
    fail("hidden-kuanggu must reserve an actor Slash and a target Peach")
  end
end

local function validateHiddenLiegongScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-liegong scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-liegong-deputy"
  local expectedMain = deputy and "hs__zhaoyun" or "hs__huangzhong"
  local expectedDeputy = deputy and "hs__huangzhong" or "hs__zhaoyun"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "shu" then
    fail("hidden-liegong actor must use the catalogued Huang Zhong main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhangliao" or
      target.deputy ~= "hs__xuchu" or target.kingdom ~= "wei" then
    fail("hidden-liegong target must be Zhang Liao + Xu Chu in Wei")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-liegong must expose AskForSkillInvoke as its prelight gate")
  end
  if #scenario.cards ~= 2 then
    fail("hidden-liegong must reserve one actor Slash and one target Peach")
  end
  local actorCard, targetCard
  for _, card in ipairs(scenario.cards) do
    if card.key == "liegong-card" and card.owner == "actor" and card.area == "hand" and
        type(card.match) == "table" and card.match.trueName == "slash" then
      actorCard = card
    elseif card.key == "liegong-target-card" and card.owner == "target" and card.area == "hand" and
        type(card.match) == "table" and card.match.trueName == "peach" then
      targetCard = card
    end
  end
  if not actorCard or not targetCard then
    fail("hidden-liegong must reserve an actor Slash and a target Peach")
  end
end

local function validateHiddenJueqingScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-jueqing scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-jueqing-deputy"
  local expectedMain = deputy and "hs__simayi" or "zhangchunhua"
  local expectedDeputy = deputy and "zhangchunhua" or "hs__simayi"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "wei" then
    fail("hidden-jueqing actor must use the catalogued Zhang Chunhua main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhaoyun" or
      target.deputy ~= "ld__fazheng" or target.kingdom ~= "shu" then
    fail("hidden-jueqing target must be Zhao Yun + Fa Zheng in Shu")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-jueqing must expose AskForSkillInvoke as its prelight gate")
  end
  if #scenario.cards ~= 1 then
    fail("hidden-jueqing must reserve one actor Slash")
  end
  local actorCard
  for _, card in ipairs(scenario.cards) do
    if card.key == "jueqing-card" and card.owner == "actor" and card.area == "hand" and
        type(card.match) == "table" and card.match.trueName == "slash" then
      actorCard = card
    end
  end
  if not actorCard then
    fail("hidden-jueqing must reserve an actor Slash")
  end
end

local function validateHiddenEjueScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-ejue scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-ejue-deputy"
  local expectedMain = deputy and "heg__simayi" or "heg__zhangchunhua"
  local expectedDeputy = deputy and "heg__zhangchunhua" or "heg__simayi"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "jin" then
    fail("hidden-ejue actor must use the catalogued Zhang Chunhua main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhaoyun" or
      target.deputy ~= "ld__fazheng" or target.kingdom ~= "shu" then
    fail("hidden-ejue source must be Zhao Yun + Fa Zheng in Shu before QA marks it unknown")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-ejue must expose AskForSkillInvoke before the DamageCaused Slash")
  end
  if #scenario.cards ~= 1 or type(scenario.cards[1]) ~= "table" or
      scenario.cards[1].key ~= "ejue-card" or scenario.cards[1].owner ~= "actor" or
      scenario.cards[1].area ~= "hand" or type(scenario.cards[1].match) ~= "table" or
      scenario.cards[1].match.trueName ~= "slash" then
    fail("hidden-ejue must reserve exactly one actor Slash")
  end
end

local function validateHiddenRevealScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-reveal scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local expectedMain = scenario.id == "hidden-reveal-deputy" and "hs__sunquan" or "hs__luxun"
  local expectedDeputy = scenario.id == "hidden-reveal-deputy" and "hs__luxun" or "hs__sunquan"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "wu" then
    fail("hidden-reveal actor must use the catalogued Lục Tốn main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhaoyun" or
      target.deputy ~= "ld__fazheng" or target.kingdom ~= "shu" then
    fail("hidden-reveal target must be Triệu Vân + Pháp Chính in Shu")
  end
  if scenario.expectedCommand ~= "AskForUseActiveSkill" then
    fail("hidden-reveal must expose AskForUseActiveSkill as its active reveal proof")
  end
end

local function validateHiddenActiveScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-active scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local expectedMain = scenario.id == "hidden-active-main" and "hs__sunquan" or "hs__luxun"
  local expectedDeputy = scenario.id == "hidden-active-main" and "hs__luxun" or "hs__sunquan"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "wu" then
    fail("hidden-active actor must use the catalogued Tôn Quyền main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhaoyun" or
      target.deputy ~= "ld__fazheng" or target.kingdom ~= "shu" then
    fail("hidden-active target must be Triệu Vân + Pháp Chính in Shu")
  end
  if scenario.expectedCommand ~= "PlayCard" then
    fail("hidden-active must expose a native PlayCard request")
  end
  if #scenario.cards ~= 1 or type(scenario.cards[1]) ~= "table" or
      scenario.cards[1].key ~= "zhiheng-card" or scenario.cards[1].owner ~= "actor" or
      scenario.cards[1].area ~= "hand" or type(scenario.cards[1].match) ~= "table" or
      scenario.cards[1].match.trueName ~= "slash" then
    fail("hidden-active must reserve exactly one actor Slash for Chế Hành")
  end
end

local function validateHiddenFanjianScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-fanjian scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-fanjian-deputy"
  local expectedMain = deputy and "hs__daqiao" or "hs__zhouyu"
  local expectedDeputy = deputy and "hs__zhouyu" or "hs__daqiao"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "wu" then
    fail("hidden-fanjian actor must use the catalogued Chu Du main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhangliao" or
      target.deputy ~= "hs__xuchu" or target.kingdom ~= "wei" then
    fail("hidden-fanjian target must be Zhang Liao + Xu Chu in Wei")
  end
  if scenario.expectedCommand ~= "PlayCard" then
    fail("hidden-fanjian must expose the native PlayCard request")
  end
  if #scenario.cards ~= 2 then
    fail("hidden-fanjian must reserve one actor Peach and one hidden target Jink")
  end
  local actorCard, targetCard
  for _, card in ipairs(scenario.cards) do
    if card.key == "fanjian-card" and card.owner == "actor" and card.area == "hand" and
        type(card.match) == "table" and card.match.trueName == "peach" then
      actorCard = card
    elseif card.key == "fanjian-target-card" and card.owner == "target" and card.area == "hand" and
        type(card.match) == "table" and card.match.trueName == "jink" then
      targetCard = card
    end
  end
  if not actorCard or not targetCard then
    fail("hidden-fanjian must reserve an actor Peach and a target Jink")
  end
end

local function validateHiddenViewAsScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-view-as scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local mainIsZhaoyun = scenario.id == "hidden-view-as-main"
  local expectedMain = mainIsZhaoyun and "hs__zhaoyun" or "hs__guanyu"
  local expectedDeputy = mainIsZhaoyun and "hs__guanyu" or "hs__zhaoyun"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "shu" then
    fail("hidden-view-as actor must use the catalogued Triệu Vân main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__guojia" or
      target.deputy ~= "hs__simayi" or target.kingdom ~= "wei" then
    fail("hidden-view-as target must be Quách Gia + Tư Mã Ý in Wei")
  end
  if scenario.expectedCommand ~= "PlayCard" then
    fail("hidden-view-as must expose a native PlayCard request")
  end
  if #scenario.cards ~= 1 or type(scenario.cards[1]) ~= "table" or
      scenario.cards[1].key ~= "longdan-card" or scenario.cards[1].owner ~= "actor" or
      scenario.cards[1].area ~= "hand" or type(scenario.cards[1].match) ~= "table" or
      scenario.cards[1].match.trueName ~= "jink" then
    fail("hidden-view-as must reserve exactly one actor Jink for Longdan")
  end
end

local function validateHiddenDualScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-dual scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  if type(actor) ~= "table" or actor.general ~= "hs__yanliangwenchou" or
      actor.deputy ~= "hs__yuanshao" or actor.kingdom ~= "qun" then
    fail("hidden-dual actor must use the catalogued Yan Liang/Wen Chou + Yuan Shao pair")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhaoyun" or
      target.deputy ~= "ld__fazheng" or target.kingdom ~= "shu" then
    fail("hidden-dual target must be Triệu Vân + Pháp Chính in Shu")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-dual must expose AskForSkillInvoke as its prelight gate")
  end
  if #scenario.cards ~= 2 then
    fail("hidden-dual must reserve exactly one actor Slash and one target Jink")
  end
  local actorCard, targetCard
  for _, card in ipairs(scenario.cards) do
    if card.key == "shuangxiong-card" and card.owner == "actor" and card.area == "hand" and
        type(card.match) == "table" and card.match.trueName == "slash" and card.match.color == "black" then
      actorCard = card
    elseif card.key == "shuangxiong-discard" and card.owner == "target" and card.area == "hand" and
        type(card.match) == "table" and card.match.trueName == "jink" and card.match.color == "red" then
      targetCard = card
    end
  end
  if not actorCard or not targetCard then
    fail("hidden-dual must reserve a black actor Slash and red target Jink")
  end
end

local function validateHiddenLuoshenScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-luoshen scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-luoshen-deputy"
  local expectedMain = deputy and "hs__simayi" or "hs__zhenji"
  local expectedDeputy = deputy and "hs__zhenji" or "hs__simayi"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "wei" then
    fail("hidden-luoshen actor must use the catalogued Zhen Ji main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhaoyun" or
      target.deputy ~= "ld__fazheng" or target.kingdom ~= "shu" then
    fail("hidden-luoshen target must be Triệu Vân + Pháp Chính in Shu")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-luoshen must expose AskForSkillInvoke as its phase-start proof")
  end
  if #scenario.cards ~= 0 then
    fail("hidden-luoshen must not reserve hand cards; judgment cards come from the native pile")
  end
end

local function validateHiddenTianduScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-tiandu scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-tiandu-deputy"
  local expectedMain = deputy and "hs__simayi" or "hs__guojia"
  local expectedDeputy = deputy and "hs__guojia" or "hs__simayi"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "wei" then
    fail("hidden-tiandu actor must use the catalogued Guo Jia main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhaoyun" or
      target.deputy ~= "ld__fazheng" or target.kingdom ~= "shu" then
    fail("hidden-tiandu target must be Triệu Vân + Pháp Chính in Shu")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-tiandu must expose AskForSkillInvoke as its prelight gate")
  end
  if #scenario.cards ~= 0 then
    fail("hidden-tiandu must not reserve hand cards; the judged card comes from the native pile")
  end
end

local function validateHiddenJizhiScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-jizhi scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-jizhi-deputy"
  local expectedMain = deputy and "hs__zhaoyun" or "hs__huangyueying"
  local expectedDeputy = deputy and "hs__huangyueying" or "hs__zhaoyun"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "shu" then
    fail("hidden-jizhi actor must use the catalogued Huang Yueying main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhangliao" or
      target.deputy ~= "hs__xuchu" or target.kingdom ~= "wei" then
    fail("hidden-jizhi target must be Zhang Liao + Xu Chu in Wei")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-jizhi must expose AskForSkillInvoke for the optional CardUsing effect")
  end
  if #scenario.cards ~= 1 or type(scenario.cards[1]) ~= "table" or
      scenario.cards[1].key ~= "jizhi-card" or scenario.cards[1].owner ~= "actor" or
      scenario.cards[1].area ~= "hand" or type(scenario.cards[1].match) ~= "table" or
      scenario.cards[1].match.trueName ~= "duel" then
    fail("hidden-jizhi must reserve exactly one actor Duel")
  end
end

local function validateHiddenMingshiScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-mingshi scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-mingshi-deputy"
  local expectedMain = deputy and "hs__jiling" or "hs__kongrong"
  local expectedDeputy = deputy and "hs__kongrong" or "hs__jiling"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "qun" then
    fail("hidden-mingshi actor must use the catalogued Kong Rong main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhaoyun" or
      target.deputy ~= "ld__fazheng" or target.kingdom ~= "shu" then
    fail("hidden-mingshi target must be Zhao Yun + Fazheng in Shu")
  end
  if scenario.expectedCommand ~= "PlayCard" then
    fail("hidden-mingshi must expose the native PlayCard damage source request")
  end
  if #scenario.cards ~= 1 or type(scenario.cards[1]) ~= "table" or
      scenario.cards[1].key ~= "mingshi-damage" or scenario.cards[1].owner ~= "target" or
      scenario.cards[1].area ~= "hand" or type(scenario.cards[1].match) ~= "table" or
      scenario.cards[1].match.trueName ~= "slash" then
    fail("hidden-mingshi must reserve exactly one hidden-source Slash")
  end
end

local function validateHiddenGongqingScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-gongqing scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-gongqing-deputy"
  local expectedMain = deputy and "hs__sunquan" or "panjun"
  local expectedDeputy = deputy and "panjun" or "hs__sunquan"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "wu" then
    fail("hidden-gongqing actor must use the catalogued Pan Jun main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhaoyun" or
      target.deputy ~= "ld__fazheng" or target.kingdom ~= "shu" then
    fail("hidden-gongqing source must be Zhao Yun + Fazheng in Shu")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-gongqing must expose AskForSkillInvoke as its prelight gate")
  end
  if #scenario.cards ~= 1 or type(scenario.cards[1]) ~= "table" or
      scenario.cards[1].key ~= "gongqing-bow" or scenario.cards[1].owner ~= "target" or
      scenario.cards[1].area ~= "hand" or type(scenario.cards[1].match) ~= "table" or
      scenario.cards[1].match.name ~= "kylin_bow" then
    fail("hidden-gongqing must reserve exactly one source Kylin Bow in hand")
  end
end

local function validateHiddenEnyuanScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-enyuan scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-enyuan-deputy"
  local expectedMain = deputy and "hs__zhaoyun" or "ld__fazheng"
  local expectedDeputy = deputy and "ld__fazheng" or "hs__zhaoyun"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "shu" then
    fail("hidden-enyuan actor must use the catalogued Fa Zheng main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhangliao" or
      target.deputy ~= "hs__xuchu" or target.kingdom ~= "wei" then
    fail("hidden-enyuan source must be Zhang Liao + Xu Chu in Wei")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-enyuan must expose AskForSkillInvoke as its prelight gate")
  end
  if #scenario.cards ~= 1 or type(scenario.cards[1]) ~= "table" or
      scenario.cards[1].key ~= "enyuan-peach" or scenario.cards[1].owner ~= "target" or
      scenario.cards[1].area ~= "hand" or type(scenario.cards[1].match) ~= "table" or
      scenario.cards[1].match.trueName ~= "peach" then
    fail("hidden-enyuan must reserve exactly one source Peach")
  end
end

local function validateHiddenFuyinScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-fuyin scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-fuyin-deputy"
  local expectedMain = deputy and "hs__zhaoyun" or "zhugezhan"
  local expectedDeputy = deputy and "zhugezhan" or "hs__zhaoyun"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "shu" then
    fail("hidden-fuyin actor must use the catalogued Zhuge Zhan main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhangliao" or
      target.deputy ~= "hs__xuchu" or target.kingdom ~= "wei" then
    fail("hidden-fuyin source must be Zhang Liao + Xu Chu in Wei")
  end
  if scenario.expectedCommand ~= "PlayCard" then
    fail("hidden-fuyin must expose the native PlayCard Slash request")
  end
  if #scenario.cards ~= 1 or type(scenario.cards[1]) ~= "table" or
      scenario.cards[1].key ~= "fuyin-slash" or scenario.cards[1].owner ~= "target" or
      scenario.cards[1].area ~= "hand" or type(scenario.cards[1].match) ~= "table" or
      scenario.cards[1].match.trueName ~= "slash" then
    fail("hidden-fuyin must reserve exactly one source Slash")
  end
end

local function validateHiddenQianxunScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-qianxun scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-qianxun-deputy" or
    scenario.id == "hidden-qianxun-indulgence-deputy"
  local expectedMain = deputy and "hs__sunquan" or "hs__luxun"
  local expectedDeputy = deputy and "hs__luxun" or "hs__sunquan"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "wu" then
    fail("hidden-qianxun actor must use the catalogued Lục Tốn main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhangliao" or
      target.deputy ~= "hs__xuchu" or target.kingdom ~= "wei" then
    fail("hidden-qianxun source must be Zhang Liao + Xu Chu in Wei")
  end
  if scenario.expectedCommand ~= "AskForUseActiveSkill" then
    fail("hidden-qianxun must expose AskForUseActiveSkill for the real Snatch request")
  end
  local indulgenceScenario = scenario.id == "hidden-qianxun-indulgence" or
    scenario.id == "hidden-qianxun-indulgence-deputy"
  if indulgenceScenario then
    if #scenario.cards ~= 1 or type(scenario.cards[1]) ~= "table" or
        scenario.cards[1].key ~= "qianxun-indulgence" or
        scenario.cards[1].owner ~= "target" or scenario.cards[1].area ~= "hand" or
        type(scenario.cards[1].match) ~= "table" or
        scenario.cards[1].match.trueName ~= "indulgence" then
      fail("hidden-qianxun indulgence scenarios must reserve one source Indulgence")
    end
  else
    if #scenario.cards ~= 2 then
      fail("hidden-qianxun must reserve one source Snatch and one actor Peach")
    end
    local snatchCard, victimCard
    for _, card in ipairs(scenario.cards) do
      if card.key == "qianxun-snatch" and card.owner == "target" and card.area == "hand" and
          type(card.match) == "table" and card.match.trueName == "snatch" then
        snatchCard = card
      elseif card.key == "qianxun-victim" and card.owner == "actor" and card.area == "hand" and
          type(card.match) == "table" and card.match.trueName == "peach" then
        victimCard = card
      end
    end
    if not snatchCard or not victimCard then
      fail("hidden-qianxun must reserve a target Snatch and actor Peach")
    end
  end
end

local function validateHiddenKongchengScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-kongcheng scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-kongcheng-deputy"
  local expectedMain = deputy and "hs__zhaoyun" or "hs__zhugeliang"
  local expectedDeputy = deputy and "hs__zhugeliang" or "hs__zhaoyun"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "shu" then
    fail("hidden-kongcheng actor must use the catalogued Zhuge Liang main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhangliao" or
      target.deputy ~= "hs__xuchu" or target.kingdom ~= "wei" then
    fail("hidden-kongcheng source must be Zhang Liao + Xu Chu in Wei")
  end
  if scenario.expectedCommand ~= "AskForUseActiveSkill" then
    fail("hidden-kongcheng must expose AskForUseActiveSkill for the real Duel request")
  end
  if #scenario.cards ~= 1 or type(scenario.cards[1]) ~= "table" or
      scenario.cards[1].key ~= "kongcheng-duel" or scenario.cards[1].owner ~= "target" or
      scenario.cards[1].area ~= "hand" or type(scenario.cards[1].match) ~= "table" or
      scenario.cards[1].match.trueName ~= "duel" then
    fail("hidden-kongcheng must reserve one source Duel")
  end
end

local function validateHiddenWeimuScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-weimu scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-weimu-deputy" or
    scenario.id == "hidden-weimu-indulgence-deputy"
  local indulgenceScenario = scenario.id == "hidden-weimu-indulgence" or
    scenario.id == "hidden-weimu-indulgence-deputy"
  local expectedMain = deputy and "hs__pangde" or "hs__jiaxu"
  local expectedDeputy = deputy and "hs__jiaxu" or "hs__pangde"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "qun" then
    fail("hidden-weimu actor must use the catalogued Jia Xu main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhangliao" or
      target.deputy ~= "hs__xuchu" or target.kingdom ~= "wei" then
    fail("hidden-weimu source must be Zhang Liao + Xu Chu in Wei")
  end
  if scenario.expectedCommand ~= "AskForUseActiveSkill" then
    fail("hidden-weimu must expose AskForUseActiveSkill for the real black Trick request")
  end
  local expectedKey = indulgenceScenario and "weimu-indulgence" or "weimu-duel"
  local expectedTrueName = indulgenceScenario and "indulgence" or "duel"
  if #scenario.cards ~= 1 or type(scenario.cards[1]) ~= "table" or
      scenario.cards[1].key ~= expectedKey or scenario.cards[1].owner ~= "target" or
      scenario.cards[1].area ~= "hand" or type(scenario.cards[1].match) ~= "table" or
      scenario.cards[1].match.trueName ~= expectedTrueName or scenario.cards[1].match.color ~= "black" then
    fail(indulgenceScenario and
      "hidden-weimu indulgence scenarios must reserve one black source Indulgence" or
      "hidden-weimu must reserve one black source Duel")
  end
end

local function validateHiddenXiaojiScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-xiaoji scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-xiaoji-deputy"
  local expectedMain = deputy and "hs__sunquan" or "hs__sunshangxiang"
  local expectedDeputy = deputy and "hs__sunshangxiang" or "hs__sunquan"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "wu" then
    fail("hidden-xiaoji actor must use the catalogued Sun Shangxiang main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhangliao" or
      target.deputy ~= "hs__xuchu" or target.kingdom ~= "wei" then
    fail("hidden-xiaoji source must be Zhang Liao + Xu Chu in Wei")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-xiaoji must expose AskForSkillInvoke for the prelight gate")
  end
  if #scenario.cards ~= 1 or type(scenario.cards[1]) ~= "table" or
      scenario.cards[1].key ~= "xiaoji-equip" or scenario.cards[1].owner ~= "actor" or
      scenario.cards[1].area ~= "equip" or type(scenario.cards[1].match) ~= "table" or
      scenario.cards[1].match.type ~= "equip" then
    fail("hidden-xiaoji must reserve exactly one actor equipment")
  end
end

local function validateHiddenGuanxingScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-guanxing scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-guanxing-deputy"
  local expectedMain = deputy and "hs__zhaoyun" or "hs__zhugeliang"
  local expectedDeputy = deputy and "hs__zhugeliang" or "hs__zhaoyun"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "shu" then
    fail("hidden-guanxing actor must use the catalogued Zhuge Liang main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhangliao" or
      target.deputy ~= "hs__xuchu" or target.kingdom ~= "wei" then
    fail("hidden-guanxing source must be Zhang Liao + Xu Chu in Wei")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-guanxing must expose AskForSkillInvoke before the native arrange request")
  end
  if #scenario.cards ~= 0 then
    fail("hidden-guanxing must let native Guanxing own the top-card selection")
  end
end

local function validateHiddenYingziScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-yingzi scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-yingzi-deputy"
  local expectedMain = deputy and "hs__daqiao" or "hs__zhouyu"
  local expectedDeputy = deputy and "hs__zhouyu" or "hs__daqiao"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "wu" then
    fail("hidden-yingzi actor must use the catalogued Zhou Yu main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhangliao" or
      target.deputy ~= "hs__xuchu" or target.kingdom ~= "wei" then
    fail("hidden-yingzi source must be Zhang Liao + Xu Chu in Wei")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-yingzi must expose AskForSkillInvoke only for the prelight readiness gate")
  end
  if #scenario.cards ~= 0 then
    fail("hidden-yingzi must let the native DrawNCards event own the draw")
  end
end

local function validateHiddenTianxiangScenario(scenario)
  if scenario.playerCount ~= 2 or type(scenario.players) ~= "table" then
    fail("hidden-tianxiang scenarios must define exactly two players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-tianxiang-deputy"
  local expectedMain = deputy and "hs__sunquan" or "hs__xiaoqiao"
  local expectedDeputy = deputy and "hs__xiaoqiao" or "hs__sunquan"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "wu" then
    fail("hidden-tianxiang actor must use the catalogued Xiao Qiao main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__zhangliao" or
      target.deputy ~= "hs__xuchu" or target.kingdom ~= "wei" then
    fail("hidden-tianxiang source must be Zhang Liao + Xu Chu in Wei")
  end
  if scenario.expectedCommand ~= "AskForSkillInvoke" then
    fail("hidden-tianxiang must expose AskForSkillInvoke before its native damage interaction")
  end
  if #scenario.cards ~= 1 or type(scenario.cards[1]) ~= "table" or
      scenario.cards[1].key ~= "tianxiang-heart" or scenario.cards[1].owner ~= "actor" or
      scenario.cards[1].area ~= "hand" or type(scenario.cards[1].match) ~= "table" or
      scenario.cards[1].match.suit ~= "heart" then
    fail("hidden-tianxiang must reserve exactly one actor heart hand card")
  end
end

local function validateHiddenDuanchangScenario(scenario)
  if scenario.playerCount ~= 4 or type(scenario.players) ~= "table" then
    fail("hidden-duanchang scenarios must define exactly four players")
  end
  local actor = scenario.players.actor
  local target = scenario.players.target
  local deputy = scenario.id == "hidden-duanchang-deputy"
  local expectedMain = deputy and "hs__yuanshao" or "hs__caiwenji"
  local expectedDeputy = deputy and "hs__caiwenji" or "hs__yuanshao"
  if type(actor) ~= "table" or actor.general ~= expectedMain or
      actor.deputy ~= expectedDeputy or actor.kingdom ~= "qun" then
    fail("hidden-duanchang actor must use the catalogued Cai Wenji main/deputy placement")
  end
  if type(target) ~= "table" or target.general ~= "hs__caocao" or
      target.deputy ~= "hs__simayi" or target.kingdom ~= "wei" then
    fail("hidden-duanchang killer must be Cao Cao + Sima Yi in Wei")
  end
  if scenario.expectedCommand ~= "AskForChoices" then
    fail("hidden-duanchang must expose AskForChoices for the killer slot choice")
  end
  if #scenario.cards ~= 0 then
    fail("hidden-duanchang must not reserve cards")
  end
end

for _, scenario in ipairs(catalog.scenarios) do
  if type(scenario.id) ~= "string" or scenario.id == "" or scenarioById[scenario.id] or
      type(scenario.seed) ~= "number" or type(scenario.expectedCommand) ~= "string" or
      type(scenario.trigger) ~= "string" or type(scenario.cards) ~= "table" then
    fail("invalid or duplicate scenario catalog entry")
  end
  if scenario.trigger == "damage-exchange" then
    validateDamageExchangeScenario(scenario)
  elseif scenario.trigger == "hidden-yiji" then
    validateHiddenYijiScenario(scenario)
  elseif scenario.trigger == "hidden-rehide-yiji" then
    validateHiddenRehideYijiScenario(scenario)
  elseif scenario.trigger == "hidden-jianxiong" then
    validateHiddenJianxiongScenario(scenario)
  elseif scenario.trigger == "hidden-fankui" then
    validateHiddenFankuiScenario(scenario)
  elseif scenario.trigger == "hidden-kuanggu" then
    validateHiddenKuangguScenario(scenario)
  elseif scenario.trigger == "hidden-liegong" then
    validateHiddenLiegongScenario(scenario)
  elseif scenario.trigger == "hidden-jueqing" then
    validateHiddenJueqingScenario(scenario)
  elseif scenario.trigger == "hidden-ejue" then
    validateHiddenEjueScenario(scenario)
  elseif scenario.trigger == "hidden-reveal" then
    validateHiddenRevealScenario(scenario)
  elseif scenario.trigger == "hidden-active" then
    validateHiddenActiveScenario(scenario)
  elseif scenario.trigger == "hidden-fanjian" then
    validateHiddenFanjianScenario(scenario)
  elseif scenario.trigger == "hidden-view-as" then
    validateHiddenViewAsScenario(scenario)
  elseif scenario.trigger == "hidden-dual" then
    validateHiddenDualScenario(scenario)
  elseif scenario.trigger == "hidden-luoshen" then
    validateHiddenLuoshenScenario(scenario)
  elseif scenario.trigger == "hidden-tiandu" then
    validateHiddenTianduScenario(scenario)
  elseif scenario.trigger == "hidden-jizhi" then
    validateHiddenJizhiScenario(scenario)
  elseif scenario.trigger == "hidden-mingshi" then
    validateHiddenMingshiScenario(scenario)
  elseif scenario.trigger == "hidden-gongqing" then
    validateHiddenGongqingScenario(scenario)
  elseif scenario.trigger == "hidden-enyuan" then
    validateHiddenEnyuanScenario(scenario)
  elseif scenario.trigger == "hidden-fuyin" then
    validateHiddenFuyinScenario(scenario)
  elseif scenario.trigger == "hidden-qianxun" then
    validateHiddenQianxunScenario(scenario)
  elseif scenario.trigger == "hidden-kongcheng" then
    validateHiddenKongchengScenario(scenario)
  elseif scenario.trigger == "hidden-weimu" then
    validateHiddenWeimuScenario(scenario)
  elseif scenario.trigger == "hidden-xiaoji" then
    validateHiddenXiaojiScenario(scenario)
  elseif scenario.trigger == "hidden-guanxing" then
    validateHiddenGuanxingScenario(scenario)
  elseif scenario.trigger == "hidden-yingzi" then
    validateHiddenYingziScenario(scenario)
  elseif scenario.trigger == "hidden-tianxiang" then
    validateHiddenTianxiangScenario(scenario)
  elseif scenario.trigger == "hidden-duanchang" then
    validateHiddenDuanchangScenario(scenario)
  end
  scenarioById[scenario.id] = scenario
end

local allowedUsers = config.allowedUsers
if type(allowedUsers) ~= "table" or #allowedUsers == 0 then
  fail("tqsQa.allowedUsers must contain at least one QA account")
end

local roomPrefix = type(config.roomPrefix) == "string" and config.roomPrefix or "TQSQA/"
local maxPlayers = tonumber(config.maxPlayers) or 4
local maxActiveRooms = tonumber(config.maxActiveRooms) or 1
local maxDurationSeconds = tonumber(config.maxDurationSeconds) or 900
local maxRunsPerProcess = tonumber(config.maxRunsPerProcess) or 50

local extension = Package:new("tqs_qa", Package.SpecialPack)
extension.extensionName = "tqs_qa"

local activeRooms = {}
local totalRuns = 0

local function now()
  return os.time()
end

local function activeRoomCount()
  local count = 0
  for _, state in pairs(activeRooms) do
    if now() - state.startedAt <= maxDurationSeconds then
      count = count + 1
    end
  end
  return count
end

local function parseSeed(value)
  if type(value) ~= "string" or not value:match("^0[xX][0-9a-fA-F]+$") then
    return nil
  end
  return tonumber(value:sub(3), 16)
end

local function parseRequest(room)
  local roomName = room:getSettings("roomName") or ""
  if roomName:sub(1, #roomPrefix) ~= roomPrefix then
    return nil
  end

  local id, seedText = roomName:sub(#roomPrefix + 1):match("^([%w%-]+)/(0[xX][0-9a-fA-F]+)$")
  if not id or not seedText then
    fail("QA room name must be " .. roomPrefix .. "<scenario-id>/<0xseed>")
  end
  local scenario = scenarioById[id]
  if not scenario then
    fail("unknown scenario: " .. id)
  end
  local seed = parseSeed(seedText)
  if not seed or seed ~= scenario.seed then
    fail("seed does not match catalog for scenario " .. id)
  end
  return scenario, seed
end

local function isAllowedUser(name)
  return type(name) == "string" and table.contains(allowedUsers, name)
end

local function assertRoomAllowed(room, scenario)
  if #room.players < 2 then
    fail("scenario " .. scenario.id .. " requires at least two players")
  end
  if scenario.playerCount and #room.players ~= scenario.playerCount then
    fail(string.format("scenario %s requires exactly %d players", scenario.id, scenario.playerCount))
  end
  if #room.players > maxPlayers then
    fail("QA room exceeds maxPlayers")
  end
  for _, player in ipairs(room.players) do
    -- Negative ids are native bots. They inherit the room's QA authorization.
    if player.id > 0 then
      local screenName = player._splayer:getScreenName()
      if not isAllowedUser(screenName) then
        fail("non-allowlisted player attempted to enter a QA room")
      end
    end
  end
  if totalRuns >= maxRunsPerProcess then
    fail("process QA run quota exhausted")
  end
  if activeRoomCount() >= maxActiveRooms then
    fail("active QA room quota exhausted")
  end
end

local function cardMatches(card, matcher)
  if matcher.trueName and card.trueName ~= matcher.trueName then
    return false
  end
  if matcher.name and card.name ~= matcher.name then
    return false
  end
  if matcher.type == "equip" and card.type ~= Card.TypeEquip then
    return false
  end
  if matcher.color and card:getColorString() ~= matcher.color then
    return false
  end
  if matcher.suit and card:getSuitString() ~= matcher.suit then
    return false
  end
  return true
end

local function takeCard(room, matcher, reserved)
  for _, id in ipairs(room.draw_pile) do
    if not reserved[id] and cardMatches(Fk:getCardById(id), matcher) then
      reserved[id] = true
      return id
    end
  end
  fail("catalog card is unavailable in the native draw pile")
end

local function playerForRole(state, owner)
  if owner == "actor" then return state.actor end
  if owner == "target" then return state.target end
  fail("unknown card owner: " .. tostring(owner))
end

local function getGeneral(generalName)
  local general = Fk.generals[generalName]
  if not general then
    fail("catalog general is not installed: " .. generalName)
  end
  return general
end

local function clearInitialFakeSkills(player)
  local seen = {}
  for _, mark in ipairs({ "__heg_general", "__heg_deputy" }) do
    local generalName = player:getMark(mark)
    local general = type(generalName) == "string" and Fk.generals[generalName] or nil
    if general then
      for _, skillName in ipairs(general:getSkillNameList(true)) do
        if not seen[skillName] then
          seen[skillName] = true
          local skill = Fk.skills[skillName]
          if skill and player:isFakeSkill(skill) then
            player:loseFakeSkill(skill)
          end
        end
      end
    end
  end
  local revealSkill = Fk.skills["reveal_skill&"]
  if revealSkill and player:isFakeSkill(revealSkill) then
    player:loseFakeSkill(revealSkill)
  end
end

local function attachGeneralPair(room, player, roster)
  if room:getSettings("gameMode") ~= "new_heg_mode" then
    fail("catalog general injection currently requires new_heg_mode")
  end
  local general = getGeneral(roster.general)
  local deputy = getGeneral(roster.deputy)
  if general.kingdom ~= roster.kingdom then
    fail(string.format("%s is not in the catalog kingdom %s", roster.general, roster.kingdom))
  end
  if deputy.kingdom ~= roster.kingdom then
    fail(string.format("%s is not in the catalog kingdom %s", roster.deputy, roster.kingdom))
  end

  -- Hegemony has already attached the randomly selected pair as fake skills
  -- when GamePrepared fires. Remove those first, otherwise an unrelated
  -- random trigger could make this scenario look like a false positive.
  clearInitialFakeSkills(player)
  room:setPlayerMark(player, "__heg_general", roster.general)
  room:setPlayerMark(player, "__heg_deputy", roster.deputy)
  room:setPlayerMark(player, "__heg_wild", 0)
  room:setPlayerMark(player, "__heg_kingdom", roster.kingdom)
  room:setPlayerMark(player, "__heg_init_kingdom", roster.kingdom)
  room:setPlayerProperty(player, "kingdom", roster.kingdom)
  player.role = roster.kingdom

  local maxHp = (general.maxHp + general.mainMaxHpAdjustedValue +
    deputy.maxHp + deputy.deputyMaxHpAdjustedValue) // 2
  room:setPlayerProperty(player, "maxHp", maxHp)
  room:setPlayerProperty(player, "hp", maxHp)

  local hasCompulsory = false
  local function attachSelectedGeneralSkills(selectedGeneral, isDeputy)
    -- Keep the QA injection identical to HegLogic: a main general cannot
    -- contribute a DeputyPlace-only skill, and vice versa. Without this
    -- filter a deterministic scenario could test a skill that the native
    -- Hegemony setup would never attach to the selected slot.
    local excludedPlace = isDeputy and Skill.MainPlace or Skill.DeputyPlace
    for _, skillName in ipairs(selectedGeneral:getSkillNameList(true)) do
      local skill = Fk.skills[skillName]
      if skill and not skill:hasTag(excludedPlace) then
        room:addFakeSkill(player, skillName)
        if skill:hasTag(Skill.Compulsory) then
          hasCompulsory = true
        end
      end
    end
  end
  attachSelectedGeneralSkills(general, false)
  attachSelectedGeneralSkills(deputy, true)
  if hasCompulsory then
    room:addFakeSkill(player, "reveal_skill&")
  end
end

local function attachGeneral(room, player, generalName)
  local general = getGeneral(generalName)
  if room:getSettings("gameMode") ~= "new_heg_mode" then
    fail("catalog general injection currently requires new_heg_mode")
  end
  room:setPlayerMark(player, "__heg_general", generalName)
  -- Keep the deputy marker selected by the real Hegemony setup. Several
  -- downstream rules read it after GamePrepared; replacing it with numeric 0
  -- would make those rules index a non-existent general.
  room:setPlayerMark(player, "__heg_wild", general.kingdom == "wild" and 1 or 0)
  if general.kingdom == "wild" then
    room:setPlayerMark(player, "__heg_kingdom", "wild")
    room:setPlayerMark(player, "__heg_init_kingdom", "wild")
  end
  for _, skillName in ipairs(general:getSkillNameList(true)) do
    local skill = Fk.skills[skillName]
    if skill and not skill:hasTag(Skill.DeputyPlace) then
      room:addFakeSkill(player, skillName)
    end
  end
end

local function nextRandom(value)
  -- xorshift32, kept in the native Lua layer so the same seed produces the
  -- same deterministic tail order without touching the engine RNG globally.
  value = value ~ ((value << 13) & 0xffffffff)
  value = value ~ (value >> 17)
  value = value ~ ((value << 5) & 0xffffffff)
  return value & 0xffffffff
end

local function shuffleTail(room, seed)
  local value = seed & 0xffffffff
  for index = #room.draw_pile, 2, -1 do
    value = nextRandom(value)
    local swap = (value % index) + 1
    room.draw_pile[index], room.draw_pile[swap] = room.draw_pile[swap], room.draw_pile[index]
  end
  for _, id in ipairs(room.draw_pile) do
    room:setCardArea(id, Card.DrawPile, nil)
  end
  room:syncDrawPile()
end

local function setupCards(room, state, scenario)
  local reserved = {}
  state.fixedHands = {}
  state.deferredHands = {}
  state.slotCards = {}
  for _, spec in ipairs(scenario.cards) do
    local owner = playerForRole(state, spec.owner)
    local id = takeCard(room, spec.match, reserved)
    state.slotCards[spec.key] = id
    if spec.area == "equip" then
      room:moveCardTo(id, Card.PlayerEquip, owner, fk.ReasonJustMove, "tqs_qa", nil, true, owner)
    elseif spec.area == "hand" then
      -- The core's DrawInitialCards fixture path can notify a private hand
      -- card with from=nil/fromArea=Player.Hand.  That is invalid input for
      -- the client known-card tracker (and is especially easy to hit when
      -- the reserved hand belongs to the opponent).  Keep this Jianxiong
      -- card out of the initial draw entirely, then move it into the target
      -- hand through the normal MoveCards path immediately before the real
      -- Slash request.  The gameplay assertion remains the same while the
      -- QA setup no longer fabricates a malformed private-hand move.
      if scenario.trigger == "hidden-jianxiong" and spec.owner == "target" then
        -- Use the normal move path here as well.  Mutating draw_pile/void
        -- directly would leave each client believing this ID is still in
        -- DrawPile, so the later Void -> target-hand move would be ignored
        -- by CardManager:applyMoveInfo on the browser client.
        room:moveCardTo(id, Card.Void, nil, fk.ReasonJustMove, "tqs_qa", nil, false)
        state.deferredHands[spec.key] = id
      else
        state.fixedHands[owner.id] = state.fixedHands[owner.id] or {}
        table.insert(state.fixedHands[owner.id], id)
      end
    else
      fail("unsupported catalog card area: " .. tostring(spec.area))
    end
  end
  if scenario.trigger == "hidden-fuyin" then
    -- 父荫 only nullifies the first Slash when the user's hand is no larger
    -- than the Slash user. The catalogued source Slash is the only card that
    -- must be selected by the browser; add four non-Slash filler cards so the
    -- native source has five cards against the actor's normal four-card hand.
    -- This preserves the real hand-size predicate instead of making the QA
    -- fixture pass by bypassing it.
    local source = playerForRole(state, "target")
    state.fixedHands[source.id] = state.fixedHands[source.id] or {}
    for _ = 1, 4 do
      table.insert(state.fixedHands[source.id], takeCard(room, { trueName = "jink" }, reserved))
    end
  end
end

local function setupState(room, scenario, seed)
  assertRoomAllowed(room, scenario)
  local actor = table.find(room.players, function(player)
    return player.id > 0 and player._splayer:getScreenName() == allowedUsers[1]
  end) or table.find(room.players, function(player) return player.id > 0 end) or room.players[1]
  local target = table.find(room.players, function(player) return player.id ~= actor.id end) or room.players[2]
  local state = {
    scenario = scenario.id,
    seed = seed,
    revision = manifest.sourceRevision,
    startedAt = now(),
    actor = actor,
    target = target,
    skillEffects = {},
    damageResults = {},
    cardEvents = {},
    skillMoves = {},
    damageEvents = {},
    drawEvents = {},
    kuangguBeforeHpChanged = false,
    kuangguDamage = false,
    liegongTargetSpecified = false,
    liegongDamage = false,
    jueqingPreDamage = false,
    hiddenEnyuanTargetConfirmed = false,
    hiddenEnyuanDrawCount = 0,
    hiddenEnyuanDrawCards = {},
    hiddenFuyinTargetConfirmed = false,
    hiddenFuyinNullified = false,
    hiddenEjueDamageCaused = false,
  }
  if scenario.players then
    attachGeneralPair(room, state.actor, scenario.players.actor)
    attachGeneralPair(room, state.target, scenario.players.target)
  elseif scenario.general then
    attachGeneral(room, state.actor, scenario.general)
    if scenario.trigger == "founding" then
      room:setPlayerProperty(state.actor, "kingdom", "wild")
      state.actor.role = "wild"
      room:broadcastProperty(state.actor, "kingdom")
      room:broadcastProperty(state.actor, "role")
    end
  end
  setupCards(room, state, scenario)
  totalRuns = totalRuns + 1
  activeRooms[tostring(room)] = state
  room:setTag("tqs_qa", state)
  fk.qInfo(string.format("[tqs_qa] scenario=%s seed=%u revision=%s players=%d",
    state.scenario, state.seed, state.revision, #room.players))
  return state
end

local function stateFor(room)
  return room:getTag("tqs_qa")
end

local function triggerRescue(room, state)
  local scenario = scenarioById[state.scenario]
  if scenario.trigger == "rescue-battle" then
    local hegUtil = require "packages.hegemony.util"
    hegUtil.enterBattleRoyalMode(room)
  end
  -- This is the native Dying -> AskForPeaches path. The actor's fixed peach
  -- is offered by game_rule to the same client/bot as in a normal match.
  if state.target.hp > 0 then
    room:changeHp(state.target, -state.target.hp, "loseHp", "tqs_qa")
  end
end

local function triggerFounding(room, state)
  -- The Hegemony GeneralShown rule owns the actual AskForChoice request.
  if state.actor:getMark("__heg_wild") == 1 then
    state.actor:revealGeneral(false)
  end
end

local function actualSkillName(skill)
  local skeleton = skill:getSkeleton()
  return skeleton and skeleton.name or skill.name
end

local function isPrelighted(player, skillName)
  return table.find(player.prelighted_skills, function(skill)
    return actualSkillName(skill) == skillName
  end) ~= nil
end

local function recordSkillEffect(state, player, data)
  local triggerEvent = data.skill_data and data.skill_data.trigger_event
  local damage = triggerEvent and triggerEvent.data
  table.insert(state.skillEffects, {
    step = state.currentDamageStep,
    skill = actualSkillName(data.skill),
    player = player.id,
    from = damage and damage.from and damage.from.id or nil,
    to = damage and damage.to and damage.to.id or nil,
    general = player.general,
    deputyGeneral = player.deputyGeneral,
    fake = player:isFakeSkill(data.skill),
  })
end

local function observedSkill(state, step, skillName)
  return table.find(state.skillEffects, function(effect)
    return effect.step == step and effect.skill == skillName
  end) ~= nil
end

local function observedSkills(state, step)
  local names = {}
  for _, effect in ipairs(state.skillEffects) do
    if effect.step == step then
      table.insertIfNeed(names, effect.skill)
    end
  end
  table.sort(names)
  return names
end

local function sendDamageStepLog(room, step, from, to, result, skills)
  room:sendLog{
    type = "[TQS QA] Bước %arg: %from dùng Sát lên %to; SkillEffect: %arg2; kết quả: %arg3",
    from = from.id,
    to = {to.id},
    arg = tostring(step),
    arg2 = table.concat(skills, ", "),
    arg3 = result,
  }
end

local function movedCount(state, step, skillName, from, to)
  local count = 0
  for _, move in ipairs(state.skillMoves) do
    if move.step == step and move.skill == skillName and move.to == to.id and
      (not from or move.from == from.id) then
      count = count + move.count
    end
  end
  return count
end

local function movedFromArea(state, step, skillName, to, area)
  local count = 0
  for _, move in ipairs(state.skillMoves) do
    if move.step == step and move.skill == skillName and move.to == to.id and
        move.fromArea == area then
      count = count + move.count
    end
  end
  return count
end

local function convertedCard(state, step, player, name, material)
  return table.find(state.cardEvents, function(card)
    return card.step == step and card.player == player.id and card.name == name and
      card.longdan and #card.subcards == 1 and card.subcards[1] == material
  end) ~= nil
end

local function runAttackStep(room, state, step)
  local spec = scenarioById[state.scenario].attackSteps[step]
  local from = playerForRole(state, spec.from)
  local to = playerForRole(state, spec.to)
  local fromHp, toHp = from.hp, to.hp
  local fromHand, toHand = #from:getCardIds(Player.Hand), #to:getCardIds(Player.Hand)
  state.currentDamageStep = step

  local extra = { bypass_times = true, bypass_distances = true,
    extraUse = true, exclusive_targets = {to.id}, must_targets = {to.id} }
  local use
  if step <= 3 then
    -- Each attack uses a real hand card and the normal Slash/Jink resolution.
    -- Extra uses belong only to this QA setup; no equipment/hero rule changes.
    use = room:askToUseRealCard(from, {
      pattern = {state.slotCards["actor-slash-" .. step]},
      skill_name = "tqs_qa", prompt = "[TQS QA] Sát lần " .. step .. ": chọn Sát và đối thủ",
      extra_data = extra, cancelable = true, skip = true,
    })
  else
    use = room:askToUseCard(from, {
      skill_name = "tqs_qa", pattern = "slash",
      prompt = "[TQS QA] Long Đảm: dùng Thiểm như Sát để phản công",
      extra_data = extra, cancelable = true,
    })
  end
  if not use or use.card.trueName ~= "slash" or #use.tos ~= 1 or use.tos[1] ~= to then
    fail(string.format("attack step %d requires a Slash to the catalog target", step))
  end
  if step <= 3 and use.card.id ~= state.slotCards["actor-slash-" .. step] then
    fail("Wei must use the reserved real Slash for this step")
  end
  use.extraUse = true
  room:useCard(use)
  state.currentDamageStep = nil

  local dealt = 0
  for _, damage in ipairs(state.damageEvents) do
    if damage.step == step and damage.from == from.id and damage.to == to.id then
      dealt = dealt + damage.amount
    end
  end
  if dealt ~= spec.amount or toHp - to.hp ~= spec.amount then
    fail(string.format("attack step %d expected exactly %d damage", step, spec.amount))
  end
  for _, skillName in ipairs(spec.mandatorySkills) do
    if not observedSkill(state, step, skillName) then
      fail(string.format("attack step %d missing mandatory SkillEffect %s", step, skillName))
    end
  end
  -- These skills remain optional in upstream. This positive test explicitly
  -- selects Invoke; a skipped choice fails this selected branch, not the rule.
  for _, skillName in ipairs(spec.expectedInvokedSkills or {}) do
    if not observedSkill(state, step, skillName) then
      fail(string.format("attack step %d did not select optional skill %s", step, skillName))
    end
  end

  if step == 1 then
    if not convertedCard(state, step, to, "jink", state.slotCards["target-dodge"]) or
      observedSkill(state, step, "ld__enyuan") or from.hp ~= fromHp then
      fail("attack 1 must be dodged by Longdan Slash-as-Jink without Enyuan")
    end
  elseif step == 2 then
    if movedCount(state, step, "ld__enyuan", from, to) ~= 1 or
      #from:getCardIds(Player.Hand) ~= fromHand - 2 or
      #to:getCardIds(Player.Hand) ~= toHand + 1 or from.hp ~= fromHp or
      room:getCardOwner(state.slotCards["actor-gift"]) ~= to then
      fail("attack 2 must consume one Slash and give the reserved hand card via Enyuan")
    end
  elseif step == 3 then
    if fromHand ~= 1 or #from:getCardIds(Player.Hand) ~= 0 or
      fromHp - from.hp ~= 1 or #to:getCardIds(Player.Hand) ~= toHand or
      movedCount(state, step, "ld__enyuan", from, to) ~= 0 then
      fail("attack 3 must leave Wei empty-handed and lose exactly one HP via Enyuan")
    end
    if observedSkill(state, step, "hs__yiji") or observedSkill(state, step, "fankui") then
      fail("Enyuan HP loss must not trigger Damaged skills")
    end
  else
    if not convertedCard(state, step, from, "slash", state.slotCards["target-counter"]) or
      movedCount(state, step, "hs__yiji", nil, to) ~= 2 or
      movedCount(state, step, "fankui", from, to) ~= 1 or
      #to:getCardIds(Player.Hand) ~= toHand + 3 or
      #from:getCardIds(Player.Hand) ~= fromHand - 2 or from.hp ~= fromHp then
      fail("counterattack must use Longdan Jink-as-Slash, Yiji two to self and Fankui one from Shu")
    end
  end
  local skills = observedSkills(state, step)
  state.damageResults[step] = { from = spec.from, to = spec.to, amount = dealt,
    result = spec.expectedEffect, skills = skills }
  sendDamageStepLog(room, step, from, to, spec.expectedEffect, skills)
end

local function triggerDamageExchange(room, state)
  state.actor:revealGenerals()
  state.target:revealGenerals()
  for _, pair in ipairs({{state.target, "ld__enyuan"}, {state.target, "hs__longdan"},
    {state.actor, "hs__yiji"}, {state.actor, "fankui"}}) do
    if not pair[1]:hasSkill(pair[2]) then fail("fixed pair did not attach " .. pair[2]) end
  end
  for step = 1, #scenarioById[state.scenario].attackSteps do
    runAttackStep(room, state, step)
  end
  state.damageExchangeComplete = true
  room:sendLog{ type = "[TQS QA] Hoàn tất bốn bước Sát; ba đòn Ngụy: %arg; phản công Thục: %arg2", from = state.actor.id,
    arg = "longdan-slash-as-jink-dodge; source-gives-one-hand-card; empty-source-loses-one-hp",
    arg2 = "longdan-jink-as-slash; yiji-two-to-self; fankui-one-from-source" }
  fk.qInfo("[tqs_qa] four Slash steps complete scenario=" .. state.scenario)
  -- GameStart runs inside Round:main; a Round exit callback would allow
  -- unrelated normal turns before finishing this four-step acceptance path.
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenYiji(room, state)
  -- The target is revealed only to make the source of the deterministic
  -- damage public. The actor remains fully hidden; the fake Yiji skill is
  -- visible only in the actor's private dashboard.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-yiji actor must start with both generals hidden")
  end
  if state.actor:hasSkill("hs__yiji") then
    fail("hidden-yiji must not be active before the client prelights it")
  end

  -- This is a normal server request, used only as a bounded QA pause. It
  -- gives the real client time to send PushRequest("prelight,...") while the
  -- actor is still hidden; the damage below is still handled by native rules.
  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_yiji_gate",
    prompt = "TQS QA: prelight Di Kế nếu muốn, rồi bấm Kích hoạt để gây sát thương.",
  })
  if not gate then
    fail("hidden-yiji QA gate was cancelled")
  end

  local prelighted = isPrelighted(state.actor, "hs__yiji")
  state.hiddenPrelighted = prelighted
  state.currentDamageStep = 1
  local beforeHp = state.actor.hp
  room:damage({
    from = state.target,
    to = state.actor,
    damage = 1,
    skillName = "tqs_qa_hidden_yiji_damage",
  })
  state.currentDamageStep = nil

  local invoked = observedSkill(state, 1, "hs__yiji")
  local revealed = state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang"
  local yijiIsDeputy = state.scenario == "hidden-yiji-deputy" or state.scenario == "hidden-rehide-yiji-deputy"
  local moved = movedCount(state, 1, "hs__yiji", nil, state.actor)
  local damage = 0
  for _, entry in ipairs(state.damageEvents) do
    if entry.step == 1 and entry.to == state.actor.id then damage = damage + entry.amount end
  end
  if damage ~= 1 or beforeHp - state.actor.hp ~= 1 then
    fail("hidden-yiji must receive exactly one native damage")
  end

  if not prelighted then
    if invoked or revealed or moved ~= 0 then
      fail("unprelighted hidden Yiji must not ask, reveal or move cards")
    end
    state.hiddenYijiBranch = "negative-no-prelight"
  elseif invoked then
    local revealedCorrectSlot = yijiIsDeputy
      and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__guojia"
      or not yijiIsDeputy and state.actor.general == "hs__guojia" and state.actor.deputyGeneral == "anjiang"
    if not revealed or not revealedCorrectSlot or moved ~= 2 then
      fail("prelighted and invoked hidden Yiji must reveal Quách Gia in its catalogued slot and give two cards")
    end
    state.hiddenYijiBranch = state.rehideAfterYiji and "positive-prelight-invoke-rehide" or "positive-prelight-invoke"

    if state.rehideAfterYiji then
      -- Source-law regression: a revealed slot may be hidden again by another
      -- rule.  FreeKill must reattach the skill as fake while retaining the
      -- player's prelight choice, so the next legal trigger can still invoke
      -- it.  Do not accept a regular duplicate in the private skill list.
      state.actor:hideGeneral(yijiIsDeputy)
      local hiddenCorrectSlot = yijiIsDeputy
        and state.actor.general == "anjiang" and state.actor.deputyGeneral == "anjiang"
        or not yijiIsDeputy and state.actor.general == "anjiang" and state.actor.deputyGeneral == "anjiang"
      local fake = state.actor:isFakeSkill("hs__yiji")
      local retainedPrelight = isPrelighted(state.actor, "hs__yiji")
      local activeAgain = state.actor:hasSkill("hs__yiji")
      local regularDuplicate = table.contains(state.actor.player_skills, Fk.skills.hs__yiji)
      if not hiddenCorrectSlot or not fake or not retainedPrelight or not activeAgain or regularDuplicate then
        fail(string.format("hidden-rehide-yiji must reattach fake prelighted Di Kế without a regular duplicate (slot=%s fake=%s prelight=%s active=%s regular=%s)",
          yijiIsDeputy and "deputy" or "main", tostring(fake), tostring(retainedPrelight),
          tostring(activeAgain), tostring(regularDuplicate)))
      end
      state.rehideVerified = true
    end
  else
    if revealed or moved ~= 0 then
      fail("skipped hidden Yiji must remain hidden and move no cards")
    end
    state.hiddenYijiBranch = "skip-prelight"
  end

  room:sendLog{
    type = "[TQS QA] Hidden Di Kế: %arg; vị trí=%arg6; prelight=%arg2; SkillEffect=%arg3; mở tướng=%arg4; chuyển bài=%arg5; úp lại=%arg7",
    from = state.actor.id,
    arg = state.hiddenYijiBranch,
    arg2 = tostring(prelighted),
    arg3 = tostring(invoked),
    arg4 = tostring(revealed),
    arg5 = tostring(moved),
    arg6 = yijiIsDeputy and "phó tướng" or "chủ tướng",
    arg7 = tostring(state.rehideVerified == true),
  }
  fk.qInfo(string.format("[tqs_qa] hidden-yiji branch=%s slot=%s prelight=%s invoked=%s revealed=%s moved=%d rehide=%s revision=%s",
    state.hiddenYijiBranch, yijiIsDeputy and "deputy" or "main", tostring(prelighted), tostring(invoked), tostring(revealed), moved,
    tostring(state.rehideVerified == true), manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenJianxiong(room, state)
  -- Cao Cao remains fully hidden while the other player uses a real Slash.
  -- The card must stay in Processing during Damaged so the browser can prove
  -- the Jianxiong choice branch that obtains the damage card.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-jianxiong actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("hs__jianxiong") then
    fail("hidden-jianxiong must attach the hidden Jianxiong skill")
  end
  if state.actor:hasSkill("hs__jianxiong") then
    fail("hidden-jianxiong must not be active before the prelighted effect")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_jianxiong_gate",
    prompt = "TQS QA: prelight Gian Hùng, rồi xác nhận để đối thủ dùng Sát.",
  })
  if not gate then
    fail("hidden-jianxiong QA gate was cancelled")
  end
  if not isPrelighted(state.actor, "hs__jianxiong") then
    fail("hidden-jianxiong must be prelighted before the damage branch")
  end

  local cardId = state.slotCards["jianxiong-card"]
  local deferredCardId = state.deferredHands["jianxiong-card"]
  if deferredCardId ~= cardId then
    fail("hidden-jianxiong must retain its catalogued Slash as a deferred target-hand card")
  end
  room:moveCardTo(cardId, Card.PlayerHand, state.target, fk.ReasonJustMove,
    "tqs_qa", nil, false, state.target)
  if not cardId or not table.contains(state.target:getCardIds(Player.Hand), cardId) then
    fail("hidden-jianxiong must put its reserved Slash in the target hand")
  end

  state.currentDamageStep = 1
  local use = room:askToUseRealCard(state.target, {
    pattern = { cardId },
    skill_name = "tqs_qa_hidden_jianxiong_damage",
    prompt = "TQS QA: dùng Sát lên Cao Cao để kiểm tra Gian Hùng.",
    extra_data = {
      bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.actor.id }, must_targets = { state.actor.id },
    },
    cancelable = true,
    skip = true,
  })
  if not use or not use.card or use.card.id ~= cardId or #use.tos ~= 1 or
      use.tos[1] ~= state.actor then
    fail("hidden-jianxiong must receive the reserved target Slash against the hidden actor")
  end
  use.extraUse = true
  room:useCard(use)
  state.currentDamageStep = nil

  local invoked = observedSkill(state, 1, "hs__jianxiong")
  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "hs__jianxiong" and entry.player == state.actor.id
  end)
  local jianxiongIsDeputy = state.scenario == "hidden-jianxiong-deputy"
  local revealedCorrectSlot = jianxiongIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__caocao"
    or not jianxiongIsDeputy and state.actor.general == "hs__caocao" and state.actor.deputyGeneral == "anjiang"
  local obtained = movedFromArea(state, 1, "hs__jianxiong", state.actor, Card.Processing)
  local damage = 0
  for _, entry in ipairs(state.damageEvents) do
    if entry.step == 1 and entry.to == state.actor.id then damage = damage + entry.amount end
  end

  if damage ~= 1 or not invoked or not effect or effect.fake or not revealedCorrectSlot then
    fail("prelighted hidden Jianxiong must invoke, reveal Cao Cao in its catalogued slot and run a real SkillEffect")
  end
  if obtained ~= 1 or not table.contains(state.actor:getCardIds(Player.Hand), cardId) then
    fail("hidden Jianxiong obtain choice must move the damaging Slash from Processing to Cao Cao")
  end

  state.hiddenJianxiongBranch = "positive-prelight-invoke-obtain"
  room:sendLog{
    type = "[TQS QA] Hidden Gian Hùng: %arg; vị trí=%arg6; prelight=%arg2; SkillEffect=%arg3; mở tướng=%arg4; lấy bài=%arg5",
    from = state.actor.id,
    arg = state.hiddenJianxiongBranch,
    arg2 = "true",
    arg3 = tostring(invoked),
    arg4 = tostring(revealedCorrectSlot),
    arg5 = tostring(obtained),
    arg6 = jianxiongIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-jianxiong branch=%s slot=%s prelight=true invoked=%s revealed=%s obtained=%d revision=%s",
    state.hiddenJianxiongBranch, jianxiongIsDeputy and "deputy" or "main", tostring(invoked),
    tostring(revealedCorrectSlot), obtained, manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenFankui(room, state)
  -- Tư Mã Ý stays face-down while the public target uses a real Slash. The
  -- catalog keeps a second target hand card so the Slash moves to Processing
  -- and Phản Quỹ must choose the remaining hidden hand card.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-fankui actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("fankui") then
    fail("hidden-fankui must attach the hidden Fankui skill")
  end
  if state.actor:hasSkill("fankui") then
    fail("hidden-fankui must not be active before the prelighted effect")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_fankui_gate",
    prompt = "TQS QA: prelight Phản Quỹ, rồi xác nhận để đối thủ dùng Sát.",
  })
  if not gate then
    fail("hidden-fankui QA gate was cancelled")
  end
  if not isPrelighted(state.actor, "fankui") then
    fail("hidden-fankui must be prelighted before the damage branch")
  end

  local damageCardId = state.slotCards["fankui-damage"]
  local lootCardId = state.slotCards["fankui-loot"]
  if #state.target:getCardIds(Player.Hand) ~= 2 or
      not table.contains(state.target:getCardIds(Player.Hand), damageCardId) or
      not table.contains(state.target:getCardIds(Player.Hand), lootCardId) then
    fail("hidden-fankui must start with the catalogued target Slash and Peach")
  end

  state.currentDamageStep = 1
  local use = room:askToUseRealCard(state.target, {
    pattern = { damageCardId },
    skill_name = "tqs_qa_hidden_fankui_damage",
    prompt = "TQS QA: dùng Sát lên Tư Mã Ý để kiểm tra Phản Quỹ.",
    extra_data = {
      bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.actor.id }, must_targets = { state.actor.id },
    },
    cancelable = true,
    skip = true,
  })
  if not use or not use.card or use.card.id ~= damageCardId or #use.tos ~= 1 or
      use.tos[1] ~= state.actor then
    fail("hidden-fankui must receive the reserved target Slash against the hidden actor")
  end
  use.extraUse = true
  room:useCard(use)
  state.currentDamageStep = nil

  local invoked = observedSkill(state, 1, "fankui")
  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "fankui" and entry.player == state.actor.id
  end)
  local fankuiIsDeputy = state.scenario == "hidden-fankui-deputy"
  local revealedCorrectSlot = fankuiIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__simayi"
    or not fankuiIsDeputy and state.actor.general == "hs__simayi" and state.actor.deputyGeneral == "anjiang"
  local obtained = movedCount(state, 1, "fankui", state.target, state.actor)
  local damage = 0
  for _, entry in ipairs(state.damageEvents) do
    if entry.step == 1 and entry.to == state.actor.id then damage = damage + entry.amount end
  end

  if damage ~= 1 or not invoked or not effect or effect.fake or not revealedCorrectSlot then
    fail("prelighted hidden Fankui must invoke, reveal Tư Mã Ý in its catalogued slot and run a real SkillEffect")
  end
  if obtained ~= 1 or room:getCardOwner(lootCardId) ~= state.actor or
      not table.contains(state.actor:getCardIds(Player.Hand), lootCardId) then
    fail("hidden Fankui must choose and obtain the remaining target hand card")
  end

  state.hiddenFankuiBranch = "positive-prelight-trigger-obtain"
  room:sendLog{
    type = "[TQS QA] Hidden Phản Quỹ: %arg; vị trí=%arg6; prelight=%arg2; SkillEffect=%arg3; mở tướng=%arg4; lấy bài=%arg5",
    from = state.actor.id,
    arg = state.hiddenFankuiBranch,
    arg2 = "true",
    arg3 = tostring(invoked),
    arg4 = tostring(revealedCorrectSlot),
    arg5 = tostring(obtained),
    arg6 = fankuiIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-fankui branch=%s slot=%s prelight=true invoked=%s revealed=%s obtained=%d revision=%s",
    state.hiddenFankuiBranch, fankuiIsDeputy and "deputy" or "main", tostring(invoked),
    tostring(revealedCorrectSlot), obtained, manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenEnyuan(room, state)
  -- 法正 remains face-down while the other player uses a real Peach on the
  -- wounded actor.  This covers TargetConfirmed rather than the separate
  -- Damaged branch already exercised by fazheng-enyuan.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-enyuan actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("ld__enyuan") then
    fail("hidden-enyuan must attach the hidden Enyuan skill")
  end
  if state.actor:hasSkill("ld__enyuan") then
    fail("hidden-enyuan must not be active before the prelighted Peach target branch")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_enyuan_gate",
    prompt = "TQS QA: prelight Ân Oán, rồi xác nhận để đối thủ dùng Đào lên Pháp Chính.",
  })
  if not gate then
    fail("hidden-enyuan QA gate was cancelled")
  end
  if not isPrelighted(state.actor, "ld__enyuan") then
    fail("hidden-enyuan must be prelighted before the Peach target branch")
  end

  local peachId = state.slotCards["enyuan-peach"]
  if not peachId or not table.contains(state.target:getCardIds(Player.Hand), peachId) then
    fail("hidden-enyuan must put the reserved Peach in the native source hand")
  end
  if state.actor.hp >= state.actor.maxHp then
    room:setPlayerProperty(state.actor, "hp", math.max(1, state.actor.hp - 1))
  end
  if state.actor.hp >= state.actor.maxHp then
    fail("hidden-enyuan must make the actor wounded so the Peach target is legal")
  end

  state.currentDamageStep = 1
  local use = room:askToUseRealCard(state.target, {
    pattern = { peachId },
    skill_name = "tqs_qa_hidden_enyuan_peach",
    prompt = "TQS QA: dùng Đào lên Pháp Chính để kiểm tra Ân Oán.",
    extra_data = {
      bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.actor.id }, must_targets = { state.actor.id },
      -- Peach defaults to its user as a fixed target.  The standard dying
      -- rule supplies fix_targets for an external rescuer; mirror that
      -- contract here so the reserved Peach remains selectable against the
      -- wounded hidden actor.
      fix_targets = { state.actor.id },
    },
    cancelable = true,
    skip = true,
  })
  if not use or not use.card or use.card.id ~= peachId or #use.tos ~= 1 or
      use.tos[1] ~= state.actor then
    fail("hidden-enyuan must receive the reserved source Peach against the hidden actor")
  end
  use.extraUse = true
  room:useCard(use)
  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "ld__enyuan" and entry.player == state.actor.id
  end)
  state.currentDamageStep = nil

  local enyuanIsDeputy = state.scenario == "hidden-enyuan-deputy"
  local revealedCorrectSlot = enyuanIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "ld__fazheng"
    or not enyuanIsDeputy and state.actor.general == "ld__fazheng" and state.actor.deputyGeneral == "anjiang"
  if not state.hiddenEnyuanTargetConfirmed or not effect or effect.fake or not revealedCorrectSlot or
      state.hiddenEnyuanDrawCount ~= 1 or #state.target:getCardIds(Player.Hand) ~= 1 then
    fail(string.format("prelighted hidden Enyuan must reveal Fa Zheng before TargetConfirmed and draw one card (target_confirmed=%s effect=%s fake=%s revealed=%s draw=%d target_hand=%d)",
      tostring(state.hiddenEnyuanTargetConfirmed), tostring(effect ~= nil), tostring(effect and effect.fake),
      tostring(revealedCorrectSlot), state.hiddenEnyuanDrawCount, #state.target:getCardIds(Player.Hand)))
  end

  state.gameOverRequested = true
  room:sendLog{
    type = "[TQS QA] Hidden Ân Oán: TargetConfirmed=%arg; SkillEffect=%arg2; mở Pháp Chính=%arg3; rút bài=%arg4; vị trí=%arg5",
    from = state.actor.id,
    arg = tostring(state.hiddenEnyuanTargetConfirmed),
    arg2 = tostring(effect ~= nil and not effect.fake),
    arg3 = tostring(revealedCorrectSlot),
    arg4 = tostring(state.hiddenEnyuanDrawCount),
    arg5 = enyuanIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-enyuan target_confirmed=%s skill_effect=%s revealed=%s drawn=%d slot=%s revision=%s",
    tostring(state.hiddenEnyuanTargetConfirmed), tostring(effect ~= nil and not effect.fake),
    tostring(revealedCorrectSlot), state.hiddenEnyuanDrawCount,
    enyuanIsDeputy and "deputy" or "main", manifest.sourceRevision))
  room:gameOver("")
end

local function triggerHiddenFuyin(room, state)
  -- 父荫 is a compulsory TargetConfirmed effect. Keep Zhuge Zhan face-down
  -- until the real Slash reaches the native target-confirmation stage, then
  -- prove that the source reveals the owning slot before nullifying the card.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-fuyin actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("fuyin") then
    fail("hidden-fuyin must attach the hidden Fuyin skill")
  end
  if state.actor:hasSkill("fuyin") then
    fail("hidden-fuyin must not be active before the prelighted Slash branch")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_fuyin_gate",
    prompt = "TQS QA: prelight Phụ Âm, rồi xác nhận để đối thủ dùng Sát.",
  })
  if not gate then
    fail("hidden-fuyin QA gate was cancelled")
  end
  if not isPrelighted(state.actor, "fuyin") then
    fail("hidden-fuyin must be prelighted before the TargetConfirmed branch")
  end

  local cardId = state.slotCards["fuyin-slash"]
  if not cardId or not table.contains(state.target:getCardIds(Player.Hand), cardId) then
    fail("hidden-fuyin must put the reserved Slash in the native source hand")
  end

  local actorHpBefore = state.actor.hp
  state.currentDamageStep = 1
  local use = room:askToUseRealCard(state.target, {
    pattern = { cardId },
    skill_name = "tqs_qa_hidden_fuyin_damage",
    prompt = "TQS QA: dùng Sát lên Phụ Ấm để kiểm tra TargetConfirmed.",
    extra_data = {
      bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.actor.id }, must_targets = { state.actor.id },
    },
    cancelable = true,
    skip = true,
  })
  if not use or not use.card or use.card.id ~= cardId or #use.tos ~= 1 or
      use.tos[1] ~= state.actor then
    fail("hidden-fuyin must receive the reserved source Slash against the hidden actor")
  end
  use.extraUse = true
  room:useCard(use)
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "fuyin" and entry.player == state.actor.id
  end)
  local fuyinIsDeputy = state.scenario == "hidden-fuyin-deputy"
  local revealedCorrectSlot = fuyinIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "zhugezhan"
    or not fuyinIsDeputy and state.actor.general == "zhugezhan" and state.actor.deputyGeneral == "anjiang"
  if not state.hiddenFuyinTargetConfirmed or not state.hiddenFuyinNullified or
      state.actor.hp ~= actorHpBefore or not effect or effect.fake or not revealedCorrectSlot then
    fail(string.format("prelighted hidden Fuyin must reveal Zhuge Zhan before nullifying TargetConfirmed Slash (target_confirmed=%s nullified=%s hp_before=%d hp_after=%d effect=%s fake=%s revealed=%s has_skill=%s fake_skill=%s actor_hand=%d source_hand=%d)",
      tostring(state.hiddenFuyinTargetConfirmed), tostring(state.hiddenFuyinNullified), actorHpBefore,
      state.actor.hp, tostring(effect ~= nil), tostring(effect and effect.fake), tostring(revealedCorrectSlot),
      tostring(state.actor:hasSkill("fuyin")), tostring(state.actor:isFakeSkill("fuyin")),
      state.actor:getHandcardNum(), state.target:getHandcardNum()))
  end

  room:sendLog{
    type = "[TQS QA] Hidden Phụ Âm: TargetConfirmed=%arg; SkillEffect=%arg2; vô hiệu Sát=%arg3; mở Gia Cát Chiêm=%arg4; vị trí=%arg5",
    from = state.actor.id,
    arg = tostring(state.hiddenFuyinTargetConfirmed),
    arg2 = tostring(effect ~= nil and not effect.fake),
    arg3 = tostring(state.hiddenFuyinNullified),
    arg4 = tostring(revealedCorrectSlot),
    arg5 = fuyinIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-fuyin target_confirmed=%s skill_effect=%s nullified=%s revealed=%s slot=%s revision=%s",
    tostring(state.hiddenFuyinTargetConfirmed), tostring(effect ~= nil and not effect.fake),
    tostring(state.hiddenFuyinNullified), tostring(revealedCorrectSlot),
    fuyinIsDeputy and "deputy" or "main", manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenKuanggu(room, state)
  -- 狂骨 has two linked source effects: BeforeHpChanged marks a close-range
  -- damage event, then Damage asks the hidden owner whether to draw or heal.
  -- Keep Wei Yan face-down until the real SkillEffect path resolves so this
  -- scenario proves both the prelight gate and reveal-before-effect ordering.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-kuanggu actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("hs__kuanggu") then
    fail("hidden-kuanggu must attach the hidden Kuanggu skill")
  end
  if state.actor:hasSkill("hs__kuanggu") then
    fail("hidden-kuanggu must not be active before the prelighted damage effect")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_kuanggu_gate",
    prompt = "TQS QA: prelight Cuồng Cốt, rồi xác nhận để đối thủ nhận sát thương.",
  })
  if not gate then
    fail("hidden-kuanggu QA gate was cancelled")
  end
  if not isPrelighted(state.actor, "hs__kuanggu") then
    fail("hidden-kuanggu must be prelighted before the damage branch")
  end

  local cardId = state.slotCards["kuanggu-card"]
  local targetCardId = state.slotCards["kuanggu-target-card"]
  if not cardId or not table.contains(state.actor:getCardIds(Player.Hand), cardId) or
      not targetCardId or not table.contains(state.target:getCardIds(Player.Hand), targetCardId) then
    fail("hidden-kuanggu must put the reserved Slash and target Peach in the native hands")
  end
  if #state.actor:getCardIds(Player.Hand) ~= 1 or #state.target:getCardIds(Player.Hand) ~= 1 then
    fail("hidden-kuanggu must keep the actor and target hands deterministic")
  end

  state.currentDamageStep = 1
  local use = room:askToUseRealCard(state.actor, {
    pattern = { cardId },
    skill_name = "tqs_qa_hidden_kuanggu_damage",
    prompt = "TQS QA: dùng Sát lên đối thủ để kiểm tra Cuồng Cốt.",
    extra_data = {
      bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.target.id }, must_targets = { state.target.id },
    },
    cancelable = true,
    skip = true,
  })
  if not use or not use.card or use.card.id ~= cardId or #use.tos ~= 1 or
      use.tos[1] ~= state.target then
    fail("hidden-kuanggu must receive the reserved actor Slash against the target")
  end
  use.extraUse = true
  room:useCard(use)
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "hs__kuanggu" and entry.player == state.actor.id
  end)
  local kuangguIsDeputy = state.scenario == "hidden-kuanggu-deputy"
  local revealedCorrectSlot = kuangguIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__weiyan"
    or not kuangguIsDeputy and state.actor.general == "hs__weiyan" and state.actor.deputyGeneral == "anjiang"
  local damage = 0
  for _, entry in ipairs(state.damageEvents) do
    if entry.step == 1 and entry.to == state.target.id then damage = damage + entry.amount end
  end
  local moved = movedCount(state, 1, "hs__kuanggu", nil, state.actor)

  if not state.kuangguBeforeHpChanged or not state.kuangguDamage or damage ~= 1 or
      not effect or effect.fake or not revealedCorrectSlot then
    fail("prelighted hidden Kuanggu must mark close-range damage, reveal Wei Yan and run a real SkillEffect")
  end
  if moved ~= 1 then
    fail("hidden Kuanggu must execute the native draw1 choice and move one card to the actor hand")
  end

  state.hiddenKuangguBranch = "positive-prelight-damage-draw"
  room:sendLog{
    type = "[TQS QA] Hidden Cuồng Cốt: BeforeHpChanged=%arg; Damage=%arg2; SkillEffect=%arg3; mở tướng=%arg4; bốc bài=%arg5; vị trí=%arg6",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = "true",
    arg4 = tostring(revealedCorrectSlot),
    arg5 = tostring(moved == 1),
    arg6 = kuangguIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-kuanggu before_hp_changed=true damage=true skill_effect=true moved=%d slot=%s main=%s deputy=%s revision=%s",
    moved, kuangguIsDeputy and "deputy" or "main", state.actor.general, state.actor.deputyGeneral,
    manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenLiegong(room, state)
  -- 烈弓 is a TargetSpecified trigger.  Keep Huang Zhong face-down until the
  -- real Slash reaches the native choice, then prove that the damage branch
  -- adds one point and reveals only the slot owning the prelighted skill.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-liegong actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("hs__liegong") then
    fail("hidden-liegong must attach the hidden Liegong skill")
  end
  if state.actor:hasSkill("hs__liegong") then
    fail("hidden-liegong must not be active before the prelighted target branch")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_liegong_gate",
    prompt = "TQS QA: prelight Liệt Cung, rồi xác nhận để dùng Sát.",
  })
  if not gate then
    fail("hidden-liegong QA gate was cancelled")
  end
  if not isPrelighted(state.actor, "hs__liegong") then
    fail("hidden-liegong must be prelighted before the TargetSpecified branch")
  end

  local cardId = state.slotCards["liegong-card"]
  local targetCardId = state.slotCards["liegong-target-card"]
  if not cardId or not table.contains(state.actor:getCardIds(Player.Hand), cardId) or
      not targetCardId or not table.contains(state.target:getCardIds(Player.Hand), targetCardId) then
    fail("hidden-liegong must put the reserved Slash and target Peach in the native hands")
  end
  if #state.actor:getCardIds(Player.Hand) ~= 1 or #state.target:getCardIds(Player.Hand) ~= 1 then
    fail("hidden-liegong must keep the actor and target hands deterministic")
  end
  if state.actor.hp ~= state.target.hp then
    fail("hidden-liegong must start with equal full HP so its source predicate is true")
  end

  local targetHpBefore = state.target.hp
  state.currentDamageStep = 1
  local use = room:askToUseRealCard(state.actor, {
    pattern = { cardId },
    skill_name = "tqs_qa_hidden_liegong_damage",
    prompt = "TQS QA: dùng Sát lên đối thủ để kiểm tra Liệt Cung.",
    extra_data = {
      bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.target.id }, must_targets = { state.target.id },
    },
    cancelable = true,
    skip = true,
  })
  if not use or not use.card or use.card.id ~= cardId or #use.tos ~= 1 or
      use.tos[1] ~= state.target then
    fail("hidden-liegong must receive the reserved actor Slash against the target")
  end
  use.extraUse = true
  room:useCard(use)
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "hs__liegong" and entry.player == state.actor.id
  end)
  local liegongIsDeputy = state.scenario == "hidden-liegong-deputy"
  local revealedCorrectSlot = liegongIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__huangzhong"
    or not liegongIsDeputy and state.actor.general == "hs__huangzhong" and state.actor.deputyGeneral == "anjiang"
  local damage = 0
  for _, entry in ipairs(state.damageEvents) do
    if entry.step == 1 and entry.to == state.target.id then damage = damage + entry.amount end
  end

  if not state.liegongTargetSpecified or not state.liegongDamage or damage ~= 2 or
      targetHpBefore - state.target.hp ~= 2 or not effect or effect.fake or not revealedCorrectSlot then
    fail("prelighted hidden Liegong must mark TargetSpecified/Damage, reveal Huang Zhong and add one damage")
  end

  state.hiddenLiegongBranch = "positive-prelight-target-specified-damage-plus-one"
  room:sendLog{
    type = "[TQS QA] Hidden Liệt Cung: TargetSpecified=%arg; Damage=%arg2; SkillEffect=%arg3; sát thương=2; mở tướng=%arg4; vị trí=%arg5",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = "true",
    arg4 = tostring(revealedCorrectSlot),
    arg5 = liegongIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-liegong target_specified=true damage=2 skill_effect=true revealed=%s slot=%s main=%s deputy=%s revision=%s",
    tostring(revealedCorrectSlot), liegongIsDeputy and "deputy" or "main", state.actor.general,
    state.actor.deputyGeneral, manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenJueqing(room, state)
  -- 绝情 is a compulsory fk.PreDamage effect. Keep Zhang Chunhua hidden until
  -- the real Slash reaches PreDamage, then prove that the source converts the
  -- damage into HP loss and prevents the ordinary Damage/Damaged path.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-jueqing actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("jueqing") then
    fail("hidden-jueqing must attach the hidden Jueqing skill")
  end
  if state.actor:hasSkill("jueqing") then
    fail("hidden-jueqing must not be active before the prelighted effect")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_jueqing_gate",
    prompt = "TQS QA: prelight Tuyệt Tình, rồi xác nhận để đối thủ nhận Sát.",
  })
  if not gate then
    fail("hidden-jueqing QA gate was cancelled")
  end
  if not isPrelighted(state.actor, "jueqing") then
    fail("hidden-jueqing must be prelighted before the PreDamage branch")
  end

  local cardId = state.slotCards["jueqing-card"]
  if not cardId or #state.actor:getCardIds(Player.Hand) ~= 1 or
      not table.contains(state.actor:getCardIds(Player.Hand), cardId) then
    fail("hidden-jueqing must put exactly the reserved Slash in the actor hand")
  end

  local targetHpBefore = state.target.hp
  local actorHpBefore = state.actor.hp
  state.currentDamageStep = 1
  local use = room:askToUseRealCard(state.actor, {
    pattern = { cardId },
    skill_name = "tqs_qa_hidden_jueqing_damage",
    prompt = "TQS QA: dùng Sát lên đối thủ để kiểm tra Tuyệt Tình.",
    extra_data = {
      bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.target.id }, must_targets = { state.target.id },
    },
    cancelable = true,
    skip = true,
  })
  if not use or not use.card or use.card.id ~= cardId or #use.tos ~= 1 or
      use.tos[1] ~= state.target then
    fail("hidden-jueqing must receive the reserved actor Slash against the target")
  end
  use.extraUse = true
  room:useCard(use)
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "jueqing" and entry.player == state.actor.id
  end)
  local jueqingIsDeputy = state.scenario == "hidden-jueqing-deputy"
  local revealedCorrectSlot = jueqingIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "zhangchunhua"
    or not jueqingIsDeputy and state.actor.general == "zhangchunhua" and state.actor.deputyGeneral == "anjiang"
  local damage = 0
  for _, entry in ipairs(state.damageEvents) do
    if entry.step == 1 and entry.to == state.target.id then damage = damage + entry.amount end
  end
  local targetHpLoss = targetHpBefore - state.target.hp

  if not state.jueqingPreDamage or not effect or effect.fake or not revealedCorrectSlot or
      targetHpLoss ~= 1 or damage ~= 0 or actorHpBefore ~= state.actor.hp then
    fail("prelighted hidden Jueqing must reveal Zhang Chunhua, convert one damage to HP loss and prevent Damaged")
  end
  if state.actor:isFakeSkill("jueqing") or not state.actor:hasSkill("jueqing") then
    fail("hidden Jueqing must be a real active skill after SkillEffect")
  end

  room:sendLog{
    type = "[TQS QA] Hidden Tuyệt Tình: PreDamage=%arg; Damage=%arg2; SkillEffect=%arg3; mất máu=%arg4; mở tướng=%arg5; vị trí=%arg6",
    from = state.actor.id,
    arg = "true",
    arg2 = tostring(damage == 0),
    arg3 = "true",
    arg4 = tostring(targetHpLoss == 1),
    arg5 = tostring(revealedCorrectSlot),
    arg6 = jueqingIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-jueqing pre_damage=true damage_event=false skill_effect=true hp_loss=%d revealed=%s slot=%s main=%s deputy=%s revision=%s",
    targetHpLoss, tostring(revealedCorrectSlot), jueqingIsDeputy and "deputy" or "main",
    state.actor.general, state.actor.deputyGeneral, manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenEjue(room, state)
  -- 扼绝 is a compulsory fk.DamageCaused effect. Keep Zhang Chunhua hidden
  -- until the real Slash reaches the source-side damage hook, then prove the
  -- native predicate (Slash + unknown kingdom) and the +1 damage mutation.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-ejue actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("heg__ejue") then
    fail("hidden-ejue must attach the hidden Ejue skill")
  end
  if state.actor:hasSkill("heg__ejue") then
    fail("hidden-ejue must not be active before the prelighted effect")
  end

  -- The source skill itself requires data.to.kingdom == unknown. This is a
  -- test fixture for that native state, not a production rule change.
  room:setPlayerProperty(state.target, "kingdom", "unknown")
  room:broadcastProperty(state.target, "kingdom")

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_ejue_gate",
    prompt = "TQS QA: prelight Ách Tuyệt, rồi xác nhận để dùng Sát lên người chưa rõ thế lực.",
  })
  if not gate then
    fail("hidden-ejue QA gate was cancelled")
  end
  if not isPrelighted(state.actor, "heg__ejue") then
    fail("hidden-ejue must be prelighted before the DamageCaused branch")
  end

  local cardId = state.slotCards["ejue-card"]
  if not cardId or #state.actor:getCardIds(Player.Hand) ~= 1 or
      not table.contains(state.actor:getCardIds(Player.Hand), cardId) then
    fail("hidden-ejue must put exactly the reserved Slash in the actor hand")
  end

  local targetHpBefore = state.target.hp
  local actorHpBefore = state.actor.hp
  state.currentDamageStep = 1
  local use = room:askToUseRealCard(state.actor, {
    pattern = { cardId },
    skill_name = "tqs_qa_hidden_ejue_damage",
    prompt = "TQS QA: dùng Sát lên đối thủ để kiểm tra Ách Tuyệt.",
    extra_data = {
      bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.target.id }, must_targets = { state.target.id },
    },
    cancelable = true,
    skip = true,
  })
  if not use or not use.card or use.card.id ~= cardId or #use.tos ~= 1 or
      use.tos[1] ~= state.target then
    fail("hidden-ejue must receive the reserved actor Slash against the unknown target")
  end
  use.extraUse = true
  room:useCard(use)
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "heg__ejue" and entry.player == state.actor.id
  end)
  local ejueIsDeputy = state.scenario == "hidden-ejue-deputy"
  local revealedCorrectSlot = ejueIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "heg__zhangchunhua"
    or not ejueIsDeputy and state.actor.general == "heg__zhangchunhua" and state.actor.deputyGeneral == "anjiang"
  local targetHpLoss = targetHpBefore - state.target.hp
  fk.qInfo(string.format("[tqs_qa] hidden-ejue diagnostics damage_caused=%s effect=%s effect_fake=%s revealed=%s target_hp_loss=%d actor_hp_before=%d actor_hp_after=%d actor_general=%s actor_deputy=%s target_kingdom=%s active=%s fake=%s",
    tostring(state.hiddenEjueDamageCaused), tostring(effect ~= nil), tostring(effect and effect.fake or false),
    tostring(revealedCorrectSlot), targetHpLoss, actorHpBefore, state.actor.hp,
    tostring(state.actor.general), tostring(state.actor.deputyGeneral), tostring(state.target.kingdom),
    tostring(state.actor:hasSkill("heg__ejue")), tostring(state.actor:isFakeSkill("heg__ejue"))))
  if not state.hiddenEjueDamageCaused or not effect or effect.fake or not revealedCorrectSlot or
      targetHpLoss ~= 2 or actorHpBefore ~= state.actor.hp then
    fail("prelighted hidden Ejue must enter DamageCaused, reveal Zhang Chunhua and add one damage")
  end
  if state.actor:isFakeSkill("heg__ejue") or not state.actor:hasSkill("heg__ejue") then
    fail("hidden Ejue must be a real active skill after SkillEffect")
  end

  room:sendLog{
    type = "[TQS QA] Hidden Ách Tuyệt: DamageCaused=%arg; sát thương=%arg2; SkillEffect=%arg3; mở tướng=%arg4; vị trí=%arg5",
    from = state.actor.id,
    arg = tostring(state.hiddenEjueDamageCaused),
    arg2 = tostring(targetHpLoss),
    arg3 = tostring(effect ~= nil and not effect.fake),
    arg4 = tostring(revealedCorrectSlot),
    arg5 = ejueIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-ejue damage_caused=true damage=%d skill_effect=true revealed=%s slot=%s revision=%s",
    targetHpLoss, tostring(revealedCorrectSlot), ejueIsDeputy and "deputy" or "main", manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenReveal(room, state)
  -- The target is revealed to keep the public board deterministic. The actor
  -- remains face-down and must use the same active helper that the native
  -- dashboard exposes for a hidden general with a compulsory skill.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-reveal actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("hs__qianxun") then
    fail("hidden-reveal must attach the hidden compulsory Qianxun skill")
  end
  if not state.actor:isFakeSkill("reveal_skill&") then
    fail("hidden-reveal must attach the native reveal_skill& helper")
  end

  -- Keep the active request behind the same real-client readiness gate used
  -- by hidden-yiji. GameStart can finish before the browser has projected the
  -- fake/regular skill split; the active helper itself must still be the
  -- native AskForUseActiveSkill request below.
  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_reveal_gate",
    prompt = "TQS QA: xác nhận dock Mở tướng đã sẵn sàng, rồi bấm Kích hoạt.",
  })
  if not gate then
    fail("hidden-reveal readiness gate was cancelled")
  end

  local success = room:askToUseActiveSkill(state.actor, {
    skill_name = "reveal_skill&",
    prompt = "TQS QA: mở Lục Tốn bằng kỹ năng Tỏa định.",
    cancelable = true,
  })
  if not success then
    fail("hidden-reveal active helper was cancelled or rejected")
  end
  local revealIsDeputy = state.scenario == "hidden-reveal-deputy"
  local revealedCorrectSlot = revealIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__luxun"
    or not revealIsDeputy and state.actor.general == "hs__luxun" and state.actor.deputyGeneral == "anjiang"
  if not revealedCorrectSlot then
    fail("hidden-reveal must reveal Lục Tốn in its catalogued slot and leave the other slot hidden")
  end
  if not state.actor:hasSkill("hs__qianxun") or state.actor:isFakeSkill("hs__qianxun") then
    fail("hidden-reveal must convert Qianxun from fake to active after reveal")
  end

  room:sendLog{
    type = "[TQS QA] Hidden Mở tướng: %arg; vị trí=%arg4; Lục Tốn đã mở=%arg2; Tỏa định đã hoạt động=%arg3",
    from = state.actor.id,
    arg = "reveal_skill&",
    arg2 = "true",
    arg3 = "true",
    arg4 = revealIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-reveal helper=reveal_skill& slot=%s revealed=hs__luxun qianxun_active=true revision=%s",
    revealIsDeputy and "deputy" or "main", manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenActive(room, state)
  -- Sun Quan's active skill is a direct PlayCard action, not a trigger that
  -- must be prelighted. The actor starts with both generals hidden and the
  -- real client receives hs__zhiheng through the native fake-skill callback's
  -- active-skill projection.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-active actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("hs__zhiheng") then
    fail("hidden-active must attach the hidden active Chế Hành skill")
  end
  if state.actor:hasSkill("hs__zhiheng") then
    fail("hidden-active Chế Hành must not be active before PlayCard")
  end

  -- PlayCard is a normal turn request, but the native client needs one
  -- completed request round after GameStart to finish projecting the hidden
  -- pair and its fake active skill. Keep this bounded QA synchronization
  -- request separate from the rule under test; the actual assertion below is
  -- still the real PlayCard -> handleUseCardReply -> SkillEffect path.
  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_active_gate",
    prompt = "TQS QA: xác nhận dock Chế Hành đã sẵn sàng, rồi bấm Kích hoạt.",
  })
  if not gate then
    fail("hidden-active readiness gate was cancelled")
  end

  local cardId = state.slotCards["zhiheng-card"]
  if not cardId or not table.contains(state.actor:getCardIds(Player.Hand), cardId) then
    fail("hidden-active must put its reserved Slash in the actor hand")
  end

  local request = Request:new(state.actor, "PlayCard")
  request.timeout = room.timeout
  local result = request:getResult(state.actor)
  if result == "" or type(result) ~= "table" or type(result.card) ~= "table" then
    fail("hidden-active must receive a native PlayCard skill reply")
  end
  if result.card.skill ~= "hs__zhiheng" then
    fail("hidden-active PlayCard must select hs__zhiheng")
  end
  if type(result.card.subcards) ~= "table" or #result.card.subcards ~= 1 or
      result.card.subcards[1] ~= cardId then
    fail("hidden-active Chế Hành must select exactly the reserved Slash")
  end

  local beforeHand = #state.actor:getCardIds(Player.Hand)
  local useResult = room:handleUseCardReply(state.actor, result)
  if type(useResult) == "table" then
    room:useCard(useResult)
  end

  local effect = table.find(state.skillEffects, function(entry)
    return entry.skill == "hs__zhiheng" and entry.player == state.actor.id
  end)
  if not effect then
    fail("hidden-active must execute Chế Hành through the native SkillEffect")
  end
  local activeIsMain = state.scenario == "hidden-active-main"
  local revealedCorrectSlot = activeIsMain
    and state.actor.general == "hs__sunquan" and state.actor.deputyGeneral == "anjiang"
    or not activeIsMain and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__sunquan"
  if not revealedCorrectSlot then
    fail("hidden-active must reveal Tôn Quyền in its catalogued slot and keep Lục Tốn hidden")
  end
  if state.actor:isFakeSkill("hs__zhiheng") or not state.actor:hasSkill("hs__zhiheng") then
    fail("hidden-active must convert Chế Hành from fake to active after reveal")
  end
  if (activeIsMain and (effect.general ~= "hs__sunquan" or effect.deputyGeneral ~= "anjiang")) or
      (not activeIsMain and (effect.general ~= "anjiang" or effect.deputyGeneral ~= "hs__sunquan")) or effect.fake then
    fail("hidden-active must reveal Sun Quan before Chế Hành SkillEffect")
  end
  local afterHand = #state.actor:getCardIds(Player.Hand)
  if beforeHand ~= 1 or afterHand ~= beforeHand or
      table.contains(state.actor:getCardIds(Player.Hand), cardId) then
    fail("hidden-active Chế Hành must discard one card and draw one card")
  end

  room:sendLog{
    type = "[TQS QA] Hidden Chế Hành: SkillEffect=%arg; Tôn Quyền đã mở=%arg2; Lục Tốn còn úp=%arg3; vị trí=%arg6; bài trước=%arg4; sau=%arg5",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = "true",
    arg4 = tostring(beforeHand),
    arg5 = tostring(afterHand),
    arg6 = activeIsMain and "chủ tướng" or "phó tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-active skill=hs__zhiheng effect=true slot=%s main=%s deputy=%s hand=%d->%d revision=%s",
    activeIsMain and "main" or "deputy", state.actor.general, state.actor.deputyGeneral, beforeHand, afterHand,
    manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenFanjian(room, state)
  -- Chu Du's active skill is a real PlayCard action.  Keep both Wu generals
  -- hidden until the native SkillEffect runs; the SkillEffect itself must
  -- reveal only the slot that owns ex__fanjian before on_use gives the Peach
  -- and asks the target for the source-defined choice.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-fanjian actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("ex__fanjian") then
    fail("hidden-fanjian must attach the hidden active Phản Gián skill")
  end
  if state.actor:hasSkill("ex__fanjian") then
    fail("hidden-fanjian Phản Gián must not be active before PlayCard")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_fanjian_gate",
    prompt = "TQS QA: xác nhận dock Phản Gián đã sẵn sàng, rồi bấm Kích hoạt.",
  })
  if not gate then
    fail("hidden-fanjian readiness gate was cancelled")
  end

  local cardId = state.slotCards["fanjian-card"]
  local targetCardId = state.slotCards["fanjian-target-card"]
  if not cardId or not table.contains(state.actor:getCardIds(Player.Hand), cardId) then
    fail("hidden-fanjian must put its reserved Peach in the actor hand")
  end
  if not targetCardId or not table.contains(state.target:getCardIds(Player.Hand), targetCardId) then
    fail("hidden-fanjian must put its reserved Jink in the target hand")
  end

  local request = Request:new(state.actor, "PlayCard")
  request.timeout = room.timeout
  local result = request:getResult(state.actor)
  if result == "" or type(result) ~= "table" or type(result.card) ~= "table" then
    fail("hidden-fanjian must receive a native PlayCard skill reply")
  end
  if result.card.skill ~= "ex__fanjian" then
    fail("hidden-fanjian PlayCard must select ex__fanjian")
  end
  if type(result.card.subcards) ~= "table" or #result.card.subcards ~= 1 or
      result.card.subcards[1] ~= cardId or type(result.targets) ~= "table" or
      #result.targets ~= 1 or result.targets[1] ~= state.target.id then
    fail("hidden-fanjian must select exactly the reserved Peach and the native target")
  end

  local beforeActorHand = #state.actor:getCardIds(Player.Hand)
  local beforeTargetHp = state.target.hp
  local useResult = room:handleUseCardReply(state.actor, result)
  if type(useResult) == "table" then
    room:useCard(useResult)
  end

  local effect = table.find(state.skillEffects, function(entry)
    return entry.skill == "ex__fanjian" and entry.player == state.actor.id
  end)
  local fanjianIsDeputy = state.scenario == "hidden-fanjian-deputy"
  local revealedCorrectSlot = fanjianIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__zhouyu"
    or not fanjianIsDeputy and state.actor.general == "hs__zhouyu" and state.actor.deputyGeneral == "anjiang"
  local targetKeptGift = room:getCardOwner(cardId) == state.target and
    table.contains(state.target:getCardIds(Player.Hand), cardId)
  local targetKeptOriginal = table.contains(state.target:getCardIds(Player.Hand), targetCardId)
  if not effect or effect.fake or not revealedCorrectSlot then
    fail("hidden-fanjian must reveal Chu Du in its catalogued slot before a real SkillEffect")
  end
  if state.actor:isFakeSkill("ex__fanjian") or not state.actor:hasSkill("ex__fanjian") then
    fail("hidden-fanjian must convert Phản Gián from fake to active after reveal")
  end
  if beforeActorHand ~= 1 or table.contains(state.actor:getCardIds(Player.Hand), cardId) or
      not targetKeptGift or not targetKeptOriginal then
    fail("hidden-fanjian must give the selected Peach to the target and preserve the target Jink")
  end
  if state.target.hp ~= beforeTargetHp - 1 then
    fail("hidden-fanjian QA must select the native loseHp branch after the gift")
  end

  state.hiddenFanjianBranch = "positive-active-reveal-lose-hp"
  room:sendLog{
    type = "[TQS QA] Hidden Phản Gián: SkillEffect=%arg; vị trí=%arg6; mở Chu Du=%arg2; fake=%arg3; tặng bài=%arg4; mất HP=%arg5",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = tostring(effect.fake),
    arg4 = tostring(targetKeptGift),
    arg5 = tostring(state.target.hp == beforeTargetHp - 1),
    arg6 = fanjianIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-fanjian skill=ex__fanjian effect=true slot=%s main=%s deputy=%s target_hp=%d->%d revision=%s",
    fanjianIsDeputy and "deputy" or "main", state.actor.general, state.actor.deputyGeneral,
    beforeTargetHp, state.target.hp, manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenViewAs(room, state)
  -- Longdan is a ViewAsSkill rather than an ordinary ActiveSkill. The actor
  -- remains fully hidden until the native PlayCard path uses the fake skill.
  -- Clear the target's initial hand so the converted Slash cannot branch into
  -- an unrelated private Jink request during this bounded acceptance case.
  state.target:revealGenerals()
  state.target:throwAllCards("h", "tqs_qa")
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-view-as actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("hs__longdan") then
    fail("hidden-view-as must attach the hidden ViewAsSkill Longdan")
  end
  if state.actor:hasSkill("hs__longdan") then
    fail("hidden-view-as Longdan must not be active before PlayCard")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_view_as_gate",
    prompt = "TQS QA: xác nhận dock Long Đảm đã sẵn sàng, rồi chọn Thiểm như Sát.",
  })
  if not gate then
    fail("hidden-view-as readiness gate was cancelled")
  end

  local cardId = state.slotCards["longdan-card"]
  if not cardId or not table.contains(state.actor:getCardIds(Player.Hand), cardId) then
    fail("hidden-view-as must put its reserved Jink in the actor hand")
  end

  local request = Request:new(state.actor, "PlayCard")
  request.timeout = room.timeout
  local result = request:getResult(state.actor)
  if result == "" or type(result) ~= "table" or type(result.card) ~= "table" then
    fail("hidden-view-as must receive a native PlayCard skill reply")
  end
  if result.card.skill ~= "hs__longdan" then
    fail("hidden-view-as PlayCard must select hs__longdan")
  end
  if type(result.card.subcards) ~= "table" or #result.card.subcards ~= 1 or
      result.card.subcards[1] ~= cardId then
    fail("hidden-view-as Longdan must select exactly the reserved Jink")
  end
  local useResult = room:handleUseCardReply(state.actor, result, {
    extra_data = { bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.target.id }, must_targets = { state.target.id } },
  })
  if type(useResult) ~= "table" or not useResult.card or useResult.card.trueName ~= "slash" or
      not table.contains(useResult.card.skillNames or {}, "hs__longdan") then
    fail("hidden-view-as must convert the reserved Jink into a Longdan Slash")
  end
  room:useCard(useResult)

  local effect = table.find(state.skillEffects, function(entry)
    return entry.skill == "hs__longdan" and entry.player == state.actor.id
  end)
  if not effect then
    fail("hidden-view-as must execute Longdan through native SkillEffect")
  end
  local mainIsZhaoyun = state.scenario == "hidden-view-as-main"
  local revealedCorrectSlot = mainIsZhaoyun
    and state.actor.general == "hs__zhaoyun" and state.actor.deputyGeneral == "anjiang"
    or not mainIsZhaoyun and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__zhaoyun"
  if not revealedCorrectSlot then
    fail("hidden-view-as must reveal Triệu Vân in its catalogued slot")
  end
  if state.actor:isFakeSkill("hs__longdan") or not state.actor:hasSkill("hs__longdan") then
    fail("hidden-view-as must convert Longdan from fake to active after reveal")
  end
  if (mainIsZhaoyun and (effect.general ~= "hs__zhaoyun" or effect.deputyGeneral ~= "anjiang")) or
      (not mainIsZhaoyun and (effect.general ~= "anjiang" or effect.deputyGeneral ~= "hs__zhaoyun")) or effect.fake then
    fail("hidden-view-as must reveal Triệu Vân before Longdan SkillEffect")
  end

  room:sendLog{
    type = "[TQS QA] Hidden Long Đảm: SkillEffect=%arg; Triệu Vân đã mở=%arg2; vị trí=%arg3; Thiểm→Sát=%arg4",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = mainIsZhaoyun and "chủ tướng" or "phó tướng",
    arg4 = "true",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-view-as skill=hs__longdan effect=true slot=%s main=%s deputy=%s converted=true revision=%s",
    mainIsZhaoyun and "main" or "deputy", state.actor.general, state.actor.deputyGeneral,
    manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenDual(room, state)
  -- The actor remains face-down while the real trigger is prelighted. The
  -- target is public and owns exactly one red Jink so the source color and the
  -- later opposite-color ViewAs card are deterministic.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-dual actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("hs__shuangxiong") then
    fail("hidden-dual must attach the hidden dual trigger/ViewAs skill")
  end
  if state.actor:hasSkill("hs__shuangxiong") then
    fail("hidden-dual must not be active before the prelighted phase trigger")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_dual_gate",
    prompt = "TQS QA: xác nhận dock Song Hùng đã sẵn sàng, rồi kích hoạt trigger úp.",
  })
  if not gate then
    fail("hidden-dual readiness gate was cancelled")
  end
  if not isPrelighted(state.actor, "hs__shuangxiong") then
    fail("hidden-dual must be prelighted before the EventPhaseStart branch")
  end

  local actorCardId = state.slotCards["shuangxiong-card"]
  local discardCardId = state.slotCards["shuangxiong-discard"]
  local targetInitialHand = #state.target:getCardIds(Player.Hand)
  if targetInitialHand ~= 1 or not table.contains(state.actor:getCardIds(Player.Hand), actorCardId) or
      not table.contains(state.target:getCardIds(Player.Hand), discardCardId) then
    fail("hidden-dual must start with exactly the catalogued actor Slash and target Jink")
  end

  -- Reproduce the engine's phase-start contract without running a full random
  -- turn. The source skill itself still owns the real cost/effect chain below.
  room:setPlayerProperty(state.actor, "phase", Player.Play)
  room:broadcastProperty(state.actor, "phase")
  room.logic:trigger(fk.EventPhaseStart, state.actor, {
    who = state.actor,
    phase = Player.Play,
  })

  local triggerEffects = table.filter(state.skillEffects, function(entry)
    return entry.skill == "hs__shuangxiong" and entry.player == state.actor.id
  end)
  if #triggerEffects < 1 then
    fail("hidden-dual prelighted EventPhaseStart must execute a native SkillEffect")
  end
  local triggerEffect = triggerEffects[1]
  if triggerEffect.fake then
    fail("hidden-dual must reveal before the native trigger SkillEffect")
  end
  if state.actor.general ~= "hs__yanliangwenchou" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-dual must reveal Yan Liang/Wen Chou in the catalogued main slot")
  end
  if state.actor:isFakeSkill("hs__shuangxiong") or not state.actor:hasSkill("hs__shuangxiong") then
    fail("hidden-dual must convert the dual skill from fake to active before its cost chain")
  end

  local mark = state.actor:getMark("@hs__shuangxiong-turn")
  if mark ~= Fk:getCardById(discardCardId):getColorString() or mark ~= "red" then
    fail("hidden-dual must record the discarded red card color before ViewAs")
  end
  if #state.target:getCardIds(Player.Hand) ~= 0 then
    fail("hidden-dual target must discard the catalogued Jink")
  end

  local request = Request:new(state.actor, "PlayCard")
  request.timeout = room.timeout
  local result = request:getResult(state.actor)
  if result == "" or type(result) ~= "table" or type(result.card) ~= "table" then
    fail("hidden-dual must receive a native PlayCard ViewAs reply")
  end
  if result.card.skill ~= "hs__shuangxiong" then
    fail("hidden-dual PlayCard must select hs__shuangxiong")
  end
  if type(result.card.subcards) ~= "table" or #result.card.subcards ~= 1 or
      result.card.subcards[1] ~= actorCardId then
    fail("hidden-dual PlayCard must select exactly the catalogued opposite-color Slash")
  end

  local useResult = room:handleUseCardReply(state.actor, result, {
    extra_data = { bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.target.id }, must_targets = { state.target.id } },
  })
  if type(useResult) ~= "table" or not useResult.card or useResult.card.trueName ~= "duel" or
      not table.contains(useResult.card.skillNames or {}, "hs__shuangxiong") or
      not table.contains(useResult.card.subcards or {}, actorCardId) then
    fail("hidden-dual must convert the opposite-color Slash into a native Duel")
  end
  room:useCard(useResult)

  local effectsAfter = table.filter(state.skillEffects, function(entry)
    return entry.skill == "hs__shuangxiong" and entry.player == state.actor.id
  end)
  if #effectsAfter < 2 or table.contains(state.actor:getCardIds(Player.Hand), actorCardId) then
    fail("hidden-dual must execute the ViewAs Duel and consume the catalogued Slash")
  end

  room:sendLog{
    type = "[TQS QA] Hidden Song Hùng: trigger SkillEffect=%arg; mở chủ=%arg2; bỏ bài đỏ=%arg3; Duel khác màu=%arg4",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = "true",
    arg4 = "true",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-dual skill=hs__shuangxiong trigger=true view_as_duel=true slot=main revision=%s",
    manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function moveJudgmentColorsToTop(room)
  local blackId, redId
  for index = #room.draw_pile, 1, -1 do
    local id = room.draw_pile[index]
    local color = Fk:getCardById(id):getColorString()
    if not blackId and color == "black" then
      blackId = table.remove(room.draw_pile, index)
    elseif not redId and color == "red" then
      redId = table.remove(room.draw_pile, index)
    end
    if blackId and redId then break end
  end
  if not blackId or not redId then
    fail("hidden-luoshen needs one black and one red native judgment card")
  end
  -- Luoshen sees the black card first, then the red card ends the loop. The
  -- QA fixture only fixes the pile order; the source skill still owns judge,
  -- reveal-before-effect, optional continuation and obtaining the black card.
  table.insert(room.draw_pile, 1, redId)
  table.insert(room.draw_pile, 1, blackId)
  room:syncDrawPile()
  return blackId, redId
end

local function triggerHiddenTiandu(room, state)
  -- Thiên Đố is a mandatory FinishJudge effect. The only client-controlled
  -- gate here is the native prelight request; the actual judge and obtain
  -- path must remain the source skill's real SkillEffect flow.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-tiandu actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("tiandu") then
    fail("hidden-tiandu must attach the hidden Tiandu skill")
  end
  if state.actor:hasSkill("tiandu") then
    fail("hidden-tiandu must not be active before the prelighted FinishJudge")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_tiandu_gate",
    prompt = "TQS QA: prelight Thiên Đố, rồi xác nhận để bắt đầu phán xét.",
  })
  if not gate then
    fail("hidden-tiandu readiness gate was cancelled")
  end
  if not isPrelighted(state.actor, "tiandu") then
    fail("hidden-tiandu must be prelighted before the FinishJudge branch")
  end

  local judgedId = moveJudgmentColorsToTop(room)
  state.currentDamageStep = 1
  local judge = {
    who = state.actor,
    reason = "tiandu",
    pattern = ".",
  }
  room:judge(judge)
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "tiandu" and entry.player == state.actor.id
  end)
  local tianduIsDeputy = state.scenario == "hidden-tiandu-deputy"
  local revealedCorrectSlot = tianduIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__guojia"
    or not tianduIsDeputy and state.actor.general == "hs__guojia" and state.actor.deputyGeneral == "anjiang"
  local obtained = movedFromArea(state, 1, "tiandu", state.actor, Card.Processing)
  if not effect or effect.fake or not revealedCorrectSlot then
    fail("prelighted hidden Tiandu must run a real SkillEffect and reveal Guo Jia in its catalogued slot")
  end
  if not judge.card or judge.card:getEffectiveId() ~= judgedId or obtained ~= 1 or
      not table.contains(state.actor:getCardIds(Player.Hand), judgedId) then
    fail("hidden Tiandu must obtain the judged card from Card.Processing")
  end
  if state.actor:isFakeSkill("tiandu") or not state.actor:hasSkill("tiandu") then
    fail("hidden Tiandu must convert from fake to active after reveal")
  end

  local position = tianduIsDeputy and "phó tướng" or "chủ tướng"
  room:sendLog{
    type = "[TQS QA] Hidden Thiên Đố: FinishJudge=%arg; SkillEffect=%arg2; lấy lá phán xét=%arg3; mở tướng=%arg4; vị trí=%arg5",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = tostring(obtained == 1),
    arg4 = tostring(revealedCorrectSlot),
    arg5 = position,
  }
  fk.qInfo(string.format("[tqs_qa] hidden-tiandu finish_judge=true skill_effect=true obtained=%d revealed=%s slot=%s revision=%s",
    obtained, tostring(revealedCorrectSlot), tianduIsDeputy and "deputy" or "main", manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenLuoshen(room, state)
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-luoshen actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("hs__luoshen") then
    fail("hidden-luoshen must attach the hidden Luoshen skill")
  end
  if state.actor:hasSkill("hs__luoshen") then
    fail("hidden-luoshen must not be active before the prelighted phase trigger")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_luoshen_gate",
    prompt = "TQS QA: prelight 洛神, rồi xác nhận để bắt đầu pha chuẩn bị.",
  })
  if not gate then
    fail("hidden-luoshen readiness gate was cancelled")
  end
  if not isPrelighted(state.actor, "hs__luoshen") then
    fail("hidden-luoshen must be prelighted before the EventPhaseStart branch")
  end

  local blackId = moveJudgmentColorsToTop(room)
  state.currentDamageStep = 1
  room:setPlayerProperty(state.actor, "phase", Player.Start)
  room:broadcastProperty(state.actor, "phase")
  room.logic:trigger(fk.EventPhaseStart, state.actor, {
    who = state.actor,
    phase = Player.Start,
  })
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.skill == "hs__luoshen" and entry.player == state.actor.id
  end)
  local luoshenIsDeputy = state.scenario == "hidden-luoshen-deputy"
  local revealedCorrectSlot = luoshenIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__zhenji"
    or not luoshenIsDeputy and state.actor.general == "hs__zhenji" and state.actor.deputyGeneral == "anjiang"
  local obtained = movedFromArea(state, 1, "hs__luoshen", state.actor, Card.Processing)
  if not effect or effect.fake or not revealedCorrectSlot then
    fail("prelighted hidden Luoshen must run a real SkillEffect and reveal Zhen Ji in its catalogued slot")
  end
  if obtained ~= 1 or not table.contains(state.actor:getCardIds(Player.Hand), blackId) then
    fail("hidden Luoshen must obtain the black judgment card after the red stop card")
  end
  if state.actor:isFakeSkill("hs__luoshen") or not state.actor:hasSkill("hs__luoshen") then
    fail("hidden Luoshen must convert from fake to active after reveal")
  end

  state.hiddenLuoshenBranch = "positive-prelight-phase-start-judge-obtain"
  room:sendLog{
    type = "[TQS QA] Hidden 洛神: %arg; vị trí=%arg6; prelight=%arg2; SkillEffect=%arg3; mở tướng=%arg4; lấy bài đen=%arg5",
    from = state.actor.id,
    arg = state.hiddenLuoshenBranch,
    arg2 = "true",
    arg3 = "true",
    arg4 = tostring(revealedCorrectSlot),
    arg5 = tostring(obtained),
    arg6 = luoshenIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-luoshen branch=%s slot=%s prelight=true invoked=true revealed=%s obtained=%d revision=%s",
    state.hiddenLuoshenBranch, luoshenIsDeputy and "deputy" or "main", tostring(revealedCorrectSlot), obtained,
    manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenJizhi(room, state)
  -- 集智 is an optional CardUsing effect. The actor stays face-down while a
  -- real common Trick is used; the source SkillEffect must reveal only the
  -- Huang Yueying slot before asking whether to draw.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-jizhi actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("hs__jizhi") then
    fail("hidden-jizhi must attach the hidden Jizhi skill")
  end
  if state.actor:hasSkill("hs__jizhi") then
    fail("hidden-jizhi must not be active before CardUsing")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_jizhi_gate",
    prompt = "TQS QA: prelight Tập Trí, rồi xác nhận để dùng Lạc Hồn.",
  })
  if not gate then
    fail("hidden-jizhi readiness gate was cancelled")
  end
  if not isPrelighted(state.actor, "hs__jizhi") then
    fail("hidden-jizhi must be prelighted before the CardUsing branch")
  end

  local cardId = state.slotCards["jizhi-card"]
  if not cardId or not table.contains(state.actor:getCardIds(Player.Hand), cardId) then
    fail("hidden-jizhi must put its reserved Duel in the actor hand")
  end

  local beforeHand = #state.actor:getCardIds(Player.Hand)
  state.currentDamageStep = 1
  local use = room:askToUseRealCard(state.actor, {
    pattern = { cardId },
    skill_name = "tqs_qa_hidden_jizhi_card",
    prompt = "TQS QA: dùng Lạc Hồn lên đối thủ để kiểm tra Tập Trí.",
    extra_data = {
      bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.target.id }, must_targets = { state.target.id },
    },
    cancelable = true,
    skip = true,
  })
  if not use or not use.card or use.card.id ~= cardId or use.card.trueName ~= "duel" or
      #use.tos ~= 1 or use.tos[1] ~= state.target then
    fail("hidden-jizhi must receive the reserved Duel against the catalog target")
  end
  use.extraUse = true
  room:useCard(use)
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "hs__jizhi" and entry.player == state.actor.id
  end)
  local jizhiIsDeputy = state.scenario == "hidden-jizhi-deputy"
  local revealedCorrectSlot = jizhiIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__huangyueying"
    or not jizhiIsDeputy and state.actor.general == "hs__huangyueying" and state.actor.deputyGeneral == "anjiang"
  local afterHand = #state.actor:getCardIds(Player.Hand)
  local drawn = movedFromArea(state, 1, "hs__jizhi", state.actor, Card.DrawPile)
  if not effect or effect.fake or not revealedCorrectSlot then
    fail("prelighted hidden Jizhi must run a real SkillEffect and reveal Huang Yueying in its catalogued slot")
  end
  if afterHand ~= beforeHand or table.contains(state.actor:getCardIds(Player.Hand), cardId) or drawn ~= 1 then
    fail("hidden Jizhi must consume the Duel and draw exactly one card through its native effect")
  end
  if state.actor:isFakeSkill("hs__jizhi") or not state.actor:hasSkill("hs__jizhi") then
    fail("hidden Jizhi must convert from fake to active after reveal")
  end

  room:sendLog{
    type = "[TQS QA] Hidden Tập Trí: CardUsing Duel=%arg; SkillEffect=%arg2; mở tướng=%arg3; rút bài=%arg4; vị trí=%arg5",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = tostring(revealedCorrectSlot),
    arg4 = tostring(drawn),
    arg5 = jizhiIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-jizhi card_using=duel effect=true slot=%s revealed=%s drawn=%d revision=%s",
    jizhiIsDeputy and "deputy" or "main", tostring(revealedCorrectSlot), drawn, manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenMingshi(room, state)
  -- 名士 is compulsory and only checks whether the damage source still has an
  -- unrevealed slot. Keep both players hidden until the real Slash reaches
  -- DamageInflicted; the target must remain hidden after the effect as well.
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-mingshi actor must start with both generals hidden")
  end
  if state.target.general ~= "anjiang" or state.target.deputyGeneral ~= "anjiang" then
    fail("hidden-mingshi source must remain hidden so DamageInflicted can see anjiang")
  end
  if not state.actor:isFakeSkill("mingshi") then
    fail("hidden-mingshi must attach the hidden Mingshi skill")
  end
  if state.actor:hasSkill("mingshi") then
    fail("hidden-mingshi must not be active before DamageInflicted")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_mingshi_gate",
    prompt = "TQS QA: prelight Danh Sĩ, rồi xác nhận để nguồn úp dùng Sát.",
  })
  if not gate then
    fail("hidden-mingshi readiness gate was cancelled")
  end
  if not isPrelighted(state.actor, "mingshi") then
    fail("hidden-mingshi must be prelighted before the DamageInflicted branch")
  end

  local cardId = state.slotCards["mingshi-damage"]
  if not cardId or not table.contains(state.target:getCardIds(Player.Hand), cardId) then
    fail("hidden-mingshi must put its reserved hidden-source Slash in the target hand")
  end
  local beforeHp = state.actor.hp
  state.currentDamageStep = 1
  local use = room:askToUseRealCard(state.target, {
    pattern = { cardId },
    skill_name = "tqs_qa_hidden_mingshi_damage",
    prompt = "TQS QA: dùng Sát lên Khổng Dung để kiểm tra Danh Sĩ.",
    extra_data = {
      bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.actor.id }, must_targets = { state.actor.id },
    },
    cancelable = true,
    skip = true,
  })
  if not use or not use.card or use.card.id ~= cardId or use.card.trueName ~= "slash" or
      #use.tos ~= 1 or use.tos[1] ~= state.actor then
    fail("hidden-mingshi must receive the reserved hidden-source Slash against the actor")
  end
  use.extraUse = true
  room:useCard(use)
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "mingshi" and entry.player == state.actor.id
  end)
  local mingshiIsDeputy = state.scenario == "hidden-mingshi-deputy"
  local revealedCorrectSlot = mingshiIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__kongrong"
    or not mingshiIsDeputy and state.actor.general == "hs__kongrong" and state.actor.deputyGeneral == "anjiang"
  if not effect or effect.fake or not revealedCorrectSlot then
    fail("prelighted hidden Mingshi must run a real SkillEffect and reveal Kong Rong in its catalogued slot")
  end
  if state.actor.hp ~= beforeHp then
    fail("hidden Mingshi must reduce the one Slash damage to zero")
  end
  if state.target.general ~= "anjiang" or state.target.deputyGeneral ~= "anjiang" then
    fail("hidden Mingshi must not reveal the hidden damage source")
  end
  if state.actor:isFakeSkill("mingshi") or not state.actor:hasSkill("mingshi") then
    fail("hidden Mingshi must convert from fake to active after reveal")
  end

  room:sendLog{
    type = "[TQS QA] Hidden Danh Sĩ: DamageInflicted=%arg; SkillEffect=%arg2; mở tướng=%arg3; sát thương=0; vị trí=%arg4",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = tostring(revealedCorrectSlot),
    arg4 = mingshiIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-mingshi damage_inflicted=zero effect=true slot=%s revealed=%s source_hidden=true revision=%s",
    mingshiIsDeputy and "deputy" or "main", tostring(revealedCorrectSlot), manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenGongqing(room, state)
  -- 公清 has two independent DamageInflicted paths in the source package:
  -- low attack range collapses damage to 1 through DetermineDamageInflicted,
  -- while high attack range adds one through DamageInflicted.  Keep 潘濬
  -- hidden until the first native effect so this also proves slot ownership
  -- and fake-skill conversion on both main/deputy placements.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-gongqing actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("gongqing") then
    fail("hidden-gongqing must attach the hidden Gongqing skill")
  end
  if state.actor:hasSkill("gongqing") then
    fail("hidden-gongqing must not be active before the first damage branch")
  end

  -- The paired roster can otherwise start at three HP, while the two source
  -- branches intentionally deal 1 + 2 damage. Increase only the QA actor's
  -- life total so the second native branch completes without entering Dying.
  room:setPlayerProperty(state.actor, "maxHp", 5)
  room:setPlayerProperty(state.actor, "hp", 5)

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_gongqing_gate",
    prompt = "TQS QA: prelight Công Thanh, rồi xác nhận để kiểm tra hai nhánh tầm đánh.",
  })
  if not gate then
    fail("hidden-gongqing readiness gate was cancelled")
  end
  if not isPrelighted(state.actor, "gongqing") then
    fail("hidden-gongqing must be prelighted before the damage branches")
  end

  local bowId = state.slotCards["gongqing-bow"]
  if not bowId or not table.contains(state.target:getCardIds(Player.Hand), bowId) then
    fail("hidden-gongqing must put the reserved Kylin Bow in the source hand")
  end
  local lowRange = state.target:getAttackRange() < 3
  local beforeLowHp = state.actor.hp
  state.currentDamageStep = 1
  room:damage({
    from = state.target,
    to = state.actor,
    damage = 2,
    skillName = "tqs_qa_hidden_gongqing_low_range",
  })
  state.currentDamageStep = nil

  if not lowRange or not state.actor:hasSkill("gongqing") or state.actor:isFakeSkill("gongqing") then
    fail("hidden-gongqing must reveal and activate before the low-range damage effect")
  end
  if not table.contains(state.target:getCardIds(Player.Hand), bowId) then
    fail("hidden-gongqing source Kylin Bow must remain available for the high-range branch")
  end

  room:moveCardTo(bowId, Card.PlayerEquip, state.target, fk.ReasonJustMove, "tqs_qa", nil, true, state.target)
  local highRange = state.target:getAttackRange() > 3
  if not highRange then
    fail("hidden-gongqing Kylin Bow must raise the source attack range above 3")
  end

  local beforeHighHp = state.actor.hp
  state.currentDamageStep = 2
  room:damage({
    from = state.target,
    to = state.actor,
    damage = 1,
    skillName = "tqs_qa_hidden_gongqing_high_range",
  })
  state.currentDamageStep = nil

  local lowDamage = 0
  local highDamage = 0
  for _, entry in ipairs(state.damageEvents) do
    if entry.to == state.actor.id and entry.step == 1 then
      lowDamage = lowDamage + entry.amount
    elseif entry.to == state.actor.id and entry.step == 2 then
      highDamage = highDamage + entry.amount
    end
  end
  local lowEffect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "gongqing" and entry.player == state.actor.id
  end)
  local highEffect = table.find(state.skillEffects, function(entry)
    return entry.step == 2 and entry.skill == "gongqing" and entry.player == state.actor.id
  end)
  local gongqingIsDeputy = state.scenario == "hidden-gongqing-deputy"
  local revealedCorrectSlot = gongqingIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "panjun"
    or not gongqingIsDeputy and state.actor.general == "panjun" and state.actor.deputyGeneral == "anjiang"
  if not lowEffect or lowEffect.fake or not highEffect or highEffect.fake or not revealedCorrectSlot then
    fail("prelighted hidden Gongqing must run both real SkillEffects and reveal Pan Jun in its catalogued slot")
  end
  if lowDamage ~= 1 or highDamage ~= 2 or beforeLowHp - state.actor.hp ~= 3 or
      beforeLowHp - beforeHighHp ~= 1 or beforeHighHp - state.actor.hp ~= 2 then
    fail(string.format("hidden Gongqing must resolve low/high damage as 1/2, observed %d/%d", lowDamage, highDamage))
  end
  if state.actor:isFakeSkill("gongqing") or not state.actor:hasSkill("gongqing") then
    fail("hidden Gongqing must remain active after both native damage branches")
  end

  room:sendLog{
    type = "[TQS QA] Hidden Công Thanh: DetermineDamageInflicted=%arg; DamageInflicted=%arg2; SkillEffect=%arg3; mở tướng=%arg4; sát thương thấp=%arg5; sát thương xa=%arg6; vị trí=%arg7",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = tostring(not lowEffect.fake and not highEffect.fake),
    arg4 = tostring(revealedCorrectSlot),
    arg5 = tostring(lowDamage),
    arg6 = tostring(highDamage),
    arg7 = gongqingIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-gongqing determine_damage_inflicted=true damage_inflicted=true effects=2 damage_low=%d damage_high=%d slot=%s revealed=%s revision=%s",
    lowDamage, highDamage, gongqingIsDeputy and "deputy" or "main", tostring(revealedCorrectSlot), manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenQianxun(room, state)
  -- 谦逊 is compulsory on TargetConfirming. The actor remains face-down while
  -- a real Snatch has a legal Peach target; the native effect must reveal only
  -- the Lục Tốn slot and cancel that target before Snatch can obtain anything.
  local indulgenceScenario = state.scenario == "hidden-qianxun-indulgence" or
    state.scenario == "hidden-qianxun-indulgence-deputy"
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-qianxun actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("hs__qianxun") then
    fail("hidden-qianxun must attach the hidden Qianxun skill")
  end
  if state.actor:hasSkill("hs__qianxun") then
    fail("hidden-qianxun must not be active before TargetConfirming")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_qianxun_gate",
    prompt = indulgenceScenario
      and "TQS QA: prelight Khiêm Tốn, rồi xác nhận để đối thủ dùng Lạc Bất Tư Thục."
      or "TQS QA: prelight Khiêm Tốn, rồi xác nhận để đối thủ dùng Thuận Thủ.",
  })
  if not gate then
    fail("hidden-qianxun readiness gate was cancelled")
  end
  if not isPrelighted(state.actor, "hs__qianxun") then
    fail("hidden-qianxun must be prelighted before TargetConfirming")
  end

  if indulgenceScenario then
    local indulgenceId = state.slotCards["qianxun-indulgence"]
    if not indulgenceId or not table.contains(state.target:getCardIds(Player.Hand), indulgenceId) then
      fail("hidden-qianxun indulgence must put its reserved Indulgence in the source hand")
    end

    state.currentDamageStep = 1
    local use = room:askToUseRealCard(state.target, {
      pattern = { indulgenceId },
      skill_name = "tqs_qa_hidden_qianxun_indulgence",
      prompt = "TQS QA: dùng Lạc Bất Tư Thục lên Lục Tốn để kiểm tra Khiêm Tốn.",
      extra_data = {
        bypass_times = true, bypass_distances = true, extraUse = true,
        exclusive_targets = { state.actor.id }, must_targets = { state.actor.id },
      },
      cancelable = true,
      skip = true,
    })
    if not use or not use.card or use.card.id ~= indulgenceId or
        use.card.trueName ~= "indulgence" or #use.tos ~= 1 or use.tos[1] ~= state.actor then
      fail("hidden-qianxun indulgence must receive the reserved card against the actor")
    end
    use.extraUse = true
    room:useCard(use)
    state.currentDamageStep = nil

    local effect = table.find(state.skillEffects, function(entry)
      return entry.step == 1 and entry.skill == "hs__qianxun" and entry.player == state.actor.id
    end)
    local qianxunIsDeputy = state.scenario == "hidden-qianxun-indulgence-deputy"
    local revealedCorrectSlot = qianxunIsDeputy
      and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__luxun"
      or not qianxunIsDeputy and state.actor.general == "hs__luxun" and state.actor.deputyGeneral == "anjiang"
    local cancelledJudgeMove = room:getCardArea(indulgenceId) == Card.DiscardPile and
      #state.actor:getCardIds(Player.Judge) == 0
    if not effect or effect.fake or not revealedCorrectSlot then
      fail("prelighted hidden Qianxun must run a real SkillEffect and reveal Lục Tốn in its catalogued slot")
    end
    if not cancelledJudgeMove then
      fail("hidden Qianxun must cancel the Indulgence judge move and discard the card")
    end
    if state.actor:isFakeSkill("hs__qianxun") or not state.actor:hasSkill("hs__qianxun") then
      fail("hidden Qianxun must convert from fake to active after reveal")
    end

    room:sendLog{
      type = "[TQS QA] Hidden Khiêm Tốn: BeforeCardsMove Lạc Bất Tư Thục=%arg; SkillEffect=%arg2; mở tướng=%arg3; vào phán xét=%arg4; chuyển bỏ=%arg5; vị trí=%arg6",
      from = state.actor.id,
      arg = "true",
      arg2 = "true",
      arg3 = tostring(revealedCorrectSlot),
      arg4 = "false",
      arg5 = tostring(cancelledJudgeMove),
      arg6 = qianxunIsDeputy and "phó tướng" or "chủ tướng",
    }
    fk.qInfo(string.format("[tqs_qa] hidden-qianxun before_cards_move=indulgence effect=true slot=%s revealed=%s judge_move_cancelled=%s discarded=true revision=%s",
      qianxunIsDeputy and "deputy" or "main", tostring(revealedCorrectSlot), tostring(cancelledJudgeMove), manifest.sourceRevision))
    state.gameOverRequested = true
    room:gameOver("")
    return
  end

  local snatchId = state.slotCards["qianxun-snatch"]
  local victimId = state.slotCards["qianxun-victim"]
  if not snatchId or not table.contains(state.target:getCardIds(Player.Hand), snatchId) then
    fail("hidden-qianxun must put its reserved Snatch in the source hand")
  end
  if not victimId or not table.contains(state.actor:getCardIds(Player.Hand), victimId) then
    fail("hidden-qianxun must put a legal actor Peach target in hand")
  end

  state.currentDamageStep = 1
  local use = room:askToUseRealCard(state.target, {
    pattern = { snatchId },
    skill_name = "tqs_qa_hidden_qianxun_snatch",
    prompt = "TQS QA: dùng Thuận Thủ lên Lục Tốn để kiểm tra Khiêm Tốn.",
    extra_data = {
      bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.actor.id }, must_targets = { state.actor.id },
    },
    cancelable = true,
    skip = true,
  })
  if not use or not use.card or use.card.id ~= snatchId or use.card.trueName ~= "snatch" or
      #use.tos ~= 1 or use.tos[1] ~= state.actor then
    fail("hidden-qianxun must receive the reserved Snatch against the actor")
  end
  use.extraUse = true
  room:useCard(use)
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "hs__qianxun" and entry.player == state.actor.id
  end)
  local qianxunIsDeputy = state.scenario == "hidden-qianxun-deputy"
  local revealedCorrectSlot = qianxunIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__luxun"
    or not qianxunIsDeputy and state.actor.general == "hs__luxun" and state.actor.deputyGeneral == "anjiang"
  local targetCancelled = room:getCardArea(snatchId) == Card.DiscardPile and
    room:getCardOwner(victimId) == state.actor and
    table.contains(state.actor:getCardIds(Player.Hand), victimId)
  if not effect or effect.fake or not revealedCorrectSlot then
    fail("prelighted hidden Qianxun must run a real SkillEffect and reveal Lục Tốn in its catalogued slot")
  end
  if not targetCancelled then
    fail("hidden Qianxun must cancel the valid Snatch target before any card is obtained")
  end
  if state.actor:isFakeSkill("hs__qianxun") or not state.actor:hasSkill("hs__qianxun") then
    fail("hidden Qianxun must convert from fake to active after reveal")
  end

  room:sendLog{
    type = "[TQS QA] Hidden Khiêm Tốn: TargetConfirming Thuận Thủ=%arg; SkillEffect=%arg2; mở tướng=%arg3; hủy mục tiêu=%arg4; vị trí=%arg5",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = tostring(revealedCorrectSlot),
    arg4 = tostring(targetCancelled),
    arg5 = qianxunIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-qianxun target_confirming=snatch effect=true slot=%s revealed=%s cancelled=%s victim_retained=true revision=%s",
    qianxunIsDeputy and "deputy" or "main", tostring(revealedCorrectSlot), tostring(targetCancelled), manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenKongcheng(room, state)
  -- 空城's TargetConfirming branch is conditional on a genuinely empty hand.
  -- Empty the actor through the native move path before the real Duel so the
  -- scenario proves the source predicate instead of merely proving reveal.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-kongcheng actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("hs__kongcheng") then
    fail("hidden-kongcheng must attach the hidden Kongcheng skill")
  end
  if state.actor:hasSkill("hs__kongcheng") then
    fail("hidden-kongcheng must not be active before TargetConfirming")
  end
  state.actor:throwAllCards("h", "tqs_qa")
  if not state.actor:isKongcheng() then
    fail("hidden-kongcheng actor must be empty-handed before the Duel gate")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_kongcheng_gate",
    prompt = "TQS QA: prelight Không Thành, rồi xác nhận để đối thủ dùng Quyết Đấu.",
  })
  if not gate then
    fail("hidden-kongcheng readiness gate was cancelled")
  end
  if not isPrelighted(state.actor, "hs__kongcheng") then
    fail("hidden-kongcheng must be prelighted before TargetConfirming")
  end

  local duelId = state.slotCards["kongcheng-duel"]
  if not duelId or not table.contains(state.target:getCardIds(Player.Hand), duelId) then
    fail("hidden-kongcheng must put its reserved Duel in the source hand")
  end

  state.currentDamageStep = 1
  local use = room:askToUseRealCard(state.target, {
    pattern = { duelId },
    skill_name = "tqs_qa_hidden_kongcheng_duel",
    prompt = "TQS QA: dùng Quyết Đấu lên Gia Cát Lượng để kiểm tra Không Thành.",
    extra_data = {
      bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.actor.id }, must_targets = { state.actor.id },
    },
    cancelable = true,
    skip = true,
  })
  if not use or not use.card or use.card.id ~= duelId or use.card.trueName ~= "duel" or
      #use.tos ~= 1 or use.tos[1] ~= state.actor then
    fail("hidden-kongcheng must receive the reserved Duel against the actor")
  end
  use.extraUse = true
  room:useCard(use)
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "hs__kongcheng" and entry.player == state.actor.id
  end)
  local kongchengIsDeputy = state.scenario == "hidden-kongcheng-deputy"
  local revealedCorrectSlot = kongchengIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__zhugeliang"
    or not kongchengIsDeputy and state.actor.general == "hs__zhugeliang" and state.actor.deputyGeneral == "anjiang"
  local targetCancelled = room:getCardArea(duelId) == Card.DiscardPile and
    state.actor:isKongcheng()
  if not effect or effect.fake or not revealedCorrectSlot then
    fail("prelighted hidden Kongcheng must run a real SkillEffect and reveal Zhuge Liang in its catalogued slot")
  end
  if not targetCancelled then
    fail("hidden Kongcheng must cancel the valid Duel target while empty-handed")
  end
  if state.actor:isFakeSkill("hs__kongcheng") or not state.actor:hasSkill("hs__kongcheng") then
    fail("hidden Kongcheng must convert from fake to active after reveal")
  end

  room:sendLog{
    type = "[TQS QA] Hidden Không Thành: TargetConfirming Quyết Đấu=%arg; SkillEffect=%arg2; hết bài=%arg3; mở tướng=%arg4; hủy mục tiêu=%arg5; vị trí=%arg6",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = tostring(state.actor:isKongcheng()),
    arg4 = tostring(revealedCorrectSlot),
    arg5 = tostring(targetCancelled),
    arg6 = kongchengIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-kongcheng target_confirming=duel effect=true empty_hand=true slot=%s revealed=%s cancelled=%s revision=%s",
    kongchengIsDeputy and "deputy" or "main", tostring(revealedCorrectSlot), tostring(targetCancelled), manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenWeimu(room, state)
  -- 帷幕 has two separate native branches: TargetConfirming cancels a black
  -- Trick target, while BeforeCardsMove mirrors a black delayed Trick away
  -- from the actor's Judge area. Keep both branches in one scenario family so
  -- hidden main/deputy reveal and fake-to-active conversion are checked the
  -- same way for each source predicate.
  local indulgenceScenario = state.scenario == "hidden-weimu-indulgence" or
    state.scenario == "hidden-weimu-indulgence-deputy"
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-weimu actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("hs__weimu") then
    fail("hidden-weimu must attach the hidden Weimu skill")
  end
  if state.actor:hasSkill("hs__weimu") then
    fail("hidden-weimu must not be active before its source event")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_weimu_gate",
    prompt = indulgenceScenario
      and "TQS QA: prelight 帷幕, rồi xác nhận để đối thủ dùng Lạc Bất Tư Thục đen."
      or "TQS QA: prelight 帷幕, rồi xác nhận để đối thủ dùng Quyết Đấu đen.",
  })
  if not gate then
    fail("hidden-weimu readiness gate was cancelled")
  end
  if not isPrelighted(state.actor, "hs__weimu") then
    fail("hidden-weimu must be prelighted before its source event")
  end

  if indulgenceScenario then
    local indulgenceId = state.slotCards["weimu-indulgence"]
    if not indulgenceId or not table.contains(state.target:getCardIds(Player.Hand), indulgenceId) then
      fail("hidden-weimu indulgence must put its reserved black Indulgence in the source hand")
    end

    state.currentDamageStep = 1
    local use = room:askToUseRealCard(state.target, {
      pattern = { indulgenceId },
      skill_name = "tqs_qa_hidden_weimu_indulgence",
      prompt = "TQS QA: dùng Lạc Bất Tư Thục đen lên Giả Hủ để kiểm tra 帷幕.",
      extra_data = {
        bypass_times = true, bypass_distances = true, extraUse = true,
        exclusive_targets = { state.actor.id }, must_targets = { state.actor.id },
      },
      cancelable = true,
      skip = true,
    })
    if not use or not use.card or use.card.id ~= indulgenceId or
        use.card.trueName ~= "indulgence" or use.card:getColorString() ~= "black" or
        #use.tos ~= 1 or use.tos[1] ~= state.actor then
      fail("hidden-weimu indulgence must receive the reserved black Indulgence against the actor")
    end
    use.extraUse = true
    room:useCard(use)
    state.currentDamageStep = nil

    local effect = table.find(state.skillEffects, function(entry)
      return entry.step == 1 and entry.skill == "hs__weimu" and entry.player == state.actor.id
    end)
    local weimuIsDeputy = state.scenario == "hidden-weimu-indulgence-deputy"
    local revealedCorrectSlot = weimuIsDeputy
      and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__jiaxu"
      or not weimuIsDeputy and state.actor.general == "hs__jiaxu" and state.actor.deputyGeneral == "anjiang"
    local cancelledJudgeMove = room:getCardArea(indulgenceId) == Card.DiscardPile and
      #state.actor:getCardIds(Player.Judge) == 0
    if not effect or effect.fake or not revealedCorrectSlot then
      fail("prelighted hidden Weimu must run a real SkillEffect and reveal Jia Xu in its catalogued slot")
    end
    if not cancelledJudgeMove then
      fail("hidden Weimu must cancel the black Indulgence judge move and discard the card")
    end
    if state.actor:isFakeSkill("hs__weimu") or not state.actor:hasSkill("hs__weimu") then
      fail("hidden Weimu must convert from fake to active after reveal")
    end

    room:sendLog{
      type = "[TQS QA] Hidden 帷幕: BeforeCardsMove Lạc Bất Tư Thục đen=%arg; SkillEffect=%arg2; mở tướng=%arg3; vào phán xét=%arg4; chuyển bỏ=%arg5; vị trí=%arg6",
      from = state.actor.id,
      arg = "true",
      arg2 = "true",
      arg3 = tostring(revealedCorrectSlot),
      arg4 = "false",
      arg5 = tostring(cancelledJudgeMove),
      arg6 = weimuIsDeputy and "phó tướng" or "chủ tướng",
    }
    fk.qInfo(string.format("[tqs_qa] hidden-weimu before_cards_move=black_indulgence effect=true slot=%s revealed=%s judge_move_cancelled=%s discarded=true revision=%s",
      weimuIsDeputy and "deputy" or "main", tostring(revealedCorrectSlot), tostring(cancelledJudgeMove), manifest.sourceRevision))
    state.gameOverRequested = true
    room:gameOver("")
    return
  end

  local duelId = state.slotCards["weimu-duel"]
  if not duelId or not table.contains(state.target:getCardIds(Player.Hand), duelId) then
    fail("hidden-weimu must put its reserved black Duel in the source hand")
  end

  local beforeHp = state.actor.hp
  state.currentDamageStep = 1
  local use = room:askToUseRealCard(state.target, {
    pattern = { duelId },
    skill_name = "tqs_qa_hidden_weimu_duel",
    prompt = "TQS QA: dùng Quyết Đấu đen lên Giả Hủ để kiểm tra 帷幕.",
    extra_data = {
      bypass_times = true, bypass_distances = true, extraUse = true,
      exclusive_targets = { state.actor.id }, must_targets = { state.actor.id },
    },
    cancelable = true,
    skip = true,
  })
  if not use or not use.card or use.card.id ~= duelId or use.card.trueName ~= "duel" or
      use.card:getColorString() ~= "black" or #use.tos ~= 1 or use.tos[1] ~= state.actor then
    fail("hidden-weimu must receive the reserved black Duel against the actor")
  end
  use.extraUse = true
  room:useCard(use)
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "hs__weimu" and entry.player == state.actor.id
  end)
  local weimuIsDeputy = state.scenario == "hidden-weimu-deputy"
  local revealedCorrectSlot = weimuIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__jiaxu"
    or not weimuIsDeputy and state.actor.general == "hs__jiaxu" and state.actor.deputyGeneral == "anjiang"
  local targetCancelled = room:getCardArea(duelId) == Card.DiscardPile and state.actor.hp == beforeHp
  if not effect or effect.fake or not revealedCorrectSlot then
    fail("prelighted hidden Weimu must run a real SkillEffect and reveal Jia Xu in its catalogued slot")
  end
  if not targetCancelled then
    fail("hidden Weimu must cancel the valid black Duel target before damage")
  end
  if state.actor:isFakeSkill("hs__weimu") or not state.actor:hasSkill("hs__weimu") then
    fail("hidden Weimu must convert from fake to active after reveal")
  end

  room:sendLog{
    type = "[TQS QA] Hidden 帷幕: TargetConfirming Quyết Đấu đen=%arg; SkillEffect=%arg2; mở tướng=%arg3; hủy mục tiêu=%arg4; vị trí=%arg5",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = tostring(revealedCorrectSlot),
    arg4 = tostring(targetCancelled),
    arg5 = weimuIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-weimu target_confirming=black_duel effect=true slot=%s revealed=%s cancelled=%s damage=0 revision=%s",
    weimuIsDeputy and "deputy" or "main", tostring(revealedCorrectSlot), tostring(targetCancelled), manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenXiaoji(room, state)
  -- 枭姬 is an AfterCardsMove trigger. The actor remains face-down while a
  -- real equipment card is moved out of PlayerEquip; the native effect must
  -- reveal Sun Shangxiang in the owning slot before drawing.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-xiaoji actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("hs__xiaoji") then
    fail("hidden-xiaoji must attach the hidden Xiaoji skill")
  end
  if state.actor:hasSkill("hs__xiaoji") then
    fail("hidden-xiaoji must not be active before AfterCardsMove")
  end

  local equipId = state.slotCards["xiaoji-equip"]
  if not equipId or room:getCardArea(equipId) ~= Card.PlayerEquip or
      not table.contains(state.actor:getCardIds(Player.Equip), equipId) then
    fail("hidden-xiaoji must put its reserved equipment in the actor equipment area")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_xiaoji_gate",
    prompt = "TQS QA: prelight 枭姬, rồi xác nhận để mất trang bị thật.",
  })
  if not gate then
    fail("hidden-xiaoji QA gate was cancelled")
  end
  if not isPrelighted(state.actor, "hs__xiaoji") then
    fail("hidden-xiaoji must be prelighted before the equipment-loss branch")
  end

  local beforeHand = #state.actor:getCardIds(Player.Hand)
  local expectedDraw = room.current == state.actor and 1 or 3
  state.currentDamageStep = 1
  room:throwCard(equipId, "tqs_qa_hidden_xiaoji", state.actor, state.actor)
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "hs__xiaoji" and entry.player == state.actor.id
  end)
  local xiaojiIsDeputy = state.scenario == "hidden-xiaoji-deputy"
  local revealedCorrectSlot = xiaojiIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__sunshangxiang"
    or not xiaojiIsDeputy and state.actor.general == "hs__sunshangxiang" and state.actor.deputyGeneral == "anjiang"
  local drawn = 0
  for _, move in ipairs(state.skillMoves) do
    if move.step == 1 and move.skill == "hs__xiaoji" and move.to == state.actor.id and
        move.fromArea == Card.DrawPile then
      drawn = drawn + move.count
    end
  end
  local afterHand = #state.actor:getCardIds(Player.Hand)
  if not effect or effect.fake or not revealedCorrectSlot then
    fail("prelighted hidden Xiaoji must run a real SkillEffect and reveal Sun Shangxiang in its catalogued slot")
  end
  if room:getCardArea(equipId) ~= Card.DiscardPile or drawn ~= expectedDraw or
      afterHand ~= beforeHand + expectedDraw then
    fail(string.format("hidden Xiaoji must discard the equipment and draw %d card(s)", expectedDraw))
  end
  if state.actor:isFakeSkill("hs__xiaoji") or not state.actor:hasSkill("hs__xiaoji") then
    fail("hidden Xiaoji must convert from fake to active after reveal")
  end

  room:sendLog{
    type = "[TQS QA] Hidden 枭姬: AfterCardsMove mất trang bị=%arg; SkillEffect=%arg2; mở tướng=%arg3; bốc bài=%arg4; vị trí=%arg5",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = tostring(revealedCorrectSlot),
    arg4 = tostring(drawn),
    arg5 = xiaojiIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-xiaoji after_cards_move=equipment effect=true slot=%s revealed=%s drawn=%d expected=%d revision=%s",
    xiaojiIsDeputy and "deputy" or "main", tostring(revealedCorrectSlot), drawn, expectedDraw,
    manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenGuanxing(room, state)
  -- 观星 is an optional EventPhaseStart trigger. The QA pause is separate
  -- from the source trigger: it gives the browser a real opportunity to
  -- prelight the hidden skill before the native event is raised.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-guanxing actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("hs__guanxing") then
    fail("hidden-guanxing must attach the hidden Guanxing skill")
  end
  if state.actor:hasSkill("hs__guanxing") then
    fail("hidden-guanxing must not be active before the prelighted phase trigger")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_guanxing_gate",
    prompt = "TQS QA: prelight 观星, rồi xác nhận để bắt đầu pha chuẩn bị.",
  })
  if not gate then
    fail("hidden-guanxing readiness gate was cancelled")
  end
  if not isPrelighted(state.actor, "hs__guanxing") then
    fail("hidden-guanxing must be prelighted before the EventPhaseStart branch")
  end

  -- With two live players the source skill must ask the native arrange dialog
  -- for exactly two top cards. The skill itself calls getNCards/askToGuanxing;
  -- this director only records the expected native cards so completion can be
  -- checked after the real AskForArrangeCards reply returns.
  state.guanxingCards = table.simpleClone(room:getNCards(math.min(5, #room.alive_players)))
  state.currentDamageStep = 1
  room:setPlayerProperty(state.actor, "phase", Player.Start)
  room:broadcastProperty(state.actor, "phase")
  room.logic:trigger(fk.EventPhaseStart, state.actor, {
    who = state.actor,
    phase = Player.Start,
  })
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "hs__guanxing" and entry.player == state.actor.id
  end)
  local guanxingIsDeputy = state.scenario == "hidden-guanxing-deputy"
  local revealedCorrectSlot = guanxingIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__zhugeliang"
    or not guanxingIsDeputy and state.actor.general == "hs__zhugeliang" and state.actor.deputyGeneral == "anjiang"
  local arranged = #state.guanxingCards == 2
  for _, id in ipairs(state.guanxingCards) do
    if room:getCardArea(id) ~= Card.DrawPile then
      arranged = false
      break
    end
  end
  if not effect or effect.fake or not revealedCorrectSlot then
    fail("prelighted hidden Guanxing must run a real SkillEffect and reveal Zhuge Liang in its catalogued slot")
  end
  if not arranged then
    fail("hidden Guanxing must return both native top cards to the draw pile after AskForArrangeCards")
  end
  if state.actor:isFakeSkill("hs__guanxing") or not state.actor:hasSkill("hs__guanxing") then
    fail("hidden Guanxing must convert from fake to active after reveal")
  end

  room:sendLog{
    type = "[TQS QA] Hidden 观星: EventPhaseStart=%arg; AskForArrangeCards=%arg2; SkillEffect=%arg3; mở tướng=%arg4; đã xếp=%arg5; vị trí=%arg6",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = "true",
    arg4 = tostring(revealedCorrectSlot),
    arg5 = tostring(arranged),
    arg6 = guanxingIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-guanxing event_phase_start=guanxing arrange=true effect=true slot=%s revealed=%s cards=%d revision=%s",
    guanxingIsDeputy and "deputy" or "main", tostring(revealedCorrectSlot), #state.guanxingCards,
    manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenYingzi(room, state)
  -- 英姿 is compulsory on fk.DrawNCards. The QA pause is deliberately
  -- separate from that source event: it gives the browser a real chance to
  -- prelight the hidden skill while both general slots are still anjiang.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-yingzi actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("ex__yingzi") then
    fail("hidden-yingzi must attach the hidden ex__yingzi skill")
  end
  if state.actor:hasSkill("ex__yingzi") then
    fail("hidden-yingzi must not be active before the prelighted draw trigger")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_yingzi_gate",
    prompt = "TQS QA: prelight 英姿, rồi xác nhận để bắt đầu pha rút bài.",
  })
  if not gate then
    fail("hidden-yingzi readiness gate was cancelled")
  end
  if not isPrelighted(state.actor, "ex__yingzi") then
    fail("hidden-yingzi must be prelighted before the DrawNCards branch")
  end

  local beforeHand = #state.actor:getCardIds(Player.Hand)
  state.currentDamageStep = 1
  room:setPlayerProperty(state.actor, "phase", Player.Draw)
  room:broadcastProperty(state.actor, "phase")
  local phaseData = {
    who = state.actor,
    reason = "game_rule",
    phase = Player.Draw,
  }
  room.logic:trigger(fk.EventPhaseStart, state.actor, phaseData)
  room.logic:trigger(fk.EventPhaseProceeding, state.actor, phaseData)

  -- This is the same draw-phase sequence used by the native Phase event:
  -- base count 2 -> fk.DrawNCards modifiers -> actual draw -> AfterDrawNCards.
  local drawData = {
    who = state.actor,
    reason = "game_rule",
    phase = Player.Draw,
    n = 2,
  }
  room.logic:trigger(fk.DrawNCards, state.actor, drawData)
  if drawData.n > 0 then
    room:drawCards(state.actor, drawData.n, "phase_draw")
  end
  room.logic:trigger(fk.AfterDrawNCards, state.actor, drawData)
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "ex__yingzi" and entry.player == state.actor.id
  end)
  local drawEvent = table.find(state.drawEvents, function(entry)
    return entry.step == 1 and entry.player == state.actor.id and entry.stage == "after"
  end)
  local yingziIsDeputy = state.scenario == "hidden-yingzi-deputy"
  local revealedCorrectSlot = yingziIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__zhouyu"
    or not yingziIsDeputy and state.actor.general == "hs__zhouyu" and state.actor.deputyGeneral == "anjiang"
  local afterHand = #state.actor:getCardIds(Player.Hand)
  if not effect or effect.fake or not revealedCorrectSlot then
    fail("prelighted hidden Yingzi must run a real SkillEffect and reveal Zhou Yu in its catalogued slot")
  end
  if not drawEvent or drawEvent.n ~= 3 then
    fail(string.format("hidden Yingzi must raise DrawNCards from 2 to 3, observed %s", drawEvent and drawEvent.n or "none"))
  end
  if afterHand ~= beforeHand + 3 then
    fail(string.format("hidden Yingzi must draw three cards, hand changed from %d to %d", beforeHand, afterHand))
  end
  if state.actor:isFakeSkill("ex__yingzi") or not state.actor:hasSkill("ex__yingzi") then
    fail("hidden Yingzi must convert from fake to active after the native DrawNCards effect")
  end

  room:sendLog{
    type = "[TQS QA] Hidden 英姿: DrawNCards=%arg; AfterDrawNCards=%arg2; SkillEffect=%arg3; mở tướng=%arg4; bốc bài=%arg5; vị trí=%arg6",
    from = state.actor.id,
    arg = "true",
    arg2 = tostring(drawEvent ~= nil),
    arg3 = "true",
    arg4 = tostring(revealedCorrectSlot),
    arg5 = tostring(drawEvent and drawEvent.n or 0),
    arg6 = yingziIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-yingzi draw_n_cards=true after_draw_n=%d effect=true slot=%s revealed=%s drawn=%d revision=%s",
    drawEvent.n, yingziIsDeputy and "deputy" or "main", tostring(revealedCorrectSlot), drawEvent.n,
    manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenTianxiang(room, state)
  -- 天香 is a real DetermineDamageInflicted interaction: the hidden owner
  -- must remain fake until the player has selected a heart card and a target.
  -- SkillEffect then reveals Xiao Qiao before the source effect prevents the
  -- incoming damage and asks for the native lose-HP/damage branch.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-tianxiang actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("hs__tianxiang") then
    fail("hidden-tianxiang must attach the hidden Tianxiang skill")
  end
  if state.actor:hasSkill("hs__tianxiang") then
    fail("hidden-tianxiang must not be active before the damage trigger")
  end

  local cardId = state.slotCards["tianxiang-heart"]
  if not cardId or not table.contains(state.actor:getCardIds(Player.Hand), cardId) or
      Fk:getCardById(cardId):getSuitString() ~= "heart" then
    fail("hidden-tianxiang must put the reserved heart card in the actor hand")
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_tianxiang_gate",
    prompt = "TQS QA: prelight Thiên Hương, rồi xác nhận để nhận sát thương.",
  })
  if not gate then
    fail("hidden-tianxiang QA gate was cancelled")
  end
  if not isPrelighted(state.actor, "hs__tianxiang") then
    fail("hidden-tianxiang must be prelighted before DetermineDamageInflicted")
  end

  local actorHp = state.actor.hp
  local targetHp = state.target.hp
  state.currentDamageStep = 1
  room:damage({
    from = state.target,
    to = state.actor,
    damage = 1,
    skillName = "tqs_qa_hidden_tianxiang_damage",
  })
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "hs__tianxiang" and entry.player == state.actor.id
  end)
  local tianxiangIsDeputy = state.scenario == "hidden-tianxiang-deputy"
  local revealedCorrectSlot = tianxiangIsDeputy
    and state.actor.general == "anjiang" and state.actor.deputyGeneral == "hs__xiaoqiao"
    or not tianxiangIsDeputy and state.actor.general == "hs__xiaoqiao" and state.actor.deputyGeneral == "anjiang"
  local cardObtained = table.contains(state.target:getCardIds(Player.Hand), cardId) and
    not table.contains(state.actor:getCardIds(Player.Hand), cardId)
  local damagePrevented = state.actor.hp == actorHp
  local targetLostHp = state.target.hp == targetHp - 1

  if not effect or effect.fake or not revealedCorrectSlot then
    fail("prelighted hidden Tianxiang must run a real SkillEffect and reveal Xiao Qiao in its catalogued slot")
  end
  if not damagePrevented or not targetLostHp or not cardObtained then
    fail("hidden Tianxiang must prevent the incoming damage, make the target lose 1 HP and return the heart card")
  end
  if state.actor:isFakeSkill("hs__tianxiang") or not state.actor:hasSkill("hs__tianxiang") then
    fail("hidden Tianxiang must convert from fake to active after reveal")
  end

  room:sendLog{
    type = "[TQS QA] Hidden Thiên Hương: DetermineDamageInflicted=%arg; AskForUseActiveSkill=%arg2; AskForChoices=%arg3; SkillEffect=%arg4; sát thương bị chặn=%arg5; mục tiêu mất HP=%arg6; trả bài=%arg7; mở tướng=%arg8; vị trí=%arg9",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = "true",
    arg4 = "true",
    arg5 = tostring(damagePrevented),
    arg6 = tostring(targetLostHp),
    arg7 = tostring(cardObtained),
    arg8 = tostring(revealedCorrectSlot),
    arg9 = tianxiangIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-tianxiang determine_damage_inflicted=true choose_card_target=true choice=lose_hp effect=true prevented=%s target_lost_hp=%s card_returned=%s slot=%s revealed=%s revision=%s",
    tostring(damagePrevented), tostring(targetLostHp), tostring(cardObtained),
    tianxiangIsDeputy and "deputy" or "main", tostring(revealedCorrectSlot), manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local function triggerHiddenDuanchang(room, state)
  -- 断肠 is a compulsory fk.Death trigger.  Keep 蔡文姬 hidden and
  -- prelighted until the real death event; the native GameOverJudge may
  -- reveal a dead player before fk.Death, but it must not skip the trigger.
  state.target:revealGenerals()
  if state.actor.general ~= "anjiang" or state.actor.deputyGeneral ~= "anjiang" then
    fail("hidden-duanchang actor must start with both generals hidden")
  end
  if not state.actor:isFakeSkill("hs__duanchang") then
    fail("hidden-duanchang must attach the hidden Duanchang skill")
  end
  if state.actor:hasSkill("hs__duanchang") then
    fail("hidden-duanchang must not be active before the death trigger")
  end
  if not state.target:hasSkill("hs__jianxiong") or not state.target:hasSkill("fankui") then
    fail("hidden-duanchang killer must expose Cao Cao Jianxiong and Sima Yi Fankui")
  end

  -- With four seats, GameOverJudge must not decide the match before fk.Death.
  -- Pin an additional living bot to Shu so the Wei killer cannot be the only
  -- surviving kingdom by accident.
  for _, player in ipairs(room.alive_players) do
    if player ~= state.actor and player ~= state.target then
      room:setPlayerProperty(player, "kingdom", "shu")
      player.role = "shu"
      room:setPlayerMark(player, "__heg_kingdom", "shu")
      room:broadcastProperty(player, "kingdom")
      room:broadcastProperty(player, "role")
    end
  end

  local gate = room:askToSkillInvoke(state.actor, {
    skill_name = "tqs_qa_hidden_duanchang_gate",
    prompt = "TQS QA: prelight Đoạn Trường, rồi xác nhận để xử lý khi chết.",
  })
  if not gate then
    fail("hidden-duanchang QA gate was cancelled")
  end
  if not isPrelighted(state.actor, "hs__duanchang") then
    fail("hidden-duanchang must be prelighted before fk.Death")
  end

  state.currentDamageStep = 1
  room:killPlayer({
    who = state.actor,
    killer = state.target,
  })
  state.currentDamageStep = nil

  local effect = table.find(state.skillEffects, function(entry)
    return entry.step == 1 and entry.skill == "hs__duanchang" and entry.player == state.actor.id
  end)
  local duanchangIsDeputy = state.scenario == "hidden-duanchang-deputy"
  local expectedMain = duanchangIsDeputy and "hs__yuanshao" or "hs__caiwenji"
  local expectedDeputy = duanchangIsDeputy and "hs__caiwenji" or "hs__yuanshao"
  local actorRevealed = state.actor.dead and state.actor.general == expectedMain and
    state.actor.deputyGeneral == expectedDeputy
  local mark = state.target:getMark("@hs__duanchang")
  local killerMainChosen = type(mark) == "table" and table.contains(mark, "hs__caocao")
  local killerMainSkillsLost = not state.target:hasSkill("hs__jianxiong")
  local killerDeputySkillsRetained = state.target:hasSkill("fankui")

  if not effect or effect.fake then
    fail("prelighted hidden Duanchang must run a real SkillEffect on fk.Death")
  end
  if not actorRevealed then
    fail("hidden Duanchang death must reveal the catalogued Cai Wenji slot pair")
  end
  if not killerMainChosen or not killerMainSkillsLost or not killerDeputySkillsRetained then
    fail("hidden Duanchang must remove only the killer's chosen Cao Cao skills")
  end

  room:sendLog{
    type = "[TQS QA] Hidden Đoạn Trường: Death=%arg; SkillEffect=%arg2; người chết mở tướng=%arg3; killer chọn chủ tướng=%arg4; killer mất kỹ năng chủ=%arg5; kỹ năng phó còn lại=%arg6; vị trí=%arg7",
    from = state.actor.id,
    arg = "true",
    arg2 = "true",
    arg3 = tostring(actorRevealed),
    arg4 = tostring(killerMainChosen),
    arg5 = tostring(killerMainSkillsLost),
    arg6 = tostring(killerDeputySkillsRetained),
    arg7 = duanchangIsDeputy and "phó tướng" or "chủ tướng",
  }
  fk.qInfo(string.format("[tqs_qa] hidden-duanchang death=true skill_effect=true choice=main_general killer_main_skills_lost=%s killer_deputy_skills_retained=%s actor_revealed=%s slot=%s revision=%s",
    tostring(killerMainSkillsLost), tostring(killerDeputySkillsRetained), tostring(actorRevealed),
    duanchangIsDeputy and "deputy" or "main", manifest.sourceRevision))
  state.gameOverRequested = true
  room:gameOver("")
end

local director = fk.CreateSkill {
  name = "tqs_qa_director&",
}

director:addEffect(fk.SkillEffect, {
  global = true,
  priority = -1000,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and (state.scenario == "fazheng-enyuan" or state.scenario == "hidden-enyuan" or
      state.scenario == "hidden-enyuan-deputy" or state.scenario == "hidden-yiji" or
      state.scenario == "hidden-fuyin" or state.scenario == "hidden-fuyin-deputy" or
      state.scenario == "hidden-yiji-deputy" or state.scenario == "hidden-jianxiong" or
      state.scenario == "hidden-rehide-yiji" or state.scenario == "hidden-rehide-yiji-deputy" or
      state.scenario == "hidden-jianxiong-deputy" or state.scenario == "hidden-fankui" or
      state.scenario == "hidden-fankui-deputy" or state.scenario == "hidden-reveal" or
      state.scenario == "hidden-reveal-deputy" or state.scenario == "hidden-active" or
      state.scenario == "hidden-active-main" or state.scenario == "hidden-fanjian" or
      state.scenario == "hidden-fanjian-deputy" or state.scenario == "hidden-view-as" or
      state.scenario == "hidden-view-as-main" or state.scenario == "hidden-dual" or
      state.scenario == "hidden-luoshen" or state.scenario == "hidden-luoshen-deputy" or
      state.scenario == "hidden-tiandu" or state.scenario == "hidden-tiandu-deputy" or
      state.scenario == "hidden-jizhi" or state.scenario == "hidden-jizhi-deputy" or
      state.scenario == "hidden-mingshi" or state.scenario == "hidden-mingshi-deputy" or
      state.scenario == "hidden-gongqing" or state.scenario == "hidden-gongqing-deputy" or
      state.scenario == "hidden-qianxun" or state.scenario == "hidden-qianxun-deputy" or
      state.scenario == "hidden-qianxun-indulgence" or
      state.scenario == "hidden-qianxun-indulgence-deputy" or
      state.scenario == "hidden-kongcheng" or
      state.scenario == "hidden-kongcheng-deputy" or
      state.scenario == "hidden-weimu" or
      state.scenario == "hidden-weimu-deputy" or
      state.scenario == "hidden-weimu-indulgence" or
      state.scenario == "hidden-weimu-indulgence-deputy" or
      state.scenario == "hidden-xiaoji" or
      state.scenario == "hidden-xiaoji-deputy" or
      state.scenario == "hidden-guanxing" or
      state.scenario == "hidden-guanxing-deputy" or
      state.scenario == "hidden-yingzi" or
      state.scenario == "hidden-yingzi-deputy" or
      state.scenario == "hidden-tianxiang" or
      state.scenario == "hidden-tianxiang-deputy" or
      state.scenario == "hidden-duanchang" or
      state.scenario == "hidden-duanchang-deputy" or
      state.scenario == "hidden-kuanggu" or
      state.scenario == "hidden-kuanggu-deputy" or
      state.scenario == "hidden-liegong" or
      state.scenario == "hidden-liegong-deputy" or
      state.scenario == "hidden-jueqing" or
      state.scenario == "hidden-jueqing-deputy" or
      state.scenario == "hidden-ejue" or
      state.scenario == "hidden-ejue-deputy") and
      data and data.skill
  end,
  on_trigger = function(self, event, target, player, data)
    recordSkillEffect(stateFor(player.room), player, data)
  end,
})

director:addEffect(fk.PreDamage, {
  global = true,
  -- DamageEvent:breakCheck() stops lower-priority PreDamage observers after
  -- a prevention skill such as Jueqing calls data:preventDamage(). Observe
  -- before the real skill so the QA marker proves that the native
  -- PreDamage branch was entered, without changing the source-law ordering
  -- of any production skill.
  priority = 1000,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and (state.scenario == "hidden-jueqing" or state.scenario == "hidden-jueqing-deputy") and
      state.currentDamageStep and data and data.from == state.actor
  end,
  on_trigger = function(self, event, target, player, data)
    stateFor(player.room).jueqingPreDamage = true
  end,
})

director:addEffect(fk.DamageCaused, {
  global = true,
  priority = -1000,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and (state.scenario == "hidden-ejue" or state.scenario == "hidden-ejue-deputy") and
      state.currentDamageStep and data and data.from == state.actor and data.to == state.target
  end,
  on_trigger = function(self, event, target, player, data)
    stateFor(player.room).hiddenEjueDamageCaused = true
  end,
})

for _, eventName in ipairs({fk.BeforeHpChanged, fk.Damage}) do
  director:addEffect(eventName, {
    global = true, priority = -1000,
    can_trigger = function(self, event, target, player, data)
      local state = stateFor(player.room)
      if not state or (state.scenario ~= "hidden-kuanggu" and state.scenario ~= "hidden-kuanggu-deputy" and
          state.scenario ~= "hidden-liegong" and state.scenario ~= "hidden-liegong-deputy") or
          not state.currentDamageStep or player ~= player.room.players[1] or not data then
        return false
      end
      if eventName == fk.BeforeHpChanged then
        return data.damageEvent and data.damageEvent.from == state.actor
      end
      return data.from == state.actor
    end,
    on_trigger = function(self, event, target, player, data)
      local state = stateFor(player.room)
      if eventName == fk.BeforeHpChanged then
        if state.scenario == "hidden-kuanggu" or state.scenario == "hidden-kuanggu-deputy" then
          state.kuangguBeforeHpChanged = true
        end
      else
        if state.scenario == "hidden-kuanggu" or state.scenario == "hidden-kuanggu-deputy" then
          state.kuangguDamage = true
        elseif state.scenario == "hidden-liegong" or state.scenario == "hidden-liegong-deputy" then
          state.liegongDamage = true
        end
      end
    end,
  })
end

director:addEffect(fk.TargetSpecified, {
  global = true, priority = -1000,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and (state.scenario == "hidden-liegong" or state.scenario == "hidden-liegong-deputy") and
      state.currentDamageStep and player == player.room.players[1] and data and data.from == state.actor and
      data.card and data.card.trueName == "slash"
  end,
  on_trigger = function(self, event, target, player, data)
    stateFor(player.room).liegongTargetSpecified = true
  end,
})

-- Observe engine events once per room; no card ids are published in QA logs.
for _, eventName in ipairs({fk.CardUsing, fk.CardResponding}) do
  director:addEffect(eventName, {
    global = true, priority = -1000,
    can_trigger = function(self, event, target, player, data)
      local state = stateFor(player.room)
      return state and state.currentDamageStep and player == player.room.players[1]
    end,
    on_trigger = function(self, event, target, player, data)
      local state = stateFor(player.room)
      table.insert(state.cardEvents, { step = state.currentDamageStep, player = data.from.id,
        name = data.card.trueName, subcards = table.simpleClone(data.card.subcards),
        longdan = table.contains(data.card.skillNames, "hs__longdan") })
    end,
  })
end

director:addEffect(fk.Damaged, {
  global = true, priority = -1000,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and state.currentDamageStep and target == player
  end,
  on_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    table.insert(state.damageEvents, { step = state.currentDamageStep,
      from = data.from and data.from.id, to = data.to.id, amount = data.damage })
  end,
})

director:addEffect(fk.TargetConfirmed, {
  global = true, priority = -1000,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and (state.scenario == "hidden-enyuan" or state.scenario == "hidden-enyuan-deputy") and
      state.currentDamageStep and target == state.actor and data and data.card and
      data.card.trueName == "peach" and data.from == state.target
  end,
  on_trigger = function(self, event, target, player, data)
    stateFor(player.room).hiddenEnyuanTargetConfirmed = true
  end,
})

director:addEffect(fk.TargetConfirmed, {
  global = true, priority = -1000,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and (state.scenario == "hidden-fuyin" or state.scenario == "hidden-fuyin-deputy") and
      state.currentDamageStep and target == state.actor and data and data.card and
      data.card.trueName == "slash" and data.from == state.target
  end,
  on_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    state.hiddenFuyinTargetConfirmed = true
    state.hiddenFuyinNullified = data.nullified == true or
      (data.use and data.use.nullifiedTargets and table.contains(data.use.nullifiedTargets, state.actor))
  end,
})

director:addEffect(fk.AfterCardsMove, {
  global = true, priority = -999,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and (state.scenario == "hidden-enyuan" or state.scenario == "hidden-enyuan-deputy") and
      state.currentDamageStep and type(data) == "table"
  end,
  on_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    for _, move in ipairs(data) do
      if move.skillName == "ld__enyuan" and move.to == state.target and
          move.toArea == Card.PlayerHand then
        -- A single native draw can be represented by more than one
        -- moveInfo entry while the move is normalized.  Count card ids,
        -- not raw entries, so the QA assertion measures the actual card
        -- movement rather than an intermediate duplicate.
        for _, info in ipairs(move.moveInfo or {}) do
          if info.cardId then
            table.insertIfNeed(state.hiddenEnyuanDrawCards, info.cardId)
          end
        end
        state.hiddenEnyuanDrawCount = #state.hiddenEnyuanDrawCards
      end
    end
  end,
})

director:addEffect(fk.AfterCardsMove, {
  global = true, priority = -1000,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and state.currentDamageStep and player == player.room.players[1]
  end,
  on_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    for _, move in ipairs(data) do
      if move.toArea == Card.PlayerHand then
        local firstInfo = move.moveInfo and move.moveInfo[1]
        table.insert(state.skillMoves, { step = state.currentDamageStep, skill = move.skillName,
          from = move.from and move.from.id, to = move.to and move.to.id, count = #move.moveInfo,
          fromArea = firstInfo and firstInfo.fromArea })
      end
    end
  end,
})

for _, eventName in ipairs({fk.DrawNCards, fk.AfterDrawNCards}) do
  director:addEffect(eventName, {
    global = true, priority = -1000,
    can_trigger = function(self, event, target, player, data)
      local state = stateFor(player.room)
      return state and state.currentDamageStep and target == state.actor and player == player.room.players[1]
    end,
    on_trigger = function(self, event, target, player, data)
      local state = stateFor(player.room)
      table.insert(state.drawEvents, {
        step = state.currentDamageStep,
        stage = eventName == fk.DrawNCards and "before" or "after",
        player = target.id,
        n = data.n,
      })
    end,
  })
end

director:addEffect(fk.GamePrepared, {
  global = true,
  priority = 1000,
  can_trigger = function(self, event, target, player, data)
    return player == player.room.players[1] and not stateFor(player.room)
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local scenario, seed = parseRequest(room)
    if not scenario then return false end
    setupState(room, scenario, seed)
  end,
})

director:addEffect(fk.DrawInitialCards, {
  global = true,
  priority = 1000,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and target == player and state.fixedHands[player.id] ~= nil
  end,
  on_trigger = function(self, event, target, player, data)
    local ids = stateFor(player.room).fixedHands[player.id]
    data.num = #ids
    data.fix_ids = table.simpleClone(ids)
  end,
})

director:addEffect(fk.GameStart, {
  global = true,
  priority = 1000,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and player == player.room.players[1] and not state.gameStartDone
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local state = stateFor(room)
    state.gameStartDone = true
    shuffleTail(room, state.seed)
    local scenario = scenarioById[state.scenario]
    if scenario.trigger == "rescue" or scenario.trigger == "rescue-battle" then
      triggerRescue(room, state)
    elseif scenario.trigger == "founding" then
      triggerFounding(room, state)
    elseif scenario.trigger == "damage-exchange" then
      triggerDamageExchange(room, state)
    elseif scenario.trigger == "hidden-yiji" then
      triggerHiddenYiji(room, state)
    elseif scenario.trigger == "hidden-rehide-yiji" then
      state.rehideAfterYiji = true
      triggerHiddenYiji(room, state)
    elseif scenario.trigger == "hidden-jianxiong" then
      triggerHiddenJianxiong(room, state)
    elseif scenario.trigger == "hidden-fankui" then
      triggerHiddenFankui(room, state)
    elseif scenario.trigger == "hidden-enyuan" then
      triggerHiddenEnyuan(room, state)
    elseif scenario.trigger == "hidden-fuyin" then
      -- 父荫's official predicate searches the current turn history. Defer
      -- the real Slash until the actor's Start phase so the QA director
      -- exercises the same TargetConfirmed context as a live turn.
      state.hiddenFuyinPending = true
    elseif scenario.trigger == "hidden-kuanggu" then
      triggerHiddenKuanggu(room, state)
    elseif scenario.trigger == "hidden-liegong" then
      triggerHiddenLiegong(room, state)
    elseif scenario.trigger == "hidden-reveal" then
      triggerHiddenReveal(room, state)
    elseif scenario.trigger == "hidden-active" then
      triggerHiddenActive(room, state)
    elseif scenario.trigger == "hidden-fanjian" then
      triggerHiddenFanjian(room, state)
    elseif scenario.trigger == "hidden-view-as" then
      triggerHiddenViewAs(room, state)
    elseif scenario.trigger == "hidden-dual" then
      triggerHiddenDual(room, state)
    elseif scenario.trigger == "hidden-luoshen" then
      triggerHiddenLuoshen(room, state)
    elseif scenario.trigger == "hidden-tiandu" then
      triggerHiddenTiandu(room, state)
    elseif scenario.trigger == "hidden-jizhi" then
      triggerHiddenJizhi(room, state)
    elseif scenario.trigger == "hidden-mingshi" then
      triggerHiddenMingshi(room, state)
    elseif scenario.trigger == "hidden-gongqing" then
      triggerHiddenGongqing(room, state)
    elseif scenario.trigger == "hidden-qianxun" then
      triggerHiddenQianxun(room, state)
    elseif scenario.trigger == "hidden-kongcheng" then
      triggerHiddenKongcheng(room, state)
    elseif scenario.trigger == "hidden-weimu" then
      triggerHiddenWeimu(room, state)
    elseif scenario.trigger == "hidden-xiaoji" then
      triggerHiddenXiaoji(room, state)
    elseif scenario.trigger == "hidden-guanxing" then
      triggerHiddenGuanxing(room, state)
    elseif scenario.trigger == "hidden-yingzi" then
      triggerHiddenYingzi(room, state)
    elseif scenario.trigger == "hidden-tianxiang" then
      triggerHiddenTianxiang(room, state)
    elseif scenario.trigger == "hidden-duanchang" then
      triggerHiddenDuanchang(room, state)
    elseif scenario.trigger == "hidden-jueqing" then
      triggerHiddenJueqing(room, state)
    elseif scenario.trigger == "hidden-ejue" then
      triggerHiddenEjue(room, state)
    end
  end,
})

director:addEffect(fk.EventPhaseStart, {
  global = true,
  priority = 1000,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and state.hiddenFuyinPending and target == state.actor and
      player == state.actor and data.phase == Player.Start
  end,
  on_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    state.hiddenFuyinPending = false
    -- Hegemony reveals the first player's pair before EventPhaseStart. Re-hide
    -- the catalogued slots here so the actual TargetConfirmed test begins in
    -- the same hidden-general state as a player who kept both generals down.
    if state.actor.general ~= "anjiang" then state.actor:hideGeneral(false) end
    if state.actor.deputyGeneral ~= "anjiang" then state.actor:hideGeneral(true) end
    triggerHiddenFuyin(player.room, state)
  end,
})

director:addEffect(fk.RoundStart, {
  global = true,
  priority = 1000,
  can_trigger = function(self, event, target, player, data)
    local state = stateFor(player.room)
    return state and player == player.room.players[1] and now() - state.startedAt > maxDurationSeconds
  end,
  on_trigger = function(self, event, target, player, data)
    fk.qWarning(string.format("[tqs_qa] timeout scenario=%s seed=%u revision=%s",
      stateFor(player.room).scenario, stateFor(player.room).seed, manifest.sourceRevision))
    player.room:gameOver("")
  end,
})

director:addEffect(fk.GameFinished, {
  global = true,
  priority = 1000,
  can_trigger = function(self, event, target, player, data)
    return stateFor(player.room) ~= nil and player == player.room.players[1]
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    activeRooms[tostring(room)] = nil
    room:removeTag("tqs_qa")
  end,
})

-- fk.CreateSkill returns a SkillSkeleton. Register it through the package's
-- skeleton loader so Package:install creates a real Skill before Engine:addSkill
-- receives it. Inserting the skeleton directly into related_skills crashes the
-- native Lua worker at Engine:addSkill's type assertion.
extension:loadSkillSkels({ director })

return extension
