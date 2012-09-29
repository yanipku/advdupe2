--[[
	Title: Adv. Dupe 2 File Browser
	
	Desc: Displays and interfaces with duplication files.
	
	Author: TB
	
	Version: 1.0
]]

local panel

local switch=true
local count = 0
local function Slide(expand)
	if(expand)then
		if(panel.Expanded)then 
			panel:SetTall(panel:GetTall()-40) panel.Expanded=false
		else
			panel:SetTall(panel:GetTall()+5)
		end
	else
		if(!panel.Expanded)then 
			panel:SetTall(panel:GetTall()+40) panel.Expanded=true
		else
			panel:SetTall(panel:GetTall()-5)
		end
	end
	count = count+1
	if(count<9)then
		timer.Simple(0.01, function() Slide(expand) end)
	else
		if(expand)then
			panel.Expanded=true
		else
			panel.Expanded=false
		end
		panel.Expanding = false
		count = 0
	end
end

local BROWSERPNL = {}
AccessorFunc( BROWSERPNL, "m_bBackground", 			"PaintBackground",	FORCE_BOOL )
AccessorFunc( BROWSERPNL, "m_bgColor", 		"BackgroundColor" )
Derma_Hook( BROWSERPNL, "Paint", "Paint", "Panel" )
Derma_Hook( BROWSERPNL, "PerformLayout", "Layout", "Panel" )

local setbrowserpnlsize

local function SetBrowserPnlSize(self, x, y)
	setbrowserpnlsize(self, x, y)
	self.pnlCanvas:SetWide(x)
	self.pnlCanvas.VBar:SetUp(y, self.pnlCanvas:GetTall())
end

function BrowserPnlInit(self)
	setbrowserpnlsize = self.SetSize
	self.SetSize = SetBrowserPnlSize
	self.pnlCanvas = vgui.Create("advdupe2_browser_tree", self)

	self:SetPaintBackground(true)
	self:SetPaintBackgroundEnabled(false)
	self:SetPaintBorderEnabled(false)
	self:SetBackgroundColor(Color(255,255,255))
end

function BROWSERPNL:Init()
	BrowserPnlInit(self)
end

function BrowserPnlOnVScroll(self, iOffset)
	self.pnlCanvas:SetPos(0, iOffset)
end

function BROWSERPNL:OnVScroll( iOffset )
	BrowserPnlOnVScroll(self, iOffset)
end

derma.DefineControl( "advdupe2_browser_panel", "AD2 File Browser", BROWSERPNL, "Panel" )


local BROWSER = {}
AccessorFunc( BROWSER, "m_pSelectedItem",			"SelectedItem" )
Derma_Hook( BROWSER, "Paint", "Paint", "Panel" )

local origSetTall
local function SetTall(self, val)
	origSetTall(self, val)
	self.VBar:SetUp(self:GetParent():GetTall(), self:GetTall())
end

function INIT(self)
	self:SetTall(0)
	origSetTall = self.SetTall
	self.SetTall = SetTall
	
	self.VBar = vgui.Create( "DVScrollBar", self:GetParent() )
	self.VBar:Dock(RIGHT)
	self.Nodes = 0
	self.ChildrenExpanded = {}
	self.ChildList = self
	self.m_bExpanded = true
	self.Folders = {}
	self.Files = {}
	self.LastClick = CurTime()
	
end

function BROWSER:Init()
	INIT(self)
end

local function GetNodePath(node)
	local path = node.Label:GetText()
	local area = 0
	local name = ""
	node = node.ParentNode
	if(!node.ParentNode)then
		if(name == "-Public-")then
			area = 1
		elseif(name == "-Advanced Duplicator 1-")then
			area = 2
		end
		return "", area
	end
	
	while(true)do
		
		name = node.Label:GetText()
		if(name == "-Advanced Duplicator 2-")then
			break
		elseif(name == "-Public-")then
			area = 1
			break
		elseif(name == "-Advanced Duplicator 1-")then
			area = 2
			break
		end
		path = name.."/"..path
		node = node.ParentNode
	end
	
	return path, area
end

function BrowserDoNodeLeftClick(self, node)
	if(self.m_pSelectedItem==node && CurTime()-self.LastClick<=0.25)then		//Check for double click
		if(node.Derma.ClassName=="advdupe2_browser_folder")then
			if(node.Expander)then
				node:SetExpanded()												//It's a folder, expand/collapse it
			end
		else
			local path, area = GetNodePath(node)
			print(path)
			RunConsoleCommand("AdvDupe2_OpenFile", path, area)					//It's a file, open it
		end
	else
		self:SetSelected(node)													//A node was clicked, select it
	end
	self.LastClick = CurTime()
end

function BROWSER:DoNodeLeftClick(node)
	BrowserDoNodeLeftClick(self, node)
