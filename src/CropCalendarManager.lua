---@author Jos Modding
---@version 1.0.0.0

---@class CropCalendarManager
CropCalendarManager = {}
local modDir = g_currentModDirectory


---@return void
function CropCalendarManager:loadSettings()
    g_cropCalendarManager.map = g_currentMission.missionInfo.map

    local key = "cropCalendarManager"
    local filename = Utils.getFilename("/cropCalendarManager.xml", g_currentMission.missionInfo.savegameDirectory)

    if fileExists(filename) then
        local xmlFile = XMLFile.load('cropCalendarManagerSettings', filename)

        if xmlFile ~= nil then
            local id = Utils.getNoNil(xmlFile:getString(key .. "#id"), g_currentMission.missionInfo.map.id)
            g_cropCalendarManager.map = g_mapManager:getMapById(id)
            xmlFile:delete()
        end
    end

    Logging.info("Loading growth data from " .. g_cropCalendarManager.map.title)
    CropCalendarManager:loadGrowthDataFromMap(g_cropCalendarManager.map)
end

---@return void
function CropCalendarManager:saveSettings()
    local key = "cropCalendarManager"
    local filename = Utils.getFilename("/cropCalendarManager.xml", g_currentMission.missionInfo.savegameDirectory)

    if fileExists(filename) then
        local xmlFile = XMLFile.create('cropCalendarManagerSettings', filename, key)

        if xmlFile ~= nil then
            xmlFile:setString(key .. "#id", g_cropCalendarManager.map.id)
            xmlFile:save()
        end
    end
end

---@param map table
---@return void
function CropCalendarManager:loadGrowthDataFromMap(map)
    local mapXMLFilename = Utils.getFilename(map.mapXMLFilename, map.baseDirectory)

    if fileExists(mapXMLFilename) then
        local mapXML = XMLFile.load("map", mapXMLFilename)

        if mapXML ~= nil then
            local growthXMLFilename = Utils.getFilename(mapXML:getString("map.growth#filename"), map.baseDirectory)
            local growthXML = XMLFile.load("growth", growthXMLFilename)

            if growthXML ~= nil then
                g_currentMission.growthSystem:loadGrowthData(growthXML, "growth")
            end
        end
    end
end

---@return table
function CropCalendarManager:getOptions()
    local options = {}

    for _, map in ipairs(g_mapManager.maps) do
        table.insert(options, map.title)
    end

    return options
end

---@return number
function CropCalendarManager:getSelectedState()
    local state = 0

    for i, map in ipairs(g_mapManager.maps) do
        if map.id == g_cropCalendarManager.map.id then
            state = i
        end
    end

    return state
end

---@return void
function CropCalendarManager:onFrameOpen()
    if self.cropCalendar ~= nil then
        return
    end

    local options = CropCalendarManager:getOptions()
    local currentState = CropCalendarManager:getSelectedState()

    self.cropCalendar = self.economicDifficulty:clone()
    self.cropCalendar.target = false
    self.cropCalendar.id = "cropCalendar"
    self.cropCalendar.onClickCallback = CropCalendarManager.onStateChanged
    self.cropCalendar:setTexts(options)
    self.cropCalendar:setState(currentState)

    local settingTitle = self.cropCalendar.elements[4]
    local toolTip = self.cropCalendar.elements[6]

    settingTitle:setText(g_i18n:getText("settings_cropCalendar_title"))
    toolTip:setText("settings_cropCalendar_toolTip")

    -- Section title
    local title = TextElement.new()
    title:applyProfile("settingsMenuSubtitle", true)
    title:setText(g_i18n:getText("settings_cropCalendar_sectionTitle"))

    self.boxLayout:addElement(title)
    self.boxLayout:addElement(self.cropCalendar)
    self.boxLayout:invalidateLayout()
end

---@param state number
---@return void
function CropCalendarManager:onStateChanged(state)
    local map = g_mapManager:getMapDataByIndex(state)

    if map ~= nil then
        g_cropCalendarManager.map = map
        CropCalendarManager:loadGrowthDataFromMap(map)
    end
end

---
function CropCalendarManager:loadMapDataHelpLineManager(superFunc, ...)
    local s = superFunc(self, ...)

    if s then
        self:loadFromXML(Utils.getFilename("xml/helpLine.xml", modDir))
    end

    return s
end

---@return void
local function init()
    if g_cropCalendarManager == nil then
        g_cropCalendarManager = {
            maps = {},
            map = {},
        }
    end

    Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, CropCalendarManager.loadSettings)
    FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, CropCalendarManager.saveSettings)
    InGameMenuGameSettingsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuGameSettingsFrame.onFrameOpen, CropCalendarManager.onFrameOpen)
    HelpLineManager.loadMapData = Utils.overwrittenFunction(HelpLineManager.loadMapData, CropCalendarManager.loadMapDataHelpLineManager)
end

init()
