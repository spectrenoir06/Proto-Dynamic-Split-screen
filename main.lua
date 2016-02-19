vector = require "vector"

function love.load()

	if arg[#arg] == "-debug" then require("mobdebug").start() end

	windowWidth  = love.graphics.getWidth()
	windowHeight = love.graphics.getHeight()

	window = vector(windowWidth, windowHeight)

	p1 = {
		v = vector(0,0),
		color = {
			r = 0,
			g = 0,
			b = 255,
			a = 255
		}
	}

	p2 = {
		v = vector(0,0),
		color = {
			r = 255,
			g = 0,
			b = 0,
			a = 255
		}
	}

	img = love.graphics.newImage("img.png")

	view1 = vector(0,0)
	view2 = vector(0,0)
end

function movePlayer(dt)
	if love.keyboard.isDown("z") then
		p1.v.y = p1.v.y - (dt * 150)
	end
	if love.keyboard.isDown("s") then
		p1.v.y = p1.v.y + (dt * 150)
	end
	if love.keyboard.isDown("q") then
		p1.v.x = p1.v.x - (dt * 150)
	end
	if love.keyboard.isDown("d") then
		p1.v.x = p1.v.x + (dt * 150)
	end

	if love.keyboard.isDown("up") then
		p2.v.y = p2.v.y - (dt * 150)
	end
	if love.keyboard.isDown("down") then
		p2.v.y = p2.v.y + (dt * 150)
	end
	if love.keyboard.isDown("left") then
		p2.v.x = p2.v.x - (dt * 150)
	end
	if love.keyboard.isDown("right") then
		p2.v.x = p2.v.x + (dt * 150)
	end
end


function shouldSplit(v1, v2)
	local v = v1 - v2
	local length = v:len()

	return (length > (windowWidth + windowHeight) / 4)
end

function viewPosition(p1, p2)
	-- Our camera position is currently set to keep the player within a circular area of the screen.
	-- It would probably be better to convert this to instead keep them within a elliptical area.
	local out = p1

	-- MAX_DISTANCE will keep position1 on the screen, reguardless of how far away it is from position2.
	local MAX_DISTANCE = (windowWidth + windowHeight) / 5;
	-- this is the ideal position, the halfway point between both players, the camera will gravitate towards this position
	-- so that things meet up nicely when the views merge.
	local direction = (p2 - p1) / 2

	-- Use MAX_DISTANCE to trim our direction vector if it is too long,
	-- eg. If it would put position1 off the edge of the screen.

	local length = direction:len()

	if(length > MAX_DISTANCE) then
		-- thor::setLength(direction, MAX_DISTANCE)
		direction = direction * (MAX_DISTANCE / direction:len())
	end

	return out + direction;
end

function love.draw()
		-- Draw everything from player ones point of view.

		-- If we're splitting the views then we'll do the same for player twos view.
		if not singleView then
			love.graphics.push()
				love.graphics.translate(windowWidth/2, windowHeight/2)
				local angle = (p1.v - p2.v):perpendicular()

				love.graphics.rotate(angle:angleTo())
				local length = window:len()

				love.graphics.line(-length, 0, length, 0)

				love.graphics.stencil(function()
					love.graphics.rectangle('fill', -800, 0, 800*2, 800)
				end, "replace", 1)
			love.graphics.pop()

			love.graphics.push()
				love.graphics.setStencilTest("less", 1)
				love.graphics.translate(-view1.x, -view1.y)

				love.graphics.setColor(255, 255, 255, 255)
				love.graphics.draw(img, 0 - img:getWidth()/2, 0 - img:getHeight()/2)   -- map

				love.graphics.setColor(p1.color.r, p1.color.g, p1.color.b, p1.color.a) -- player 1
				love.graphics.rectangle("fill", p1.v.x - 5, p1.v.y - 5, 10, 10)

				love.graphics.setColor(p2.color.r, p2.color.g, p2.color.b, p2.color.a) -- player 2
				love.graphics.rectangle("fill", p2.v.x - 5, p2.v.y - 5, 10, 10)

				love.graphics.setStencilTest()
			love.graphics.pop()

			love.graphics.push()
				love.graphics.translate(-view2.x, -view2.y)
				love.graphics.setStencilTest("greater", 0)

				love.graphics.setColor(255, 255, 255, 255)
				love.graphics.draw(img, 0 - img:getWidth()/2, 0 - img:getHeight()/2)    -- map

				love.graphics.setColor(p1.color.r, p1.color.g, p1.color.b, p1.color.a)  -- player 1
				love.graphics.rectangle("fill", p1.v.x - 5, p1.v.y - 5, 10, 10)

				love.graphics.setColor(p2.color.r, p2.color.g, p2.color.b, p2.color.a)  -- player 2
				love.graphics.rectangle("fill", p2.v.x - 5, p2.v.y - 5, 10, 10)

				love.graphics.setStencilTest()
			love.graphics.pop()
		else
			love.graphics.translate(-view1.x, -view1.y)

			love.graphics.setColor(255, 255, 255, 255)
			love.graphics.draw(img, 0 - img:getWidth()/2, 0 - img:getHeight()/2)

			love.graphics.setColor(p1.color.r, p1.color.g, p1.color.b, p1.color.a)
			love.graphics.rectangle("fill", p1.v.x - 5, p1.v.y - 5, 10, 10)

			love.graphics.setColor(p2.color.r, p2.color.g, p2.color.b, p2.color.a)
			love.graphics.rectangle("fill", p2.v.x - 5, p2.v.y - 5, 10, 10)
		end

end


function love.update(dt)
	movePlayer(dt)

	singleView = true

	if shouldSplit(p1.v, p2.v) then
		singleView = false
		local idealPos = viewPosition(p1.v, p2.v);
		view1 = view1 +  (idealPos - (view1 + window / 2)) * dt * 10;  -- speed

		idealPos = viewPosition(p2.v, p1.v);
		view2 = view2 +  (idealPos - (view2 + window / 2)) * dt * 10;  -- speed
	else
		-- If we don't want a split view, then the ideal position is the halfway
		-- point between both players.
		local idealPos = (p1.v + p2.v) / 2
		view1 = view1 +  (idealPos - (view1 + window / 2)) * dt * 10;  -- speed
		-- Set player twos cameras to the same as player ones, this will avoid an jump if the cameras split again
		-- far away from where they last merged.
		view2.x = view1.x
		view2.y = view1.y
	end
end

function love.keypressed(key, isrepeat)
	if key == "escape" then
		love.event.quit()
	end
end