end

local function AddNewFolder(node)
	print("WORKING?")
	local Controller = node.Control:GetParent():GetParent():GetParent()
	local name = Controller.FileName:GetValue() 
	if(name=="" || name=="Folder_Name...")then 
		AdvDupe2.Notify("Name is blank!", NOTIFY_ERROR) 
		Controller.FileName:SelectAllOnFocus(true)
		Controller.FileName:OnGetFocus()
		Controller.FileName:RequestFocus()
		return 
	end 
	name = name:gsub("%W","")
	local path, area = GetNodePath(node)
	if(area==0)then
		path = AdvDupe2.DataFolder.."/"..path.."/"..name
	elseif(area==1)then
		path = AdvDupe2.DataFolder.."/=Public=/"..path.."/"..name
	else
		path = "adv_duplicator/"..path.."/"..name
	end

	if(file.IsDir(path, "DATA"))then 
		AdvDupe2.Notify("Folder name already exists.", NOTIFY_ERROR)
		Controller.FileName:SelectAllOnFocus(true)
		Controller.FileName:OnGetFocus()
		Controller.FileName:RequestFocus()
		return 
	end
	file.CreateDir(path)
	
	local Folder = node:AddFolder(name)
	node.Control:Sort(node)
	
	if(!node.m_bExpanded)then
		node:SetExpanded()
	end
	
	node.Control:SetSelected(Folder)
	if(Controller.Expanded)then
		Slide(false)
	end
end


local function CollapseChildren(node)
	node.m_bExpanded = false
	node.Expander:SetExpanded(false)
	node.ChildList:SetTall(0)
	for i=1, #node.ChildrenExpanded do
		CollapseChildren(node.ChildrenExpanded[i])
	end
	node.ChildrenExpanded = {}
end

local function CollapseParentsComplete(node)
	if(!node.ParentNode.ParentNode)then CollapseChildren(node) return end
	CollapseParentsComplete(node.ParentNode)
end

local function Incomplete()
	AdvDupe2.Notify("This feature is not yet complete!",NOTIFY_GENERIC,10)
end

