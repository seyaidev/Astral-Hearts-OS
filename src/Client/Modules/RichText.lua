--[[
	
Rich text markup with support for modifying any TextLabel property per character + inline images + entrance animations

Written by Defaultio ~ August 30 2017

Changes:	
	October 21 2017 - Unicode support added thanks to Tiffany Bennett - https://gist.github.com/tiffany352/ccb3559738f4e8d4152d940126998c41
	January 29 2017 - Added finishAnimate parameter to RichTextObject:Show() function
					- Fixed bug on iOS devices causing some characters to fail to appear. Using TextWrapped = false on character labels fixed this, thanks Buildthomas.


			TODO:
				- exit animations
				- emphasis animations
				- support for inline buttons
				- sounds for each text step
				- markup events that will fire a callback provided in the constructor when the text animation is reached, use for character animations, etc
			
			Let me know if these features will be useful and I'll add them more quickly.

___________________________________________________________________________________________________________________

API:

Constructor:

	RichText:New(GuiObject frame, String text, Dictionary startingProperties = {}, Boolean allowOverflow = true)
		frame: the parent frame which will be populated with text
		text: self explanitory
		startingProperties: a dictionary of what the default text properties should be
		allowOverflow: if false, text will stop rendering when it fills the vertical height of the frame. To continue the text in another frame, see RichText:ContinueOverflow() below...
		
		returns: richText object
			
	RichText:ContinueOverflow(GuiObject nextFrame, RichTextObject previousRichTextObject)
		nextFrame: the parent frame that text will continue into
		previousRichTextObject: the previous RichTextObject that is being overflown from.
		
		returns: richTextObject
	
			
RichText Object: (returned by constructor)

	RichTextObject:Animate(doYield = false)
		Will run the animation. If doYield is true, the thread will yield until the animation is complete. Else, it will wrap the animation function in a coroutine
		
	RichTextObject:Show(finishAnimation = false)
		Shows the entirety of the text body. Will interrupt and stop the animation if it's running. if finishAnimation is true, the remaining text will animate in instead of appearing instantly.
		
	RichTextObject:Hide()
		Hides the text body. Will interrupt and stop the animation if it's running. The animation can be replayed after hiding.
		
	
	Vector2 RichTextObject.ContentSize
		Content size in pixels
		
	Boolean RichTextObject.Overflown
		If allowOverflow was false, this value shows if the text is overflown or if it fit in the frame. If overflown, use RichText:ContinueOverflow to continue into a new frame.
		


___________________________________________________________________________________________________________________

USAGE:

The text supplied in the constructor can be any text string. Insert a markup modifier by including <MarkupKey=MarkupValue>. No spaces.

	Examples of what this looks like include:
		<Font=ArialBold> --Set the font to ArialBold
		<Img=639588687> -- Insert an inline image with this ID
		<AnimateStepTime=0.4> -- Set the animate step time to 0.4 seconds.
		<AnimateYield=1> -- Yield for one second at this point in the animation
		<TextColor3=1,0,0> -- Set text color to red
		<Color=Red> -- Equivalent to above. The shortcut for the property name is defined in the propertyShortcuts table, and the color shortcut is defined in the colors table.
		
	After you set any markup value, you can revert it back to default later by setting it to "/". For example:
		<Font=/>
		<AnimateStepTime=/>
		<Color=/>
		
	Default values are defined by values in the "default" table below, or by values supplied in the startingProperties dictionary when the object is constructed.

Currently does not support escapement characters for < and >, so you can't use these characters in the text string.


To when using RichText:ContinueOverflow, calling Animate(), Show(), or Hide() on the initial RichText object will pass this call onto subsequent overflown rich text objects, so
only a call to the first object is neccessary. See example.

___________________________________________________________________________________________________________________

Example code:

	local richText = require(richTextModule)
	local text = "Hello world!\nLine two! <AnimateDelay=1><Img=Thinking>"
	local textObject = richText:New(frame, text)
	textObject:Animate(true)
	print("Animation done!")


Example string 1: Basic

	local text = "<Font=SourceSansBold><TextScale=0.3>Oh!<TextScale=/><Font=/><AnimateYield=1> I didn't see you there<AnimateStepFrequency=1><AnimateStepTime=0.4> . . .<AnimateStepFrequency=/><AnimateStepTime=/>\n I wasn't expecting <Color=255,0,0>you<Color=/>. Please forgive the state of my room.<AnimateYield=1><Img=639588687>"
	
	--This yields this result: https://twitter.com/Defaultio/status/903094769617747968


Example string 2: Wind Waker

	Insert the WindWakerExample ScreenGui in this module into StarterGui.
	Insert this module into WindWakerExample.
	Ensure WindWakerExample.LocalText is not Disabled.
	
	-- This yields this result: https://twitter.com/Defaultio/status/903138250054709248
	
	
Example string 3: Text-in animations

	local text = "This text is about to be <Color=Green><AnimateStyle=Wiggle><AnimateStepFrequency=1><AnimateStyleTime=2>wiggly<AnimateStyle=/><AnimateStepFrequency=/><AnimateStyleTime=/><Color=/>!<AnimateYield=1.5>\nIt can also be <Color=Red><AnimateStyle=Fade><AnimateStepFrequency=1><AnimateStyleTime=0.5>fadey fadey<AnimateStyle=/><AnimateStepFrequency=/><AnimateStyleTime=/><Color=/>!<AnimateYield=1>\n<AnimateStyle=Rainbow><AnimateStyleTime=2>Or rainbow!!! :O<AnimateStyle=/><AnimateStyleTime=/><AnimateYield=1>\n<AnimateStyle=Swing><AnimateStyleTime=3>Make custom animations!"
	
	-- This yields this result: https://twitter.com/Defaultio/status/903346975688425472
	
	
Example string 4: Variable text justification per line

	local text = "Have you ever <Color=Red>thought<Color=/><AnimateStepFrequency=1><AnimateStepTime=0.4> . . .<AnimateStepFrequency=/><AnimateStepTime=/><AnimateYield=1><ContainerHorizontalAlignment=Center>\n<TextScale=0.5><AnimateStyle=Rainbow><AnimateStyleTime=2.5><Img=Thinking><AnimateStyle=/><TextScale=/><AnimateYield=3><ContainerHorizontalAlignment=Right>\n<Color=Green><AnimateStyle=Spin><AnimateStyleTime=1.5>Wow<AnimateStyle=/><Color=/>!"

	-- This yields this result: https://twitter.com/Defaultio/status/903381787467956224

Example 5: Overflowing

	Insert the OverflowingExample ScreenGui in this module into StarterGui.
	Inert this module into the OverflowingExample ScreenGui.
	Ensure OverflowingExample.LocalText is not disabled.
	
	-- This yields this result: https://twitter.com/Defaultio/status/918619989107621888

___________________________________________________________________________________________________________________	
	
--]]

