include("shared.lua")

function ENT:Draw()
	self.BaseClass.Draw(self)
	self.Entity:DrawModel()
end

function ENT:RemoveGhosts()
	for k,v in pairs(self.GhostEntities)do
		v:Remove()
	end
end

net.Receive("AdvDupe2_SendContraptionGhost", function()
	local self = ents.GetByIndex(net.ReadInt(16))
	local ghost
	local ghostent
	local HeadAngle = net.ReadAngle()
	local Offset = net.ReadVector()
	local CurAngle = self:GetAngles()
	self:CallOnRemove("AdvDupe2_RemoveGhosts", self.RemoveGhosts, self)
	self.GhostEntities = {}
	
	for i=1, net.ReadInt(16) do
		ghost = {R = net.ReadBit(), Model = net.ReadString(), PhysicsObjects = {}}
		for k=0, net.ReadInt(8) do
			ghost.PhysicsObjects[k] = {Angle = net.ReadAngle(), Pos = net.ReadVector()}
		end
		
		ghostent = ClientsideModel(ghost.Model, RENDERGROUP_TRANSLUCENT)
		if not IsValid(ghostent) then
			return
		end
		
		ghostent:SetRenderMode( RENDERMODE_TRANSALPHA )
		ghostent:SetColor( Color(255, 255, 255, 150) )
		ghostent:SetAngles(ghost.PhysicsObjects[0].Angle)
		ghostent:SetPos(self:GetPos() + ghost.PhysicsObjects[0].Pos - Offset)
		self:SetAngles(HeadAngle)
		ghostent:SetParent( self )
		self.GhostEntities[i] = ghostent
	end
	
	self:SetAngles(CurAngle)
end)