function BrowserDoNodeRightClick(self, node)
	self:SetSelected(node)
	
	local parent = self:GetParent():GetParent():GetParent()
	parent.FileName:KillFocus()
	parent.Desc:KillFocus()
	local Menu = DermaMenu()

	if(game.SinglePlayer())then
		if(node.Derma.ClassName == "advdupe2_browser_file")then
			Menu:AddOption("Open", 	function() 
										local path, area = GetNodePath(node)
										RunConsoleCommand("AdvDupe2_OpenFile", path, area) 
									end)
			Menu:AddOption("Rename", 	function()
											Incomplete()
											/*RenameFileCl(node, parent.FileName:GetValue())
											parent.FileName:SetValue("File_Name...")
											parent.Desc:SetValue("Description...")*/
										end)
			Menu:AddOption("Move File", function() Incomplete() end)//parent:FolderSelect( 3, node.Name, GetNodePath(node), node) end)
			Menu:AddOption("Delete", function() Incomplete() end)//Delete(self, false, false) end)
		else
			Menu:AddOption("Save", 	function()
										if(parent.Expanding)then return end
										parent.Submit:SetMaterial("icon16/page_save.png")
										parent.Submit:SetTooltip("Save duplication")
										if(parent.FileName:GetValue()=="Folder_Name...")then
											parent.FileName:SetValue("File_Name...")
										end
										parent.Desc:SetVisible(true)
										parent.FileName:SelectAllOnFocus(true) 
										parent.FileName:OnMousePressed()
										parent.FileName:RequestFocus()
										parent.Expanding=true
										Slide(true)
										parent.Submit.DoClick = function()
																	local name = parent.FileName:GetValue()
																	if(name=="" || name=="File_Name...")then
																		AdvDupe2.Notify("Name field is blank.", NOTIFY_ERROR)
																		parent.FileName:SelectAllOnFocus(true)
																		parent.FileName:OnGetFocus()
																		parent.FileName:RequestFocus()
																		return 
																	end 
																	local path, area = GetNodePath(node)
																	local desc = parent.Desc:GetValue()
																	if(desc=="Description...")then desc="" end
																	parent.ActionNode = node
																	RunConsoleCommand("AdvDupe2_SaveFile", name, path, area, desc)
																end
									end)
			Menu:AddOption("New Folder", 	function()
												if(parent.Expanding)then return end
												parent.Submit:SetMaterial("icon16/folder_add.png")
												parent.Submit:SetTooltip("Add new folder")
												if(parent.FileName:GetValue()=="File_Name...")then
													parent.FileName:SetValue("Folder_Name...")
												end
												parent.Desc:SetVisible(false)
												parent.Submit.DoClick = function() AddNewFolder(node) end
												parent.FileName:SelectAllOnFocus(true) 
												parent.FileName:OnMousePressed()
												parent.FileName:RequestFocus()
												parent.Expanding=true
												Slide(true)
												
											end)
			Menu:AddOption("Search", Incomplete)
			if(node.Label:GetText()[1]!="-")then Menu:AddOption("Delete", function() Delete(self, true, false) end) end
		end
	
	elseif(parent.TabCtrl:GetActiveTab().Server)then

		if(node.Derma.ClassName == "advdupe2_browser_file")then
			Menu:AddOption("Open", 	function() 
										local path, area = GetNodePath(node)
										RunConsoleCommand("AdvDupe2_OpenFile", path, area) 
									end) 
			Menu:AddOption("Download", 	function() 
											Incomplete()
											//parent:FolderSelect(2, node.Name, nil, node) 
										end) 
			Menu:AddOption("Rename", 	function()
											Incomplete()
											/*local name = parent.FileName:GetValue() 
											if(name=="" || name=="File_Name...")then AdvDupe2.Notify("Name field is blank!", NOTIFY_ERROR) return end 
											local path, area = ParsePath(GetNodePath(node))
											parent.NodeToRename = node
											RunConsoleCommand("AdvDupe2_RenameFile", area, name, path )
											parent.FileName:SetValue("File_Name...")
											parent.Desc:SetValue("Description...")*/
										end)
			Menu:AddOption("Move File", function()
											Incomplete()
											//parent:FolderSelect(4, nil, nil, node) 
										end)
			Menu:AddOption("Delete", function() Incomplete() end)//Delete(self, false, true) end )
		else
			Menu:AddOption("Save", 	function()
										if(parent.Expanding)then return end
										parent.Submit:SetMaterial("icon16/page_save.png")
										parent.Submit:SetTooltip("Save duplication")
										if(parent.FileName:GetValue()=="Folder_Name...")then
											parent.FileName:SetValue("File_Name...")
										end
										parent.Desc:SetVisible(true)
										parent.Submit.DoClick = function() 
																	local name = parent.FileName:GetValue()
																	if(name=="" || name=="File_Name...")then
																		AdvDupe2.Notify("Name field is blank.", NOTIFY_ERROR)
																		parent.FileName:SelectAllOnFocus(true)
																		parent.FileName:OnGetFocus()
																		parent.FileName:RequestFocus()
																		return 
																	end 
																	local path, area = GetNodePath(node)
																	local desc = parent.Desc:GetValue()
																	if(desc=="Description...")then desc="" end
																	parent.ActionNode = node
																	RunConsoleCommand("AdvDupe2_SaveFile", name, path, area, desc)
																end
										parent.FileName:SelectAllOnFocus(true)
										parent.FileName:OnMousePressed()
										parent.FileName:RequestFocus()
										parent.Expanding=true
										Slide(true)
										/*local name = parent.FileName:GetValue()
										if(name=="" || name=="File_Name...")then AdvDupe2.Notify("Name field is blank!", NOTIFY_ERROR) return end 
										local path, area = ParsePath(GetNodePath(node))
										local desc = parent.Desc:GetValue()
										if(desc=="Description...")then desc="" end
										RunConsoleCommand("AdvDupe2_SaveFile", parent.FileName:GetValue(), path, area, desc, node.ID)
										parent.FileName:SetValue("File_Name...")
										parent.Desc:SetValue("Description...")*/
									end)
			Menu:AddOption("New Folder", 	function() 
												if(parent.Expanding)then return end
												parent.Submit:SetMaterial("icon16/folder_add.png")
												parent.Submit:SetTooltip("Add new folder")
												if(parent.FileName:GetValue()=="File_Name...")then
													parent.FileName:SetValue("Folder_Name...")
												end
												parent.Desc:SetVisible(false)
												parent.FileName:SelectAllOnFocus(true)
												parent.FileName:OnMousePressed()
												parent.FileName:RequestFocus()
												parent.Expanding=true
												Slide(true)
												/*local name = parent.FileName:GetValue() 
												if(name=="" || name=="File_Name...")then AdvDupe2.Notify("Name field is blank!", NOTIFY_ERROR) return end 
												name = name:gsub("%W","") 
												local path, area = ParsePath(GetNodePath(node))
												RunConsoleCommand("AdvDupe2_NewFolder", name, path, area, node.ID) 
												parent.FileName:SetValue("File_Name...")
												parent.Desc:SetValue("Description...")*/
											end)
			Menu:AddOption("Search", Incomplete)
			if(node.Label:GetText()[1]!="-")then Menu:AddOption("Delete", function() Delete(self, true, true) end ) end
		end
	else
		if(node.Derma.ClassName == "advdupe2_browser_file")then 
			Menu:AddOption("Upload", function() Incomplete() end)//parent:FolderSelect(1, node.Name, GetNodePath(node), node) end)
			Menu:AddOption("Rename", 	function()
											Incomplete()
											/*RenameFileCl(node, parent.FileName:GetValue())
											parent.FileName:SetValue("File_Name...")
											parent.Desc:SetValue("Description...")*/
										end)
			Menu:AddOption("Move File", function() Incomplete() end) //parent:FolderSelect( 3, node.Name, GetNodePath(node), node) end)
			Menu:AddOption("Delete", function() Incomplete() end)//Delete(self, false, false) end)
		else
			Menu:AddOption("New Folder", 	function()
												if(parent.Expanding)then return end
												parent.Submit:SetMaterial("icon16/folder_add.png")
												parent.Submit:SetTooltip("Add new folder")
												if(parent.FileName:GetValue()=="File_Name...")then
													parent.FileName:SetValue("Folder_Name...")
												end
												parent.Desc:SetVisible(false)
												parent.Submit.DoClick = function() AddNewFolder(node) end
												parent.FileName:SelectAllOnFocus(true) 
												parent.FileName:OnMousePressed()
												parent.FileName:RequestFocus()
												parent.Expanding=true
												Slide(true)
											end)
			Menu:AddOption("Search", Incomplete)
			if(node.Label:GetText()[1]!="-")then Menu:AddOption("Delete", function() Delete(self, true, false) end) end
		end
	end

	Menu:AddOption("Collapse Folder", function() node.ParentNode:SetExpanded(false) end)
	Menu:AddOption("Collapse Root", function() CollapseParentsComplete(node) end)

	Menu:Open()