local richText = {}

--------- SHORTCUTS ---------

-- Color shortcuts: you can use these strings instead of full property names
local propertyShortcuts = {}
propertyShortcuts.Color = "TextColor3"
propertyShortcuts.StrokeColor = "TextStrokeColor3"
propertyShortcuts.ImageColor = "ImageColor3"

-- Color shortcuts: you can use these strings instead of defining exact color values
richText.ColorShortcuts = {}
richText.ColorShortcuts.White = Color3.new(1, 1, 1)
richText.ColorShortcuts.Black = Color3.new(0, 0, 0)
richText.ColorShortcuts.Red = Color3.new(1, 0.4, 0.4)
richText.ColorShortcuts.Green = Color3.new(0.4, 1, 0.4)
richText.ColorShortcuts.Blue = Color3.new(0.4, 0.4, 1)
richText.ColorShortcuts.Cyan = Color3.new(0.4, 0.85, 1)
richText.ColorShortcuts.Orange = Color3.new(1, 0.5, 0.2)
richText.ColorShortcuts.Yellow = Color3.new(1, 0.9, 0.2)

richText.ColorShortcuts.Astral = Color3.fromRGB(217, 136, 224)
richText.ColorShortcuts.Player = Color3.fromRGB(204, 198, 255)
richText.ColorShortcuts.Heart = Color3.fromRGB(255, 61, 110)
richText.ColorShortcuts.Quest = Color3.fromRGB(255, 139, 61)
richText.ColorShortcuts.NPC = Color3.fromRGB(255, 213, 123)
richText.ColorShortcuts.Accept = Color3.fromRGB(77, 227, 82)
richText.ColorShortcuts.Important = Color3.fromRGB(255, 246, 115)

