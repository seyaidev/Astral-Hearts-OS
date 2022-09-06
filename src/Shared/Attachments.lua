local Attachments = {}

function Attachments:setAttachmentWorldCFrame(attachment, cf)
	if not attachment or not cf then print('not attachment or not cf') return end
	attachment.CFrame = attachment.Parent.CFrame:toObjectSpace(cf)
end

function Attachments:getAttachmentWorldCFrame(attachment)
	return attachment.Parent.CFrame:toWorldSpace(attachment.CFrame)
end

return Attachments