end

function BROWSER:DoNodeRightClick(node)
	BrowserDoNodeRightClick(self, node)
end

local function CollapseParents(node, val)
	if(!node)then return end
	node.ChildList:SetTall(node.ChildList:GetTall() - val)
	CollapseParents(node.ParentNode, val)
end

function BrowserRemoveNode(self, node)
	local parent = node.ParentNode
	parent.Nodes = parent.Nodes - 1
	if(node.IsFolder)then
		if(node.m_bExpanded)then
			CollapseParents(parent, node.ChildList:GetTall()+20)
			for i=1,#parent.ChildrenExpanded do
				if(node == parent.ChildrenExpanded[i])then
					table.remove(parent.ChildrenExpanded, i)
					break
				end
			end
		elseif(parent.m_bExpanded)then
			CollapseParents(parent, 20)
		end
		for i=1, #parent.Folders do
			if(node==parent.Folders[i])then
				table.remove(parent.Folders, i)
			end
		end
		node.ChildList:Remove()
		node:Remove()
	else
		for i=1, #parent.Files do
			if(node==parent.Files[i])then
				table.remove(parent.Files, i)
			end
		end
		CollapseParents(parent, 20)
		node:Remove()
	end
	if(self.VBar.Scroll>self.VBar.CanvasSize)then
		self.VBar:SetScroll(self.VBar.Scroll)
	end
end

function BROWSER:RemoveNode(node)
	BrowserRemoveNode(self, node)
end

function BrowserOnMouseWheeled(self, dlta )
	return self.VBar:OnMouseWheeled( dlta )
end

function BROWSER:OnMouseWheeled( dlta )
	BrowserOnMouseWheeled(self, dlta )
end

function BrowserAddFolder(self, text)
	local node = vgui.Create("advdupe2_browser_folder", self)
	node.Control = self
	
	node.Offset = 0
	node.ChildrenExpanded = {}
	node.Icon:SetPos(18, 1)
	node.Label:SetPos(44, 0)
	node.Label:SetText(text)
	node.Label:SizeToContents()
	node.ParentNode = self
	node.IsFolder = true
	self.Nodes = self.Nodes + 1
	node.Folders = {}
	node.Files = {}
	table.insert(self.Folders, node)
	self:SetTall(self:GetTall()+20)
	
	return node
end

function BROWSER:AddFolder( text )
	return BrowserAddFolder(self, text)
end

function BrowserAddFile(self, text)
	local node = vgui.Create("advdupe2_browser_file", self)
	node.Control = self
	node.Icon:SetPos(18, 1)
	node.Label:SetPos(44, 0)
	node.Label:SetText(text)
	node.Label:SizeToContents()
	node.ParentNode = self
	self.Nodes = self.Nodes + 1
	table.insert(self.File, node)
	
	return node
end

function BROWSER:AddFile( text )
	return BrowserAddFolder(self, text)
end