-- Image shortcuts: you can use these string instead of using image ids
richText.ImageShortcuts = {}
richText.ImageShortcuts.Eggplant = 639588687
richText.ImageShortcuts.Thinking = 955646496
richText.ImageShortcuts.Sad = 947900188
richText.ImageShortcuts.Happy = 414889555
richText.ImageShortcuts.Despicable = 711674643

--------- DEFAULTS ---------

local defaults = {}

--Text alignment default properties
defaults.ContainerHorizontalAlignment = "Left" -- Align,ent of text within frame container
defaults.ContainerVerticalAlignment = "Center" 
defaults.TextYAlignment = "Bottom" -- Alignment of the text on the line, only makes a difference if the line has variable text sizes

-- Text size default properties
defaults.TextScaled = true
defaults.TextScaleRelativeTo = "Frame" -- "Frame" or "Screen" If Frame, will scale relative to vertical size of the parent frame. If Screen, will scale relative to vertical size of the ScreenGui.
defaults.TextScale = 0.2 -- If you want the frame to have a nominal count of n lines of text, make this value 1 / n. For four lines, 1 / 4 = 0.25.
defaults.TextSize = 20 -- Only applicable if TextScaled = false

-- TextLabel default properties
defaults.Font = "SourceSans"
defaults.TextColor3 = "White"
defaults.TextStrokeColor3 = "Black"
defaults.TextTransparency = 0
defaults.TextStrokeTransparency = 1
defaults.BackgroundTransparency = 1
defaults.BorderSizePixel = 0

-- Image label default properties
defaults.ImageColor3 = "White"
defaults.ImageTransparency = 0
defaults.ImageRectOffset = "0,0"
defaults.ImageRectSize = "0,0"

-- Text animation default properties
	-- character appearance timing:
defaults.AnimateStepTime = 0 -- Seconds between newframes
defaults.AnimateStepGrouping = "Letter" -- "Word" or "Letter" or "All"
defaults.AnimateStepFrequency = 4 -- How often to step, 1 is all, 2 is step in pairs, 3 is every three, etc.
	-- yielding:
defaults.AnimateYield = 0 -- Set this markup to yield
	-- entrance style parameters:
defaults.AnimateStyle = "Appear"
defaults.AnimateStyleTime = 0.5 -- How long it takes for an entrance style to fully execute
defaults.AnimateStyleNumPeriods = 3 -- Used differently for each entrance style
defaults.AnimateStyleAmplitude = 0.5 -- Used differently for each entrance style


--------- ENTRANCE ANIMATION FUNCTIONS ---------

-- These are functions responsible for animating how text enters. The functions are passed:
	-- characters: A list of the characters to be animated.
	-- animateAlpha: A value of 0 - 1 that represents the lifetime of the animation
	-- properties: A dictionary of all the properties at that character, including InitialSize and InitialPosition
	
local animationStyles = {}

function animationStyles.Appear(character)
	character.Visible = true
end

function animationStyles.Fade(character, animateAlpha, properties)
	character.Visible = true
	if character:IsA("TextLabel") then
		character.TextTransparency = 1 - (animateAlpha * (1 - properties.TextTransparency))
	elseif character:IsA("ImageLabel") then
		character.ImageTransparency = 1 - (animateAlpha * (1 - properties.ImageTransparency))
	end
end

function animationStyles.Wiggle(character, animateAlpha, properties)
	character.Visible = true
	local amplitude = properties.InitialSize.Y.Offset * (1 - animateAlpha) * properties.AnimateStyleAmplitude
	character.Position = properties.InitialPosition + UDim2.new(0, 0, 0, math.sin(animateAlpha * math.pi * 2 * properties.AnimateStyleNumPeriods) * amplitude / 2)
end

function animationStyles.Swing(character, animateAlpha, properties)
	character.Visible = true
	local amplitude = 90 * (1 - animateAlpha) * properties.AnimateStyleAmplitude
	character.Rotation = math.sin(animateAlpha * math.pi * 2 * properties.AnimateStyleNumPeriods) * amplitude
end