function BrowserSort(node)
	table.sort(node.Folders, function(a, b) return a.Label:GetText() < b.Label:GetText() end)	
	table.sort(node.Files, function(a, b) return a.Label:GetText() < b.Label:GetText() end)

	for i=1, #node.Folders do
		node.Folders[i]:SetParent(nil)
		node.Folders[i]:SetParent(node.ChildList)
		node.Folders[i].ChildList:SetParent(nil)
		node.Folders[i].ChildList:SetParent(node.ChildList)
	end
	for i=1, #node.Files do
		node.Files[i]:SetParent(nil)
		node.Files[i]:SetParent(node.ChildList)
	end
end

function BROWSER:Sort(node)
	BrowserSort(node)
end

function BrowserSetSelected(self, node)
	if(self.m_pSelectedItem)then self.m_pSelectedItem:SetSelected(false) end
	self.m_pSelectedItem = node
	if(node)then node:SetSelected(true) end
end

function BROWSER:SetSelected(node)
	BrowserSetSelected(self, node)
end

local function ExpandParents(node, val)
	if(!node)then return end
	node.ChildList:SetTall(node.ChildList:GetTall() + val)
	ExpandParents(node.ParentNode, val)
end

function BrowserExpand(node)
	node.ChildList:SetTall(node.Nodes*20)
	table.insert(node.ParentNode.ChildrenExpanded, node)
	ExpandParents(node.ParentNode, node.Nodes*20)
end

function BROWSER:Expand(node)
	BrowserExpand(node)
end

function BrowserCollapse(node)
	CollapseParents(node.ParentNode, node.ChildList:GetTall())

	for i=1, #node.ParentNode.ChildrenExpanded do
		if(node.ParentNode.ChildrenExpanded[i] == node)then
			table.remove(node.ParentNode.ChildrenExpanded, i)
			break
		end
	end
	CollapseChildren(node)
end

function BROWSER:Collapse(node)
	BrowserCollapse(node)
end

derma.DefineControl( "advdupe2_browser_tree", "AD2 File Browser", BROWSER, "Panel" )

local FOLDER = {}

AccessorFunc( FOLDER, "m_bBackground", 			"PaintBackground",	FORCE_BOOL )
AccessorFunc( FOLDER, "m_bgColor", 		"BackgroundColor" )

Derma_Hook( FOLDER, "Paint", "Paint", "Panel" )

function INIT_FOLDER(self)
	
	self:SetMouseInputEnabled( true )
	
	self:SetTall(20)
	self:SetPaintBackground( true )
	self:SetPaintBackgroundEnabled( false )
	self:SetPaintBorderEnabled( false )
	self:SetBackgroundColor(Color(0,0,0,0))
	

	self.Icon = vgui.Create( "DImage", self )
	self.Icon:SetImage( "icon16/folder.png" )
	
	self.Icon:SizeToContents()
	
	self.Label = vgui.Create("DLabel", self)
	self.Label:SetTextColor(Color(0,0,0))
	

	self.m_bExpanded = false
	self.Nodes = 0
	self.ChildrenExpanded = {}
	
	self:Dock(TOP)
	
	self.ChildList = vgui.Create("Panel", self:GetParent())
	self.ChildList:Dock(TOP)
	self.ChildList:SetTall(0)

end

function FOLDER:Init()
	INIT_FOLDER(self)
end

local function ExpandNode(self)
	self:GetParent():SetExpanded()
end

function FolderAddFolder(self, text)

	if(self.Nodes==0)then
		self.Expander = vgui.Create("DExpandButton", self)
		self.Expander.DoClick = ExpandNode
		self.Expander:SetPos(self.Offset, 2)
	end
	
	local node = vgui.Create("advdupe2_browser_folder", self.ChildList)
	node.Control = self.Control
	
	node.Offset = self.Offset+20

	node.Icon:SetPos(18 + node.Offset, 1)
	node.Label:SetPos(44 + node.Offset, 0)
	node.Label:SetText(text)
	node.Label:SizeToContents()
	node.ParentNode = self
	node.IsFolder = true
	node.Folders = {}
	node.Files = {}
	
	self.Nodes = self.Nodes + 1
	table.insert(self.Folders, node)
	
	return node
end

function FOLDER:AddFolder(text)
	return FolderAddFolder(self, text)
end

function FolderAddFile(self, text)
	
	if(self.Nodes==0)then
		self.Expander = vgui.Create("DExpandButton", self)
		self.Expander.DoClick = ExpandNode
		self.Expander:SetPos(self.Offset, 2)
	end

	local node = vgui.Create("advdupe2_browser_file", self.ChildList)
	node.Control = self.Control
	node.Offset = self.Offset+20
	node.Icon:SetPos(18 + node.Offset, 1)
	node.Label:SetPos(44 + node.Offset, 0)
	node.Label:SetText(text)
	node.Label:SizeToContents()
	node.ParentNode = self
	
	self.Nodes = self.Nodes + 1
	table.insert(self.Files, node)
	
	return node
end

function FOLDER:AddFile(text)
	return FolderAddFile(self, text)
end

function FolderSetExpand(self, bool)

	//self = self:GetParent()
	
	if(bool==nil)then self.m_bExpanded = !self.m_bExpanded else self.m_bExpanded = bool end
	self.Expander:SetExpanded(self.m_bExpanded)
	if(self.m_bExpanded)then
		self.Control:Expand(self)
	else
		self.Control:Collapse(self)
	end
end

function FOLDER:SetExpanded(bool)
	FolderSetExpand(self, bool)
end

local clrsel = Color(0,225,250)
local clrunsel = Color(0,0,0,0)

function FolderSetSelected(self, bool)
	if(bool)then
		self:SetBackgroundColor(clrsel)
	else
		self:SetBackgroundColor(clrunsel)
	end
end

function FOLDER:SetSelected(bool)
	FolderSetSelected(self, bool)
end


function FolderOnMousePressed(self, code)
	if(code==107)then
		self.Control:DoNodeLeftClick(self)
	elseif(code==108)then
		self.Control:DoNodeRightClick(self)
	end
end

function FOLDER:OnMousePressed(code)
	FolderOnMousePressed(self, code)
end

derma.DefineControl( "advdupe2_browser_folder", "AD2 Browser Folder node", FOLDER, "Panel" )








local FILE = {}

AccessorFunc( FILE, "m_bBackground", "PaintBackground",	FORCE_BOOL )
AccessorFunc( FILE, "m_bgColor", "BackgroundColor" )
Derma_Hook( FILE, "Paint", "Paint", "Panel" )

function INIT_FILE(self)
	
	self:SetMouseInputEnabled( true )
	
	self:SetTall(20)
	self:SetPaintBackground(true)
	self:SetPaintBackgroundEnabled(false)
	self:SetPaintBorderEnabled( false )
	self:SetBackgroundColor(Color(0,0,0,0))

	self.Icon = vgui.Create( "DImage", self )
	self.Icon:SetImage( "icon16/page.png" )
	
	self.Icon:SizeToContents()
	
	self.Label = vgui.Create("DLabel", self)
	
	self.Label:SetTextColor(Color(0,0,0))

	self:Dock(TOP)
end

function FILE:Init()
	INIT_FILE(self)
end

function FileSetSelected(self, bool)
	if(bool)then
		self:SetBackgroundColor(clrsel)
	else
		self:SetBackgroundColor(clrunsel)
	end
end

function FILE:SetSelected(bool)
	FileSetSelected(self, bool)
end

function FileOnMousePressed(self, code)
	if(code==107)then
		self.Control:DoNodeLeftClick(self)
	elseif(code==108)then
		self.Control:DoNodeRightClick(self)
	end
end

function FILE:OnMousePressed(code)
	FileOnMousePressed(self, code)
end

derma.DefineControl( "advdupe2_browser_file", "AD2 Browser File node", FILE, "Panel" )






local PANEL = {}
AccessorFunc( PANEL, "m_bBackground", "PaintBackground",	FORCE_BOOL )
AccessorFunc( PANEL, "m_bgColor", "BackgroundColor" )
Derma_Hook( PANEL, "Paint", "Paint", "Panel" )
Derma_Hook( PANEL, "PerformLayout", "Layout", "Panel" )

function PanelPerformLayout(self)
	
	if(self:GetWide()==self.LastX)then return end
	local x = self:GetWide()
	
	self.TabCtrl:SetWide(x)
	local x2, y2 = self.TabCtrl:GetPos()
	local BtnX = x - self.Help:GetWide() - 5
	self.Help:SetPos(BtnX, y2+3)
	BtnX = BtnX - self.Refresh:GetWide() - 5
	self.Refresh:SetPos(BtnX, y2+3)
	
	
	
	BtnX = x - self.Submit:GetWide() - 15
	self.Cancel:SetPos(BtnX, self.TabCtrl:GetTall())
	BtnX = BtnX - self.Submit:GetWide() - 5
	self.Submit:SetPos(BtnX, self.TabCtrl:GetTall())
	
	self.FileName:SetWide(BtnX - 10)
	self.Desc:SetWide(x-10)
	
	self.LastX = x
	
end

function PANEL:PerformLayout()
	PanelPerformLayout(self)
end

local pnlorigsetsize
local function PanelSetSize(self, x, y)	
	if(!self.LaidOut)then
		pnlorigsetsize(self, x, y)
		
		self.TabCtrl:SetSize(x, y)
		local x2, y2 = self.TabCtrl:GetPos()
		local BtnX = x - self.Help:GetWide() - 40
		self.Help:SetPos(BtnX, y2+3)
		BtnX = BtnX - self.Refresh:GetWide() - 5
		self.Refresh:SetPos(BtnX, y2+3)
	
		self.FileName:SetPos(5, self.TabCtrl:GetTall()-1)
		self.FileName:SetWide(x-100)
		self.Desc:SetPos(5, self.TabCtrl:GetTall()+18)
		self.Desc:SetWide(x-45)
		
		self.LaidOut = true
	else
		pnlorigsetsize(self, x, y)
	end
	