function animationStyles.Spin(character, animateAlpha, properties)
	character.Visible = true
	character.Position = properties.InitialPosition + UDim2.new(0, properties.InitialSize.X.Offset / 2, 0, properties.InitialSize.Y.Offset / 2)
	character.AnchorPoint = Vector2.new(0.5, 0.5)
	character.Rotation = animateAlpha * properties.AnimateStyleNumPeriods * 360
end

function animationStyles.Rainbow(character, animateAlpha, properties)
	character.Visible = true
	local rainbowColor = Color3.fromHSV(animateAlpha * properties.AnimateStyleNumPeriods % 1, 1, 1)
	if character:IsA("TextLabel") then
		local initialColor = getColorFromString(properties.TextColor3)
		character.TextColor3 = Color3.new(rainbowColor.r + animateAlpha * (initialColor.r - rainbowColor.r), rainbowColor.g + animateAlpha * (initialColor.g - rainbowColor.g), rainbowColor.b + animateAlpha * (initialColor.b - rainbowColor.b))
	else
		local initialColor = getColorFromString(properties.ImageColor3)
		character.ImageColor3 = Color3.new(rainbowColor.r + animateAlpha * (initialColor.r - rainbowColor.r), rainbowColor.g + animateAlpha * (initialColor.g - rainbowColor.g), rainbowColor.b + animateAlpha * (initialColor.b - rainbowColor.b))
	end
end


--------- MODULE BEGIN ---------

local textService = game:GetService("TextService")
local runService = game:GetService("RunService")
local animationCount = 0

function getLayerCollector(frame)
	if not frame then
		return nil
	elseif frame:IsA("LayerCollector") then
		return frame
	elseif frame and frame.Parent then
		return getLayerCollector(frame.Parent)
	else
		return nil
	end
end

function shallowCopy(tab)
	local ret = {}
	for key, value in pairs(tab) do
		ret[key] = value
	end
	return ret
end

function getColorFromString(value)
	if richText.ColorShortcuts[value] then
		 return richText.ColorShortcuts[value]
	else
		local r, g, b = value:match("(%d+),(%d+),(%d+)")
		return Color3.new(r / 255, g / 255, b / 255)
	end
end

function getVector2FromString(value)
	local x, y = value:match("(%d+),(%d+)")
	return Vector2.new(x, y)
end

function setHorizontalAlignment(frame, alignment)
	if alignment == "Left" then
		frame.AnchorPoint = Vector2.new(0, 0)
		frame.Position = UDim2.new(0, 0, 0, 0)
	elseif alignment == "Center" then
		frame.AnchorPoint = Vector2.new(0.5, 0)
		frame.Position = UDim2.new(0.5, 0, 0, 0)
	elseif alignment == "Right" then
		frame.AnchorPoint = Vector2.new(1, 0)
		frame.Position = UDim2.new(1, 0, 0, 0)
	end
end

function richText:New(frame, text, startingProperties, allowOverflow, prevTextObject)
	for _, v in pairs(frame:GetChildren()) do
		v:Destroy()
	end
	if allowOverflow == nil then
		allowOverflow = true
	end
	
	local properties = {}
	local defaultProperties = {}
	if prevTextObject then
		text = prevTextObject.Text
		startingProperties = prevTextObject.StartingProperties
	end
	
	local lineFrames = {}
	local textFrames = {}
	local frameProperties = {}
	local linePosition = 0
	local overflown = false
	local textLabel = Instance.new("TextLabel")
	local imageLabel = Instance.new("ImageLabel")
	local layerCollector = getLayerCollector(frame)
	
	local applyProperty, applyMarkup, formatLabel, printText, printImage, printSeries
	
	----- Apply properties / markups -----
	function applyMarkup(key, value)
		key = propertyShortcuts[key] or key
		if value == "/" then
			if defaultProperties[key] then
				value = defaultProperties[key]
			else
				warn("Attempt to default <"..key.."> to value with no default")
			end
		end
		if tonumber(value) then
			value = tonumber(value)
		elseif value == "false" or value == "true" then
			value = value == "true"
		end
		properties[key] = value
		
		if applyProperty(key, value) then
			-- Ok
		elseif key == "ContainerHorizontalAlignment" and lineFrames[#lineFrames] then
			setHorizontalAlignment(lineFrames[#lineFrames].Container, value)
		elseif defaults[key] then
			-- Ok
		elseif key == "Img" then
			printImage(value)
		else
			-- Unknown value
			return false	
		end
		return true
	end
	
	function applyProperty(name, value, frame)
		local propertyType
		local ret = false
		for _, label in pairs(frame and {frame} or {textLabel, imageLabel}) do
			local isProperty = pcall(function() propertyType = typeof(label[name]) end) -- is there a better way to check if it's a property?
			if isProperty then
				if propertyType == "Color3" then
					label[name] = getColorFromString(value)
				elseif propertyType == "Vector2" then
					label[name] = getVector2FromString(value)
				else
					label[name] = value	
				end
				ret = true	
			end
		end
		return ret
	end
	
	----- Set up default properties -----
	for name, value in pairs(defaults) do
		applyMarkup(name, value)
		defaultProperties[propertyShortcuts[name] or name] = properties[propertyShortcuts[name] or name]
	end
	for name, value in pairs(startingProperties or {}) do
		applyMarkup(name, value)
		defaultProperties[propertyShortcuts[name] or name] = properties[propertyShortcuts[name] or name]
	end
	
	if prevTextObject then
		properties = prevTextObject.OverflowPickupProperties
		for name, value in pairs(properties) do
			applyMarkup(name, value)
		end
	end
	
	----- Get vertical size -----
	local function getTextSize()
		if properties.TextScaled == true then
			local relativeHeight
			if properties.TextScaleRelativeTo == "Screen" then
				relativeHeight = layerCollector.AbsoluteSize.Y
			elseif properties.TextScaleRelativeTo == "Frame" then
				relativeHeight = frame.AbsoluteSize.Y
			end
			return math.min(properties.TextScale * relativeHeight, 100)
		else
			return properties.TextSize
		end
	end
	
	----- Lines -----
	local contentHeight = 0
	local function newLine()
		local lastLineFrame = lineFrames[#lineFrames]
		if lastLineFrame then
			contentHeight = contentHeight + lastLineFrame.Size.Y.Offset
			if not allowOverflow and contentHeight + getTextSize() > frame.AbsoluteSize.Y then
				overflown = true
				return
			end
		end
		local lineFrame = Instance.new("Frame")
		lineFrame.Name = string.format("Line%03d", #lineFrames + 1)
		lineFrame.Size = UDim2.new(0, 0, 0, 0)
		lineFrame.BackgroundTransparency = 1		
		local textContainer = Instance.new("Frame", lineFrame)
		textContainer.Name = "Container"
		textContainer.Size = UDim2.new(0, 0, 0, 0)
		textContainer.BackgroundTransparency = 1
		setHorizontalAlignment(textContainer, properties.ContainerHorizontalAlignment)
		lineFrame.Parent = frame
		table.insert(lineFrames, lineFrame)
		textFrames[#lineFrames] = {}
		linePosition = 0
	end
	newLine()
	
	----- Label printing -----
	local function addFrameProperties(frame)
		frameProperties[frame] = shallowCopy(properties)
		frameProperties[frame].InitialSize = frame.Size
		frameProperties[frame].InitialPosition = frame.Position
		frameProperties[frame].InitialAnchorPoint = frame.AnchorPoint
	end
	
	function formatLabel(newLabel, labelHeight, labelWidth, endOfLineCallback)
		local lineFrame = lineFrames[#lineFrames]
		
		local verticalAlignment = tostring(properties.TextYAlignment)
		if verticalAlignment  == "Top" then
			newLabel.Position = UDim2.new(0, linePosition, 0, 0)
			newLabel.AnchorPoint = Vector2.new(0, 0)
		elseif verticalAlignment  == "Center" then
			newLabel.Position = UDim2.new(0, linePosition, 0.5, 0)
			newLabel.AnchorPoint = Vector2.new(0, 0.5)
		elseif verticalAlignment  == "Bottom" then
			newLabel.Position = UDim2.new(0, linePosition, 1, 0)
			newLabel.AnchorPoint = Vector2.new(0, 1)
		end
		
		linePosition = linePosition + labelWidth
		if linePosition > frame.AbsoluteSize.X and not (linePosition == labelWidth) then
			-- Newline, get rid of label and retry it on the next line
			newLabel:Destroy()
			local lastLabel = textFrames[#lineFrames][#textFrames[#lineFrames]]
			if lastLabel:IsA("TextLabel") and lastLabel.Text == " " then -- get rid of trailing space
				lineFrame.Container.Size = UDim2.new(0, linePosition - labelWidth - lastLabel.Size.X.Offset, 1, 0)
				lastLabel:Destroy()
				table.remove(textFrames[#lineFrames])
			end
			newLine()
			endOfLineCallback()
		else
			-- Label is ok
			newLabel.Size = UDim2.new(0, labelWidth, 0, labelHeight)
			lineFrame.Container.Size = UDim2.new(0, linePosition, 1, 0)
			lineFrame.Size = UDim2.new(1, 0, 0, math.max(lineFrame.Size.Y.Offset, labelHeight))
			newLabel.Name = string.format("Group%03d", #textFrames[#lineFrames] + 1)
			newLabel.Parent = lineFrame.Container
			table.insert(textFrames[#lineFrames], newLabel)
			addFrameProperties(newLabel)
			properties.AnimateYield = 0
		end
	end
	
	function printText(text)
		if text == "\n" then
			newLine()
			return
		elseif text == " " and linePosition == 0 then
			return -- no leading spaces
		end
		
		local textSize = getTextSize()
		local textWidth = textService:GetTextSize(text, textSize, textLabel.Font, Vector2.new(layerCollector.AbsoluteSize.X, textSize)).X
		
		local newTextLabel = textLabel:Clone()
		newTextLabel.TextScaled = false
		newTextLabel.TextSize = textSize
		newTextLabel.Text = text -- This text is never actually displayed. We just use it as a reference for knowing what the group string is.
		newTextLabel.TextTransparency = 1
		newTextLabel.TextStrokeTransparency = 1
		newTextLabel.TextWrapped = false
		
		-- Keep the real text in individual frames per character:
		local charPos = 0
		local i = 1
		for first, last in utf8.graphemes(text) do
			local character = string.sub(text, first, last)
			local characterWidth = textService:GetTextSize(character, textSize, textLabel.Font, Vector2.new(layerCollector.AbsoluteSize.X, textSize)).X
			local characterLabel = textLabel:Clone()
			characterLabel.Text = character
			characterLabel.TextScaled = false
			characterLabel.TextSize = textSize
			characterLabel.Position = UDim2.new(0, charPos, 0, 0)
			characterLabel.Size = UDim2.new(0, characterWidth, 0, textSize)
			characterLabel.Name = string.format("Char%03d", i)
			characterLabel.Parent = newTextLabel
			characterLabel.Visible = false
			addFrameProperties(characterLabel)
			charPos = charPos + characterWidth
			i = i + 1
		end

		formatLabel(newTextLabel, textSize, textWidth, function() if not overflown then printText(text) end end)
	end
	
	function printImage(imageId)
		local imageHeight = getTextSize()
		local imageWidth = imageHeight -- Would be nice if we could get aspect ratio of image to get width properly.
		
		local newImageLabel = imageLabel:Clone()
		
		if richText.ImageShortcuts[imageId] then
			newImageLabel.Image = typeof(richText.ImageShortcuts[imageId]) == "number" and "rbxassetid://"..richText.ImageShortcuts[imageId] or richText.ImageShortcuts[imageId]
		else
			newImageLabel.Image = "rbxassetid://"..imageId
		end
		newImageLabel.Size = UDim2.new(0, imageHeight, 0, imageWidth)
		newImageLabel.Visible = false

		formatLabel(newImageLabel, imageHeight, imageWidth, function() if not overflown then printImage(imageId) end end)
	end
	
	function printSeries(labelSeries)	
		for _, t in pairs(labelSeries) do
			local markupKey, markupValue = string.match(t, "{(.+)=(.+)}")
			if markupKey and markupValue then
				if not applyMarkup(markupKey, markupValue) then
					warn("Could not apply markup: ", t)
				end			
			else
				printText(t)
			end
		end	
	end
	
	----- Text traversal + parsing -----
	local overflowText
	local textPos = 1
	local textLength = #text
	local labelSeries = {}
	
	if prevTextObject then
		textPos = prevTextObject.OverflowPickupIndex
	end
	
	while textPos and textPos <= textLength do
		local nextMarkupStart, nextMarkupEnd = string.find(text, "{.-}", textPos)
		local nextSpaceStart, nextSpaceEnd = string.find(text, "[ \t\n]", textPos)
		
		local nextBreakStart, nextBreakEnd, breakIsWhitespace
		if nextMarkupStart and nextMarkupEnd and (not nextSpaceStart or nextMarkupStart < nextSpaceStart) then
			nextBreakStart, nextBreakEnd = nextMarkupStart, nextMarkupEnd
		else
			nextBreakStart, nextBreakEnd = nextSpaceStart or textLength + 1, nextSpaceEnd or textLength + 1
			breakIsWhitespace = true
		end
		
		local nextWord = nextBreakStart > textPos and string.sub(text, textPos, nextBreakStart - 1) or nil
		local nextBreak = nextBreakStart <= textLength and string.sub(text, nextBreakStart, nextBreakEnd) or nil
		table.insert(labelSeries, nextWord)
		
		if breakIsWhitespace then
			printSeries(labelSeries)
			if overflown then
				break
			end
			printSeries({nextBreak})
			if overflown then
				textPos = nextBreakStart
				break
			end
			labelSeries = {}
		else
			table.insert(labelSeries, nextBreak)
		end
		
		textPos = nextBreakEnd + 1
		--textPos = utf8.offset(text, 2, nextBreakEnd)
	end
	
	if not overflown then
		printSeries(labelSeries)
	end

	----- Alignment layout -----
	local listLayout = Instance.new("UIListLayout")
	listLayout.HorizontalAlignment = properties.ContainerHorizontalAlignment
	listLayout.VerticalAlignment = properties.ContainerVerticalAlignment
	listLayout.Parent = frame
	
	----- Calculate content size -----
	local contentHeight = 0
	local contentLeft = frame.AbsoluteSize.X
	local contentRight = 0
	for _, lineFrame in pairs(lineFrames) do
		contentHeight = contentHeight + lineFrame.Size.Y.Offset
		local container = lineFrame.Container
		local left, right
		if container.AnchorPoint.X == 0 then
			left = container.Position.X.Offset
			right = container.Size.X.Offset
		elseif container.AnchorPoint.X == 0.5 then
			left = lineFrame.AbsoluteSize.X / 2 - container.Size.X.Offset / 2
			right = lineFrame.AbsoluteSize.X / 2 + container.Size.X.Offset / 2
		elseif container.AnchorPoint.X == 1 then
			left = lineFrame.AbsoluteSize.X - container.Size.X.Offset
			right = lineFrame.AbsoluteSize.X
		end
		contentLeft = math.min(contentLeft, left)
		contentRight = math.max(contentRight, right)
	end
	
	----- Animation -----
	animationCount = animationCount + 1
	local animationDone = false
	local allTextReached = false
	local overrideYield = false
	local animationRenderstepBinding = "TextAnimation"..animationCount
	local animateQueue = {}
	
	local function updateAnimations()
		if allTextReached and #animateQueue == 0 or animationDone then
			animationDone = true
			runService:UnbindFromRenderStep(animationRenderstepBinding)
			animateQueue = {}
			return
		end

		local t = tick()
		for i = #animateQueue, 1, -1 do
			local set = animateQueue[i]
			local properties = set.Settings
			local animateStyle = animationStyles[properties.AnimateStyle]
			if not animateStyle then
				warn("No animation style found for: ", properties.AnimateStyle, ", defaulting to Appear")
				animateStyle = animationStyles.Appear
			end
			local animateAlpha = math.min((t - set.Start) / properties.AnimateStyleTime, 1)
			animateStyle(set.Char, animateAlpha, properties) 
			if animateAlpha >= 1 then
				table.remove(animateQueue, i)
			end
		end
	end
	
	local function setFrameToDefault(frame)
		frame.Position = frameProperties[frame].InitialPosition
		frame.Size = frameProperties[frame].InitialSize
		frame.AnchorPoint = frameProperties[frame].InitialAnchorPoint
		for name, value in pairs(frameProperties[frame]) do
			applyProperty(name, value, frame)
		end
	end

	local function setGroupVisible(frame, visible)
		frame.Visible = visible
		for _, v in pairs(frame:GetChildren()) do
			v.Visible = visible
			if visible then
				setFrameToDefault(v)
			end
		end
		if visible and frame:IsA("ImageLabel") then
			setFrameToDefault(frame)
		end
	end

	local function animate(waitForAnimationToFinish)
		animationDone = false
		runService:BindToRenderStep(animationRenderstepBinding, Enum.RenderPriority.Last.Value, updateAnimations)

		local stepGrouping
		local stepTime
		local stepFrequency
		local numAnimated
		
		-- Make everything invisible to start
		for lineNum, list in pairs(textFrames) do
			for _, frame in pairs(list) do
				setGroupVisible(frame, false)
			end
		end
	
		local function animateCharacter(char, properties)
			table.insert(animateQueue, {Char = char, Settings = properties, Start = tick()})
		end
		
		local function yield()
			if not overrideYield and numAnimated % stepFrequency == 0 and stepTime >= 0 then
				local yieldTime = stepTime > 0 and stepTime or nil
				wait(yieldTime)
			end
		end
		
		for lineNum, list in pairs(textFrames) do
			for _, frame in pairs(list) do
				local properties = frameProperties[frame]
				if not (properties.AnimateStepGrouping  == stepGrouping) or not (properties.AnimateStepFrequency == stepFrequency) then
					numAnimated = 0
				end
				stepGrouping = properties.AnimateStepGrouping
				stepTime = properties.AnimateStepTime
				stepFrequency = properties.AnimateStepFrequency
			
				if properties.AnimateYield > 0 then
					wait(properties.AnimateYield)
				end

				if stepGrouping == "Word" or stepGrouping == "All" then
					--if not (frame:IsA("TextLabel") and (frame.Text == " ")) then
						if frame:IsA("TextLabel") then
							frame.Visible = true
							for _, v in pairs(frame:GetChildren()) do
								animateCharacter(v, frameProperties[v])
							end
						else
							animateCharacter(frame, properties)
						end
						if stepGrouping == "Word" then
							numAnimated = numAnimated + 1
							yield()
						end
					--end
				elseif stepGrouping == "Letter" then
					if frame:IsA("TextLabel") --[[and not (frame.Text == " ") ]]then
						frame.Visible = true
						local text = frame.Text
						local i = 1
						while true do
							local v = frame:FindFirstChild(string.format("Char%03d", i))
							if not v then
								break
							end
							animateCharacter(v, frameProperties[v])
							numAnimated = numAnimated + 1
							yield()
							if animationDone then
								return
							end
							i = i + 1
						end
					else
						animateCharacter(frame, properties)
						numAnimated = numAnimated + 1
						yield()
					end
				else
					warn("Invalid step grouping: ", stepGrouping)
				end
				
				if animationDone then
					return
				end
			end
		end
			
		allTextReached = true
		
		if waitForAnimationToFinish then
			while #animateQueue > 0 do
				runService.RenderStepped:Wait()
			end
		end	
	end
	


	local textObject = {}
	
	----- Overflowing -----
	
	textObject.Overflown = overflown
	textObject.OverflowPickupIndex = textPos
	textObject.StartingProperties = startingProperties
	textObject.OverflowPickupProperties = properties
	textObject.Text = text

	if prevTextObject then
		prevTextObject.NextTextObject = textObject
	end
	
	-- to overflow: check if textObject.Overflown, then use richText:ContinueOverflow(newFrame, textObject) to continue to another frame.
	
	
	----- Return object API -----

	textObject.ContentSize = Vector2.new(contentRight - contentLeft, contentHeight)

	function textObject:Animate(yield)
		if yield then
			animate()
		else
			coroutine.wrap(animate)()
		end
		if self.NextTextObject then
			self.NextTextObject:Animate(yield)
		end
	end
	
	function textObject:Show(finishAnimation)
		if finishAnimation then
			overrideYield = true
		else
			animationDone = true
			for lineNum, list in pairs(textFrames) do
				for _, frame in pairs(list) do
					setGroupVisible(frame, true)
				end
			end
		end
		if self.NextTextObject then
			self.NextTextObject:Show(finishAnimation)
		end
	end
	
	function textObject:Hide()
		animationDone = true
		for lineNum, list in pairs(textFrames) do
			for _, frame in pairs(list) do
				setGroupVisible(frame, false)
			end
		end
		if self.NextTextObject then
			self.NextTextObject:Hide()
		end
	end
	
	return textObject
end


function richText:ContinueOverflow(newFrame, prevTextObject)
	return richText:New(newFrame, nil, nil, false, prevTextObject)
end


return richText