end

local function PurgeFiles(path, curParent)
	local files, directories = file.Find(path.."*", "DATA")
	for k,v in pairs(directories)do
		curParent = curParent:AddFolder(v)
		PurgeFiles(path..v.."/", curParent)
		curParent = curParent.ParentNode
	end
	for k,v in pairs(files)do
		curParent:AddFile(string.sub(v, 1, #v-4))
	end
end

local function UpdateClientFiles()

	for i=1,2 do
		if(panel.ClientBrw.pnlCanvas.Folders[1])then
			panel.ClientBrw.pnlCanvas:RemoveNode(panel.ClientBrw.pnlCanvas.Folders[1])
		end
	end

	PurgeFiles("advdupe2/", panel.ClientBrw.pnlCanvas:AddFolder("-Advanced Duplicator 2-"))

	PurgeFiles("adv_duplicator/", panel.ClientBrw.pnlCanvas:AddFolder("-Advanced Duplicator 1-"))
	
	if(panel.ClientBrw.pnlCanvas.Folders[2])then
		if(#panel.ClientBrw.pnlCanvas.Folders[2].Folders == 0 && #panel.ClientBrw.pnlCanvas.Folders[2].Files == 0)then
			panel.ClientBrw.pnlCanvas:RemoveNode(panel.ClientBrw.pnlCanvas.Folders[2])
		end
		
		panel.ClientBrw.pnlCanvas.Folders[1]:SetParent(nil)
		panel.ClientBrw.pnlCanvas.Folders[1]:SetParent(panel.ClientBrw.pnlCanvas.ChildList)
		panel.ClientBrw.pnlCanvas.Folders[1].ChildList:SetParent(nil)
		panel.ClientBrw.pnlCanvas.Folders[1].ChildList:SetParent(panel.ClientBrw.pnlCanvas.ChildList)
	end

end

function PanelInit(self)

	panel = self
	self.Expanded = false
	self.Expanding = false
	self.LastX = 0
	self.LastY = 0
	pnlorigsetsize = self.SetSize
	self.SetSize = PanelSetSize
	
	self:SetPaintBackground(true)
	self:SetPaintBackgroundEnabled(false)
	self:SetBackgroundColor(Color(125,125,125))
	
	self.TabCtrl = vgui.Create("DPropertySheet", self)
	self.ServerBrw = vgui.Create("advdupe2_browser_panel")
	
	if(game.SinglePlayer())then
		local Tab = self.TabCtrl:AddSheet( "Local", self.ServerBrw, "icon16/user.png", false, false, "Server Files" )
		Tab.Tab.Server = true
	else
		local Tab = self.TabCtrl:AddSheet( "Server", self.ServerBrw, "icon16/world.png", false, false, "Server Files" )
		Tab.Tab.Server = true
		
		self.ClientBrw = vgui.Create("advdupe2_browser_panel")
		Tab = self.TabCtrl:AddSheet( "Client", self.ClientBrw, "icon16/user.png", false, false, "Client Files" )
		Tab.Tab.Server = false
		UpdateClientFiles()
	end
	
	self.Refresh = vgui.Create("DImageButton", self)
	self.Refresh:SetMaterial( "icon16/arrow_refresh.png" )
	self.Refresh:SizeToContents()
	self.Refresh:SetTooltip("Refresh Files")
	self.Refresh.DoClick = 	function(button)
								if(self.TabCtrl:GetActiveTab().Server) then
									RunConsoleCommand("AdvDupe2_SendFiles", 0)
								else
									UpdateClientFiles()
								end
							end
	
	self.Help = vgui.Create("DImageButton", self)
	self.Help:SetMaterial( "icon16/help.png" )
	self.Help:SizeToContents()
	self.Help:SetTooltip("Help Section")
	self.Help.DoClick = function(btn)
							local Menu = DermaMenu()
							Menu:AddOption("Forum", function() gui.OpenURL("http://www.facepunch.com/threads/1136597") end)
							Menu:AddOption("Bug Reporting", function() gui.OpenURL("http://code.google.com/p/advdupe2/issues/list") end)
							Menu:AddOption("Controls", Incomplete)
							Menu:AddOption("Commands", Incomplete)
							Menu:AddOption("About", AdvDupe2.ShowSplash)
							Menu:Open()
						end
						
	self.Submit = vgui.Create("DImageButton", self)
	self.Submit:SetMaterial( "icon16/page_save.png" )
	self.Submit:SizeToContents()
	self.Submit:SetTooltip("Confirm Action")
	self.Submit.DoClick = 	function()
								self.Expanding=true 
								Slide(false)
								/*if(self.FileName:GetValue()=="" || self.FileName:GetValue()=="File_Name...")then AdvDupe2.Notify("Name field is blank!", NOTIFY_ERROR) return end
								--[[local _,changed = self.FileName:GetValue():gsub("[?.:\"*<>|]","")]]
								local desc = self.Desc:GetValue()
								if(desc=="Description...")then desc="" end
								RunConsoleCommand("AdvDupe2_SaveFile", self.FileName:GetValue(), "", 0, desc, 0)
								self.FileName:SetValue("File_Name...")
								self.Desc:SetValue("Description...")*/
							end
	
	self.Cancel = vgui.Create("DImageButton", self)
	self.Cancel:SetMaterial( "icon16/cancel.png" )
	self.Cancel:SizeToContents()
	self.Cancel:SetTooltip("Cancel Action")
	self.Cancel.DoClick = function() self.Expanding=true Slide(false) end

	self.FileName = vgui.Create("DTextEntry", self)
	self.FileName:SetAllowNonAsciiCharacters( true )
	self.FileName:SetValue("File_Name...")
	self.FileName.OnEnter = function()
								self.FileName:KillFocus()
								self.Desc:SelectAllOnFocus(true)
								self.Desc.OnMousePressed()
								self.Desc:RequestFocus()
							end
	self.FileName.OnMousePressed = 	function() 
										self.FileName:OnGetFocus() 
										if(self.FileName:GetValue()=="File_Name..." || self.FileName:GetValue()=="Folder_Name...")then 
											self.FileName:SelectAllOnFocus(true) 
										end 
									end
	self.FileName:SetUpdateOnType(true)
	self.FileName.OnTextChanged = 	function() 
										local new, changed = self.FileName:GetValue():gsub("[?.:\"*<>|]","")
										if changed > 0 then
											self.FileName:SetValue(new)
										end
									end
	self.FileName.OnValueChange = 	function()
										if(self.FileName:GetValue()!="File_Name..." && self.FileName:GetValue()!="Folder_Name...")then
											local new,changed = self.FileName:GetValue():gsub("[?.:\"*<>|]","")
											if changed > 0 then
												self.FileName:SetValue(new)
											end
										end
									end
	
	self.Desc = vgui.Create("DTextEntry", self)
	self.Desc.OnEnter = self.Submit.DoClick
	self.Desc:SetValue("Description...")
	self.Desc.OnMousePressed = 	function() 					
									self.Desc:OnGetFocus()
									if(self.Desc:GetValue()=="Description...")then 
										self.Desc:SelectAllOnFocus(true) 
									end 
								end

end

function PANEL:Init()
	PanelInit(self)
end

local function AddFiles(len, ply, len2)

	local pos = 0
	local func
	local name
	local curParent
	local Controller = panel.ServerBrw.pnlCanvas
	for i=1,3 do
		if(Controller.Folders[1])then
			Controller:RemoveNode(Controller.Folders[1])
		else
			break
		end
	end
	
	while(pos<len)do
		func = net.ReadInt(8)
		if(func == 0)then
			pos = pos + 8
			curParent = Controller:AddFolder("-Advanced Duplicator 2-")
		elseif(func == 1)then
			pos = pos + 8
			curParent = Controller:AddFolder("-Public-")
		elseif(func == 2)then
			pos = pos + 8
			curParent = Controller:AddFolder("-Advanced Duplicator 1-")
		elseif(func == 3)then
			pos = pos + 8
			curParent = curParent.ParentNode
		elseif(func == 4)then
			name = net.ReadString()
			pos = pos + #name*8 + 16
			curParent = curParent:AddFolder(name)
		elseif(func == 5)then
			name = net.ReadString()
			pos = pos + #name*8 + 16
			curParent:AddFile(name)
		end
	end
	
	for i=2,3 do
		if(Controller.Folders[i] && Controller.Folders[i].Label:GetText()=="-Advanced Duplicator 1-" && #Controller.Folders[i].Folders == 0 && #Controller.Folders[i].Files == 0)then
			Controller:RemoveNode(Controller.Folders[i])
			break
		end
	end
	

	if(Controller.Folders[2])then
		Controller.Folders[1]:SetParent(nil)
		Controller.Folders[1]:SetParent(Controller.ChildList)
		Controller.Folders[1].ChildList:SetParent(nil)
		Controller.Folders[1].ChildList:SetParent(Controller.ChildList)
	end

end
net.Receive("AdvDupe2_SendFiles", AddFiles)

net.Receive("AdvDupe2_AddFile", function() panel.ActionNode:AddFile(net.ReadString()) Slide(false) end)

vgui.Register("advdupe2_browser", PANEL, "Panel")